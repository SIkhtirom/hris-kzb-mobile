import 'package:field_supervisor_app/data/models/attendance_record.dart';
import 'package:field_supervisor_app/services/attendance_local_store.dart';

class MemoryAttendanceStore extends AttendanceLocalStore {
  AttendanceRecord? checkInRecord;
  AttendanceRecord? checkOutRecord;

  @override
  Future<AttendanceRecord?> readCheckIn(DateTime day) async => checkInRecord;

  @override
  Future<AttendanceRecord?> readCheckOut(DateTime day) async => checkOutRecord;

  @override
  Future<void> writeCheckIn(AttendanceRecord record) async {
    checkInRecord = record;
  }

  @override
  Future<void> writeCheckOut(AttendanceRecord record) async {
    checkOutRecord = record;
  }
}
