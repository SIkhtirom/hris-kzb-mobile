import 'dart:async';

import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_strings.dart';
import '../data/models/attendance_record.dart';
import '../data/models/reimbursement_claim.dart';
import '../data/models/user.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/reimbursement_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/attendance_local_store.dart';
import '../services/photo_storage_service.dart';
import '../services/request_guard.dart';
import 'base_viewmodel.dart';

class DashboardViewModel extends BaseViewModel {
  static const Duration _minimumCycleGap = Duration(hours: 3);

  final UserRepository _userRepository;
  final AttendanceRepository _attendanceRepository;
  final ReimbursementRepository _reimbursementRepository;
  final PhotoStorageService _photoStorageService;
  final AttendanceLocalStore _attendanceStore;

  DashboardViewModel({
    required UserRepository userRepository,
    required this._attendanceRepository,
    required this._reimbursementRepository,
    required this._photoStorageService,
    required this._attendanceStore,
  }) : _userRepository = userRepository,
       _user = userRepository.cachedUser;

  User? _user;
  int _presentDays = 0;
  int _absentDays = 0;
  int _pendingClaims = 0;
  int _approvedClaims = 0;
  double _totalPendingAmount = 0;
  bool _hasClockedInToday = false;
  bool _hasCompletedCycleToday = false;
  DateTime? _todayCheckInTime;
  Timer? _cooldownTimer;

  User? get user => _user;
  int get presentDays => _presentDays;
  int get absentDays => _absentDays;
  int get pendingClaims => _pendingClaims;
  int get approvedClaims => _approvedClaims;
  double get totalPendingAmount => _totalPendingAmount;
  bool get hasClockedInToday => _hasClockedInToday;
  bool get hasCompletedCycleToday => _hasCompletedCycleToday;

  bool get _isCoolingDown {
    if (AppConfig.allowEarlyCheckOut) {
      return false;
    }
    return _todayCheckInTime != null &&
        DateTime.now().difference(_todayCheckInTime!) < _minimumCycleGap;
  }

  bool get isCheckOutLocked =>
      _hasClockedInToday && !_hasCompletedCycleToday && _isCoolingDown;

  bool get isCheckOutAvailable =>
      _hasClockedInToday && !_hasCompletedCycleToday && !_isCoolingDown;

  String get attendanceStatusLabel => _hasCompletedCycleToday
      ? AppStrings.dashboardCycleDoneLabel
      : AppStrings.attendanceSectionLabel;

  String get summaryMonthLabel {
    final now = DateTime.now();
    return AppStrings.monthYearLabel(DateTime(now.year, now.month));
  }

  Future<void> refreshUser() async {
    try {
      _user = await RequestGuard.withTimeout(
        _userRepository.fetchCurrentUser(),
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateProfilePicture(String pickedPath) async {
    final user = _user;
    if (user == null) {
      return false;
    }
    final permanentPath = await _photoStorageService.copyPhoto(
      sourcePath: pickedPath,
      folder: 'profile',
    );
    if (permanentPath == null) {
      return false;
    }
    _user = await _userRepository.updateUser(
      user.copyWith(profilePicturePath: permanentPath),
    );
    notifyListeners();
    return true;
  }

  Future<void> loadDashboard() async {
    setLoading(true);
    setError(null);
    try {
      _user = await RequestGuard.withTimeout(
        _userRepository.fetchCurrentUser(),
      );

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final monthRecords = await _attendanceRepository.fetchHistory(
        start: startOfMonth,
        end: endOfMonth,
      );

      final checkIns = monthRecords.where(
        (r) => r.eventType == ClockEventType.checkIn,
      );
      _presentDays = checkIns
          .where((r) => r.status == AttendanceStatus.present)
          .map((r) => DateUtils.dateOnly(r.timestamp))
          .toSet()
          .length;
      _absentDays = checkIns
          .where((r) => r.status == AttendanceStatus.absent)
          .map((r) => DateUtils.dateOnly(r.timestamp))
          .toSet()
          .length;

      final todayStart = DateTime(now.year, now.month, now.day);
      final todayRecords = monthRecords
          .where(
            (r) =>
                !r.timestamp.isBefore(todayStart) &&
                r.timestamp.isBefore(todayStart.add(const Duration(days: 1))),
          )
          .toList();
      _hasClockedInToday = todayRecords.any(
        (r) => r.eventType == ClockEventType.checkIn,
      );
      final checkInRecords = todayRecords
          .where((r) => r.eventType == ClockEventType.checkIn)
          .toList();
      _todayCheckInTime = checkInRecords.isEmpty
          ? null
          : checkInRecords.first.timestamp;
      _hasCompletedCycleToday =
          _hasClockedInToday &&
          todayRecords.any((r) => r.eventType == ClockEventType.checkOut);
      final storedCheckIn = await _attendanceStore.readCheckIn(now);
      if (storedCheckIn != null) {
        _hasClockedInToday = true;
        _todayCheckInTime ??= storedCheckIn.timestamp;
      }
      final storedCheckOut = await _attendanceStore.readCheckOut(now);
      if (storedCheckOut != null && _hasClockedInToday) {
        _hasCompletedCycleToday = true;
      }
      _syncCooldownTimer();

      final claims = await _reimbursementRepository.fetchClaims();
      _pendingClaims = claims
          .where((c) => c.status == ClaimStatus.pending)
          .length;
      _approvedClaims = claims
          .where((c) => c.status == ClaimStatus.approved)
          .length;
      _totalPendingAmount = claims
          .where((c) => c.status == ClaimStatus.pending)
          .fold<double>(0, (sum, c) => sum + c.amount);

      setError(null);
      setLoading(false);
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      setLoading(false);
    } catch (_) {
      setError('Gagal memuat data dashboard. Silakan coba lagi.');
      setLoading(false);
    }
  }

  void _syncCooldownTimer() {
    if (isCheckOutLocked) {
      _cooldownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        notifyListeners();
        if (!isCheckOutLocked) {
          _cooldownTimer?.cancel();
          _cooldownTimer = null;
          notifyListeners();
        }
      });
    } else {
      _cooldownTimer?.cancel();
      _cooldownTimer = null;
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
