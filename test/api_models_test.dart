import 'package:flutter_test/flutter_test.dart';

import 'package:field_supervisor_app/data/models/attendance_record.dart';
import 'package:field_supervisor_app/data/models/izin_record.dart';
import 'package:field_supervisor_app/data/models/kunjungan_record.dart';
import 'package:field_supervisor_app/data/models/reimbursement_claim.dart';
import 'package:field_supervisor_app/data/models/timesheet_task.dart';

void main() {
  test('attendance record parses api payload and serializes back', () {
    final record = AttendanceRecord.fromJson({
      'id': 'ATT-100',
      'timestamp': '2026-09-22T08:05:30.000',
      'event_type': 'check_in',
      'address': 'Site Menara Riverside',
      'latitude': -6.2259,
      'longitude': 106.8162,
      'status': 'present',
      'photo_path': '/docs/selfies/selfie_1.jpg',
    });

    expect(record.id, 'ATT-100');
    expect(record.eventType, ClockEventType.checkIn);
    expect(record.status, AttendanceStatus.present);
    expect(record.latitude, closeTo(-6.2259, 0.00001));
    expect(record.photoPath, '/docs/selfies/selfie_1.jpg');

    final json = record.toJson();
    expect(json['event_type'], 'check_in');
    expect(json['status'], 'present');
    expect(json['photo_path'], '/docs/selfies/selfie_1.jpg');
  });

  test('kunjungan record drops signature shape and parses api payload', () {
    final record = KunjunganRecord.fromJson({
      'id': 'KJN-100',
      'mode': 'end',
      'timestamp': '2026-09-22T16:30:00.000',
      'time_label': '16:30',
      'client_name': 'PT Maju Jaya',
      'notes': 'Survey lokasi',
      'address': 'Jl. Merdeka No. 10',
      'evidence_path': '/docs/evidence/kjn.jpg',
      'latitude': -6.2,
      'longitude': 106.8,
    });

    expect(record.mode, KunjunganMode.end);
    expect(record.clientName, 'PT Maju Jaya');

    final json = record.toJson();
    expect(json['mode'], 'end');
    expect(json.containsKey('signature'), isFalse);
    expect(json['evidence_path'], '/docs/evidence/kjn.jpg');
  });

  test('reimbursement claim parses api payload for http submission', () {
    final claim = ReimbursementClaim.fromJson({
      'id': 'RMB-100',
      'amount': 150000,
      'activity_name': 'Bensin gudang',
      'category': 'transport',
      'expense_date': '2026-09-20T00:00:00.000',
      'currency': 'IDR',
      'seller_name': 'SPBU 34',
      'notes': 'Operasional',
      'submitted_at': '2026-09-21T10:00:00.000',
      'status': 'pending',
      'receipt_file_name': 'bukti.jpg',
    });

    expect(claim.category, ExpenseCategory.transport);
    expect(claim.status, ClaimStatus.pending);
    expect(claim.amount, 150000);

    final json = claim.toJson();
    expect(json['category'], 'transport');
    expect(json['status'], 'pending');
    expect(json['expense_date'], '2026-09-20T00:00:00.000');
  });

  test('izin record parses api payload for http submission', () {
    final record = IzinRecord.fromJson({
      'id': 'IZN-100',
      'date': '2026-09-25T00:00:00.000',
      'reason': 'sick',
      'notes': 'Demam',
      'status': 'pending',
      'photo_path': null,
      'created_at': '2026-09-22T09:00:00.000',
    });

    expect(record.reason, IzinReason.sick);
    expect(record.status, IzinStatus.pending);

    final json = record.toJson();
    expect(json['reason'], 'sick');
    expect(json['status'], 'pending');
  });

  test('timesheet task parses admin-assigned api payload', () {
    final task = TimesheetTask.fromJson({
      'id': 'TSK-100',
      'name': 'Pasang bekisting',
      'assigned_date': '2026-09-22T00:00:00.000',
      'hour': 9,
      'minute': 0,
      'instructions': 'Instruksi dari dashboard admin',
      'is_completed': false,
      'proof_path': null,
      'completed_at': null,
    });

    expect(task.name, 'Pasang bekisting');
    expect(task.instructions, isNotEmpty);
    expect(task.isCompleted, isFalse);

    final json = task.toJson();
    expect(json['is_completed'], isFalse);
    expect(json['assigned_date'], '2026-09-22T00:00:00.000');
  });
}
