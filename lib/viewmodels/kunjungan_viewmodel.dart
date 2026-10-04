import 'dart:async';

import '../core/constants/app_strings.dart';
import '../data/models/kunjungan_record.dart';
import '../data/repositories/kunjungan_repository.dart';
import '../data/remote/auth_remote_data_source.dart';
import '../services/location_service.dart';
import 'base_viewmodel.dart';

class KunjunganViewModel extends BaseViewModel {
  final KunjunganRepository _repository;
  final LocationService _locationService;

  bool _isSubmitting = false;
  bool _isLocating = false;
  bool _isHistoryLoading = false;
  double? _latitude;
  double? _longitude;
  String? _address;
  List<KunjunganRecord> _history = <KunjunganRecord>[];

  KunjunganViewModel({
    required this._repository,
    required this._locationService,
  });

  bool get isSubmitting => _isSubmitting;
  bool get isLocating => _isLocating;
  bool get isHistoryLoading => _isHistoryLoading;
  List<KunjunganRecord> get historyRecords => List.unmodifiable(_history);

  String get address => _address ?? AppStrings.locationNotObtained;

  String get formattedLatitude =>
      _latitude == null ? '-' : _latitude!.toStringAsFixed(5);

  String get formattedLongitude =>
      _longitude == null ? '-' : _longitude!.toStringAsFixed(5);

  Future<void> loadCurrentLocation() async {
    if (_isLocating) {
      return;
    }
    _isLocating = true;
    notifyListeners();
    try {
      final location = await _locationService.getCurrentLocation();
      _latitude = location.latitude;
      _longitude = location.longitude;
      _address = location.address.isEmpty
          ? AppStrings.locationNotObtained
          : location.address;
    } on LocationServiceException catch (exception) {
      _address = exception.message;
    } catch (_) {
      _address = 'Lokasi tidak tersedia';
    }
    _isLocating = false;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _isHistoryLoading = true;
    setError(null);
    notifyListeners();
    try {
      _history = await _repository.fetchVisits();
      setError(null);
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
    } catch (_) {
      setError('Gagal memuat riwayat kunjungan. Silakan coba lagi.');
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> _finishOpenVisit({
    required String timeLabel,
    required String notes,
    String? evidencePath,
  }) async {
    final visits = await _repository.fetchVisits();
    final now = DateTime.now();
    KunjunganRecord? open;
    for (final visit in visits) {
      final day = visit.timestamp;
      final isToday =
          day.year == now.year && day.month == now.month && day.day == now.day;
      if (isToday && visit.mode == KunjunganMode.start) {
        open = visit;
      }
    }
    if (open == null) {
      throw const ApiException('Belum ada kunjungan aktif hari ini');
    }
    await _repository.finishVisit(
      id: open.id,
      timeLabel: timeLabel,
      notes: notes,
      latitude: _latitude,
      longitude: _longitude,
      address: address,
      evidencePath: evidencePath,
    );
  }

  Future<bool> submit({
    required KunjunganMode mode,
    required String timeLabel,
    required String clientName,
    required String notes,
    String? evidencePath,
  }) async {
    if (_isSubmitting) {
      return false;
    }
    _isSubmitting = true;
    setError(null);
    notifyListeners();
    try {
      if (mode == KunjunganMode.start) {
        await _repository.startVisit(
          timeLabel: timeLabel,
          clientName: clientName.trim(),
          notes: notes.trim(),
          latitude: _latitude,
          longitude: _longitude,
          address: address,
          evidencePath: evidencePath,
        );
      } else {
        await _finishOpenVisit(
          timeLabel: timeLabel,
          notes: notes,
          evidencePath: evidencePath,
        );
      }
      setError(null);
      return true;
    } on ApiException catch (error) {
      setError(error.message);
      return false;
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      return false;
    } catch (_) {
      setError('Gagal menyimpan kunjungan. Silakan coba lagi.');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
