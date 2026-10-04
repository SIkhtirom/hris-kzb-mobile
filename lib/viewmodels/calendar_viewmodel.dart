import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../data/models/attendance_record.dart';
import '../data/repositories/attendance_repository.dart';
import 'base_viewmodel.dart';

class CalendarViewModel extends BaseViewModel {
  final AttendanceRepository _attendanceRepository;

  Map<DateTime, List<AttendanceRecord>> _recordsByDate = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  CalendarViewModel({required this._attendanceRepository});

  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;

  List<AttendanceRecord> get recordsForSelectedDay => recordsFor(_selectedDay);

  Future<void> loadCalendarWindow(DateTime referenceDay) async {
    setLoading(true);
    setError(null);
    try {
      final start = DateTime(referenceDay.year, referenceDay.month - 1, 1);
      final end = DateTime(
        referenceDay.year,
        referenceDay.month + 2,
        0,
        23,
        59,
        59,
      );
      final records = await _attendanceRepository.fetchHistory(
        start: start,
        end: end,
      );
      _recordsByDate = {};
      for (final record in records) {
        final date = DateUtils.dateOnly(record.timestamp);
        _recordsByDate
            .putIfAbsent(date, () => <AttendanceRecord>[])
            .add(record);
      }
      setError(null);
      setLoading(false);
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      setLoading(false);
    } catch (_) {
      setError('Gagal memuat riwayat absen. Silakan coba lagi.');
      setLoading(false);
    }
  }

  void selectDate(DateTime date) {
    _selectedDay = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }

  List<AttendanceRecord> recordsFor(DateTime date) {
    return _recordsByDate[DateUtils.dateOnly(date)] ?? const [];
  }

  AttendanceStatus? statusFor(DateTime date) {
    final records = recordsFor(date);
    if (records.isEmpty) {
      return null;
    }
    return AttendanceStatus.present;
  }
}
