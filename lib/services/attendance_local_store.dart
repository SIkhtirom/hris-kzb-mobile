import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/attendance_record.dart';

class AttendanceLocalStore {
  static const String dateKey = 'attendance_date';
  static const String checkInKey = 'attendance_check_in';
  static const String checkOutKey = 'attendance_check_out';

  Future<AttendanceRecord?> readCheckIn(DateTime day) {
    return _readRecord(day, checkInKey);
  }

  Future<AttendanceRecord?> readCheckOut(DateTime day) {
    return _readRecord(day, checkOutKey);
  }

  Future<void> writeCheckIn(AttendanceRecord record) {
    return _writeRecord(record, checkInKey);
  }

  Future<void> writeCheckOut(AttendanceRecord record) {
    return _writeRecord(record, checkOutKey);
  }

  Future<AttendanceRecord?> _readRecord(DateTime day, String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(dateKey) != _dayKey(day)) {
        return null;
      }
      final payload = prefs.getString(key);
      if (payload == null) {
        return null;
      }
      return AttendanceRecord.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeRecord(AttendanceRecord record, String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(dateKey, _dayKey(record.timestamp));
      await prefs.setString(key, jsonEncode(record.toJson()));
    } catch (_) {}
  }

  String _dayKey(DateTime day) {
    return '${day.year}-${day.month}-${day.day}';
  }
}
