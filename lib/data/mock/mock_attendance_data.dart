import '../../data/models/attendance_record.dart';

class MockAttendanceData {
  MockAttendanceData._();

  static List<AttendanceRecord> _records = <AttendanceRecord>[];

  static List<AttendanceRecord> get records => List.unmodifiable(_records);

  static void add(AttendanceRecord record) {
    _records = [..._records, record];
  }

  static void clear() {
    _records = <AttendanceRecord>[];
  }
}
