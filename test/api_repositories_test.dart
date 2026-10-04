import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:field_supervisor_app/core/constants/api_constants.dart';
import 'package:field_supervisor_app/data/models/attendance_record.dart';
import 'package:field_supervisor_app/data/models/izin_record.dart';
import 'package:field_supervisor_app/data/models/kunjungan_record.dart';
import 'package:field_supervisor_app/data/models/reimbursement_claim.dart';
import 'package:field_supervisor_app/data/remote/auth_remote_data_source.dart';
import 'package:field_supervisor_app/data/repositories/attendance_repository.dart';
import 'package:field_supervisor_app/data/repositories/izin_repository.dart';
import 'package:field_supervisor_app/data/repositories/kunjungan_repository.dart';
import 'package:field_supervisor_app/data/repositories/reimbursement_repository.dart';
import 'package:field_supervisor_app/data/repositories/timesheet_repository.dart';
import 'package:field_supervisor_app/services/in_memory_token_store.dart';

void main() {
  Future<InMemoryTokenStore> tokenStore() async {
    final store = InMemoryTokenStore();
    await store.writeTokens(accessToken: 'test-token');
    return store;
  }

  Future<File> tempImage(String name) async {
    final directory = await Directory.systemTemp.createTemp('api_repo');
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    await file.writeAsString('bytes');
    return file;
  }

  Future<http.StreamedResponse> streamed(Object data, [int code = 201]) async {
    final bytes = utf8.encode(
      jsonEncode({'status': true, 'message': 'ok', 'data': data}),
    );
    return http.StreamedResponse(
      Stream.value(bytes),
      code,
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<http.StreamedResponse> streamedError(int code) async {
    return http.StreamedResponse(Stream.value(utf8.encode('{}')), code);
  }

  test('attendance submit sends bearer multipart and parses record', () async {
    final photo = await tempImage('selfie.jpg');
    http.BaseRequest? seen;

    final client = MockClient.streaming((request, _) async {
      seen = request;
      return streamed({
        'id': 'ATT-1',
        'timestamp': '2026-09-23T08:00:00.000',
        'event_type': 'check_in',
        'address': 'Site Menara Riverside',
        'latitude': -6.2259,
        'longitude': 106.8162,
        'status': 'present',
        'photo_path': 'attendances/selfie.jpg',
      });
    });
    final repository = AttendanceRepository(
      client: client,
      tokenStore: await tokenStore(),
    );

    final record = await repository.submitAttendance(
      eventType: ClockEventType.checkIn,
      latitude: -6.2259,
      longitude: 106.8162,
      address: 'Site Menara Riverside',
      photoPath: photo.path,
    );

    final multipart = seen as http.MultipartRequest;
    expect(multipart.url.toString(), ApiConstants.attendances);
    expect(multipart.headers['Authorization'], 'Bearer test-token');
    expect(multipart.fields['type'], 'check_in');
    expect(multipart.fields['latitude'], '-6.2259');
    expect(multipart.fields['address'], 'Site Menara Riverside');
    expect(multipart.files.single.field, 'photo');
    expect(record.eventType, ClockEventType.checkIn);
    expect(record.address, 'Site Menara Riverside');
    expect(record.latitude, closeTo(-6.2259, 0.00001));
    expect(record.photoPath, 'attendances/selfie.jpg');
  });

  test(
    'attendance history parses full and sparse items without crashing',
    () async {
      final client = MockClient.streaming((request, _) async {
        expect(request.url.toString(), ApiConstants.attendances);
        expect(request.headers['Authorization'], 'Bearer test-token');
        return streamed([
          {
            'id': 'ATT-1',
            'timestamp': '2026-09-23T08:00:00',
            'event_type': 'check_in',
            'address': 'Site Menara Riverside',
            'latitude': -6.2259,
            'longitude': 106.8162,
            'status': 'present',
            'photo_path': 'attendances/selfie.jpg',
          },
          {
            'id': 'ATT-1',
            'timestamp': null,
            'event_type': null,
            'address': null,
            'latitude': null,
            'longitude': null,
            'status': null,
            'photo_path': null,
          },
        ], 200);
      });
      final repository = AttendanceRepository(
        client: client,
        tokenStore: await tokenStore(),
      );

      final history = await repository.fetchHistory();

      expect(history, hasLength(2));
      expect(history.first.eventType, ClockEventType.checkIn);
      expect(history.first.photoPath, 'attendances/selfie.jpg');
      expect(history.last.address, '');
      expect(history.last.latitude, 0);
      expect(history.last.photoPath, isNull);
    },
  );

  test('attendance history rethrows after logging failure', () async {
    final client = MockClient.streaming((request, stream) {
      return streamedError(500);
    });
    final repository = AttendanceRepository(
      client: client,
      tokenStore: await tokenStore(),
    );

    await expectLater(repository.fetchHistory(), throwsA(isA<Exception>()));
  });

  test('attendance submit throws AuthException on 401', () async {
    final client = MockClient.streaming(
      (request, stream) => streamedError(401),
    );
    final repository = AttendanceRepository(
      client: client,
      tokenStore: await tokenStore(),
    );

    await expectLater(
      repository.submitAttendance(eventType: ClockEventType.checkIn),
      throwsA(isA<AuthException>()),
    );
  });

  test('visit start and finish hit correct endpoints', () async {
    final evidence = await tempImage('evidence.jpg');
    final seen = <http.BaseRequest>[];

    Map<String, dynamic> visitJson(String mode) => {
      'id': 'KJN-1',
      'mode': mode,
      'timestamp': '2026-09-23T09:00:00.000',
      'time_label': '09:00',
      'client_name': 'PT Maju Jaya',
      'notes': 'Survey',
      'address': 'Jl. Merdeka',
      'evidence_path': 'visits/evidence.jpg',
      'latitude': -6.2,
      'longitude': 106.8,
    };

    final client = MockClient.streaming((request, _) async {
      seen.add(request);
      final isFinish = request.url.pathSegments.length > 2;
      return streamed(visitJson(isFinish ? 'end' : 'start'));
    });
    final repository = KunjunganRepository(
      client: client,
      tokenStore: await tokenStore(),
    );

    final started = await repository.startVisit(
      timeLabel: '09:00',
      clientName: 'PT Maju Jaya',
      notes: 'Survey',
      evidencePath: evidence.path,
    );
    final finished = await repository.finishVisit(
      id: 'KJN-1',
      notes: 'Selesai survey',
    );

    expect(started.mode, KunjunganMode.start);
    expect(finished.mode, KunjunganMode.end);
    final startRequest = seen[0] as http.MultipartRequest;
    final finishRequest = seen[1] as http.MultipartRequest;
    expect(startRequest.url.toString(), ApiConstants.visits);
    expect(startRequest.headers['Authorization'], 'Bearer test-token');
    expect(startRequest.fields['client_name'], 'PT Maju Jaya');
    expect(startRequest.files.single.field, 'evidence');
    expect(finishRequest.url.toString(), '${ApiConstants.visits}/KJN-1');
    expect(finishRequest.fields['notes'], 'Selesai survey');
  });

  test('reimbursement post sends receipt multipart and parses claim', () async {
    final receipt = await tempImage('nota.jpg');
    http.BaseRequest? seen;

    final client = MockClient.streaming((request, _) async {
      seen = request;
      return streamed({
        'id': 'RMB-1',
        'amount': 150000,
        'activity_name': 'Bensin',
        'category': 'transport',
        'expense_date': null,
        'currency': 'IDR',
        'seller_name': 'SPBU',
        'notes': 'Operasional',
        'submitted_at': '2026-09-23T10:00:00.000',
        'status': 'pending',
        'receipt_file_name': 'reimbursements/nota.jpg',
      });
    });
    final repository = ReimbursementRepository(
      client: client,
      tokenStore: await tokenStore(),
    );

    final claim = await repository.postClaim(
      amount: 150000,
      activityName: 'Bensin',
      category: ExpenseCategory.transport,
      sellerName: 'SPBU',
      notes: 'Operasional',
      receiptPath: receipt.path,
    );

    final multipart = seen as http.MultipartRequest;
    expect(multipart.url.toString(), ApiConstants.reimbursements);
    expect(multipart.headers['Authorization'], 'Bearer test-token');
    expect(multipart.fields['amount'], '150000.0');
    expect(multipart.fields['category'], 'transport');
    expect(multipart.files.single.field, 'receipt');
    expect(claim.status, ClaimStatus.pending);
    expect(claim.receiptFileName, 'reimbursements/nota.jpg');
  });

  test('timesheets fetch uses date query and complete posts proof', () async {
    final proof = await tempImage('proof.jpg');
    final seen = <http.BaseRequest>[];

    Map<String, dynamic> taskJson(bool done) => {
      'id': 'TSK-1',
      'name': 'Pasang bekisting',
      'assigned_date': '2026-09-23T00:00:00.000',
      'instructions': 'Instruksi admin',
      'is_completed': done,
      'proof_path': done ? 'timesheets/proof.jpg' : null,
      'completed_at': done ? '2026-09-23T11:00:00.000' : null,
    };

    final client = MockClient.streaming((request, _) async {
      seen.add(request);
      if (request.method == 'GET') {
        return streamed([taskJson(false)], 200);
      }
      return streamed(taskJson(true));
    });
    final repository = TimesheetRepository(
      client: client,
      tokenStore: await tokenStore(),
    );

    final tasks = await repository.fetchTasks(DateTime(2026, 9, 23));
    final completed = await repository.completeTaskRemote(
      taskId: 'TSK-1',
      proofPath: proof.path,
    );

    final getRequest = seen[0];
    expect(getRequest.url.queryParameters['date'], '2026-09-23');
    expect(getRequest.headers['Authorization'], 'Bearer test-token');
    expect(tasks.single.name, 'Pasang bekisting');
    expect(tasks.single.isCompleted, isFalse);
    final postRequest = seen[1] as http.MultipartRequest;
    expect(postRequest.url.toString(), '${ApiConstants.timesheets}/TSK-1');
    expect(postRequest.fields['status'], 'completed');
    expect(postRequest.files.single.field, 'proof');
    expect(completed.isCompleted, isTrue);
    expect(completed.proofPath, 'timesheets/proof.jpg');
  });

  test('izin post sends photo multipart and parses record', () async {
    final photo = await tempImage('surat.jpg');
    http.BaseRequest? seen;

    final client = MockClient.streaming((request, _) async {
      seen = request;
      return streamed({
        'id': 'IZN-1',
        'date': '2026-09-25T00:00:00.000',
        'reason': 'sick',
        'notes': 'Demam',
        'status': 'pending',
        'photo_path': 'leaves/surat.jpg',
        'created_at': '2026-09-23T09:00:00.000',
      });
    });
    final repository = IzinRepository(
      client: client,
      tokenStore: await tokenStore(),
    );

    final record = await repository.postIzin(
      date: DateTime(2026, 9, 25),
      reason: IzinReason.sick,
      notes: 'Demam',
      photoPath: photo.path,
    );

    final multipart = seen as http.MultipartRequest;
    expect(multipart.url.toString(), ApiConstants.leaves);
    expect(multipart.headers['Authorization'], 'Bearer test-token');
    expect(multipart.fields['reason'], 'sick');
    expect(multipart.files.single.field, 'photo');
    expect(record.status, IzinStatus.pending);
    expect(record.photoPath, 'leaves/surat.jpg');
  });
}
