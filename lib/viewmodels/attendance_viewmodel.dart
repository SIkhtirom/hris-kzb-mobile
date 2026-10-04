import 'dart:async';

import 'package:intl/intl.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_strings.dart';
import '../data/models/attendance_record.dart';
import '../data/models/geo_location.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/remote/auth_remote_data_source.dart';
import '../services/attendance_local_store.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/selfie_storage_service.dart';
import 'base_viewmodel.dart';

class AttendanceViewModel extends BaseViewModel {
  static const Duration _tickInterval = Duration(seconds: 1);
  static const Duration _minimumCycleGap = Duration(hours: 3);

  final AttendanceRepository _attendanceRepository;
  final CameraService _cameraService;
  final LocationService _locationService;
  final SelfieStorageService _selfieStorageService;
  final AttendanceLocalStore _attendanceStore;

  Timer? _timer;
  bool _isSubmitting = false;
  DateTime _currentTime = DateTime.now();
  String? _selfiePath;
  double? _latitude;
  double? _longitude;
  String? _address;
  String? _lastSubmittedAt;
  bool _hasClockedInToday = false;
  bool _hasCheckedOutToday = false;
  DateTime? _todayCheckInTime;
  ClockEventType? _configuredAction;
  AttendanceRecord? _verificationRecord;

  AttendanceViewModel({
    required this._attendanceRepository,
    required this._cameraService,
    required this._locationService,
    required this._selfieStorageService,
    required this._attendanceStore,
  });

  bool get isSubmitting => _isSubmitting;
  DateTime get currentTime => _currentTime;
  String? get selfiePath => _selfiePath;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get address => _address ?? AppStrings.locationNotObtained;
  String? get lastSubmittedAt => _lastSubmittedAt;
  bool get hasClockedInToday => _hasClockedInToday;
  bool get hasCheckedOutToday => _hasCheckedOutToday;
  AttendanceRecord? get verificationRecord => _verificationRecord;

  String get verificationTimeLabel => _verificationRecord == null
      ? ''
      : DateFormat('HH:mm:ss').format(_verificationRecord!.timestamp);

  String get currentServerTime => DateFormat('HH:mm:ss').format(_currentTime);

  String get currentDateLabel => AppStrings.fullDate(_currentTime);

  String get formattedLatitude =>
      _latitude == null ? '-' : _latitude!.toStringAsFixed(5);

  String get formattedLongitude =>
      _longitude == null ? '-' : _longitude!.toStringAsFixed(5);

  bool get isCheckOutEligible {
    final checkIn = _todayCheckInTime;
    if (checkIn == null) {
      return false;
    }
    if (AppConfig.allowEarlyCheckOut) {
      return true;
    }
    return _currentTime.difference(checkIn) >= _minimumCycleGap;
  }

  bool get canCheckOut =>
      _hasClockedInToday && !_hasCheckedOutToday && isCheckOutEligible;

  bool get showActionButton {
    if (AppConfig.allowRepeatCheckIn &&
        _configuredAction == ClockEventType.checkIn) {
      return true;
    }
    return !_hasClockedInToday || canCheckOut;
  }

  ClockEventType get nextAction =>
      _configuredAction ??
      (_hasClockedInToday ? ClockEventType.checkOut : ClockEventType.checkIn);

  String get actionLabel => AppStrings.attendanceActionLabel(nextAction);

  void configure(ClockEventType action) {
    _configuredAction = action;
    _resetDraft();
    notifyListeners();
  }

  void _resetDraft() {
    _selfiePath = null;
    _latitude = null;
    _longitude = null;
    _address = null;
    _lastSubmittedAt = null;
    _verificationRecord = null;
  }

  Future<void> loadInitialState() async {
    setLoading(true);
    setError(null);
    _resetDraft();
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final todayRecords = await _attendanceRepository.fetchHistory(
        start: todayStart,
        end: todayEnd,
      );
      _hasClockedInToday = false;
      _hasCheckedOutToday = false;
      _todayCheckInTime = null;
      AttendanceRecord? checkInRecord;

      for (final record in todayRecords) {
        if (record.eventType == ClockEventType.checkIn &&
            _todayCheckInTime == null) {
          _todayCheckInTime = record.timestamp;
          checkInRecord = record;
        }
        if (record.eventType == ClockEventType.checkOut) {
          _hasCheckedOutToday = true;
        }
      }
      _hasClockedInToday = _todayCheckInTime != null;

      final storedCheckIn = await _attendanceStore.readCheckIn(now);
      if (checkInRecord == null && storedCheckIn != null) {
        checkInRecord = storedCheckIn;
        _todayCheckInTime = storedCheckIn.timestamp;
        _hasClockedInToday = true;
      }
      final storedCheckOut = await _attendanceStore.readCheckOut(now);
      if (!_hasCheckedOutToday && storedCheckOut != null) {
        _hasCheckedOutToday = true;
      }

      AttendanceRecord? lastCheckOut;
      for (final record in todayRecords) {
        if (record.eventType == ClockEventType.checkOut) {
          lastCheckOut = record;
        }
      }
      lastCheckOut ??= storedCheckOut;

      if (_configuredAction == ClockEventType.checkIn) {
        _verificationRecord = checkInRecord;
      } else if (_configuredAction == ClockEventType.checkOut) {
        _verificationRecord = lastCheckOut;
      }

      final verified = _verificationRecord;
      _selfiePath = verified?.photoPath;
      _address = verified?.address;
      _latitude = verified?.latitude;
      _longitude = verified?.longitude;

      _currentTime = DateTime.now();
      _startTimer();
      setError(null);
      setLoading(false);
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      setLoading(false);
    } catch (_) {
      setError('Gagal memuat data absen. Silakan coba lagi.');
      setLoading(false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tickInterval, (_) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }

  Future<bool> submit() async {
    if (_isSubmitting) {
      return false;
    }
    _isSubmitting = true;
    setError(null);
    notifyListeners();
    try {
      final permissionGranted = await _locationService
          .requestLocationPermission();
      if (!permissionGranted) {
        setError(AppStrings.locationPermissionDenied);
        return false;
      }
      final capturedPath = await _cameraService.takeSelfie();
      if (capturedPath == null) {
        return false;
      }
      final selfiePath = await _selfieStorageService.copyToPermanent(
        capturedPath,
      );
      if (selfiePath == null) {
        setError(AppStrings.selfieSaveError);
        return false;
      }
      final location = await _fetchLocation();
      if (location == null) {
        return false;
      }
      final action = nextAction;
      final saved = await _attendanceRepository.submitAttendance(
        eventType: action,
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address.isEmpty
            ? AppStrings.locationNotObtained
            : location.address,
        photoPath: selfiePath,
        timestamp: DateTime.now(),
      );
      final record = AttendanceRecord(
        id: saved.id,
        timestamp: saved.timestamp,
        eventType: saved.eventType,
        address: saved.address,
        latitude: saved.latitude,
        longitude: saved.longitude,
        status: saved.status,
        photoPath: selfiePath,
      );
      if (record.eventType == ClockEventType.checkIn) {
        _hasClockedInToday = true;
        _todayCheckInTime = record.timestamp;
        await _attendanceStore.writeCheckIn(record);
      } else {
        _hasCheckedOutToday = true;
        await _attendanceStore.writeCheckOut(record);
      }
      _lastSubmittedAt = DateFormat('HH:mm:ss').format(record.timestamp);
      _selfiePath = record.photoPath;
      _verificationRecord = record;
      _latitude = record.latitude;
      _longitude = record.longitude;
      _address = record.address;
      setError(null);
      return true;
    } on LocationServiceException catch (exception) {
      setError(exception.message);
      return false;
    } on ApiException catch (error) {
      setError(error.message);
      return false;
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      return false;
    } catch (_) {
      setError('Gagal mengirim absen. Silakan coba lagi.');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<GeoLocation?> _fetchLocation() async {
    try {
      return await _locationService.getCurrentLocation();
    } on LocationServiceException catch (exception) {
      setError(exception.message);
      return null;
    } catch (_) {
      setError('Gagal mendapatkan lokasi. Silakan coba lagi.');
      return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
