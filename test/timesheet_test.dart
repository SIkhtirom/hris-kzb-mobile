import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:field_supervisor_app/core/constants/app_strings.dart';
import 'package:field_supervisor_app/data/models/timesheet_task.dart';
import 'package:field_supervisor_app/data/repositories/timesheet_repository.dart';
import 'package:field_supervisor_app/services/in_memory_token_store.dart';
import 'package:field_supervisor_app/viewmodels/timesheet_viewmodel.dart';
import 'package:field_supervisor_app/views/timesheet/timesheet_screen.dart';

void main() {
  Future<void> settle(WidgetTester tester, [int pumps = 4]) async {
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<InMemoryTokenStore> apiTokenStore() async {
    final store = InMemoryTokenStore();
    await store.writeTokens(accessToken: 'test-token');
    return store;
  }

  Future<http.StreamedResponse> streamedData(
    Object data, [
    int code = 200,
  ]) async {
    final bytes = utf8.encode(
      jsonEncode({'status': true, 'message': 'ok', 'data': data}),
    );
    return http.StreamedResponse(
      Stream.value(bytes),
      code,
      headers: {'Content-Type': 'application/json'},
    );
  }

  Map<String, dynamic> taskJson(bool done) => {
    'id': 'TSK-TEST-001',
    'name': 'Pasang bekisting kolom',
    'assigned_date': '2026-09-23T00:00:00.000',
    'instructions': 'Instruksi tugas dari dashboard admin',
    'is_completed': done,
    'proof_path': done ? 'timesheets/proof.jpg' : null,
    'completed_at': done ? '2026-09-23T11:00:00.000' : null,
  };

  TimesheetTask ownerTask(DateTime assignedDate) => TimesheetTask(
    id: 'TSK-TEST-001',
    name: 'Pasang bekisting kolom',
    assignedDate: assignedDate,
    hour: 9,
    minute: 0,
    instructions: 'Instruksi tugas dari dashboard admin',
  );

  test('repository starts empty and persists owner-assigned tasks', () async {
    final repository = TimesheetRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    expect(await repository.fetchForDate(today), isEmpty);

    await repository.add(ownerTask(today));

    final loaded = await repository.fetchForDate(today);
    expect(loaded, hasLength(1));
    expect(loaded.single.instructions.trim(), isNotEmpty);
    expect(loaded.single.isCompleted, isFalse);

    final completedAt = DateTime(2026, 1, 1, 9, 30);
    await repository.completeTask(
      loaded.single.id,
      '/tmp/proof-1.jpg',
      completedAt,
    );

    final updated = (await repository.fetchForDate(today)).single;
    expect(updated.isCompleted, isTrue);
    expect(updated.proofPath, '/tmp/proof-1.jpg');
    expect(updated.completedAt, completedAt);
  });

  test('view model loads remote tasks and completes one with proof', () async {
    final proofDir = await Directory.systemTemp.createTemp('timesheet_proof');
    final proofFile = File(
      '${proofDir.path}${Platform.pathSeparator}proof.jpg',
    );
    await proofFile.writeAsString('proof-bytes');

    var completed = false;
    final client = MockClient.streaming((request, _) async {
      if (request.method == 'GET') {
        return streamedData([taskJson(completed)]);
      }
      completed = true;
      return streamedData(taskJson(true), 201);
    });
    final viewModel = TimesheetViewModel(
      repository: TimesheetRepository(
        client: client,
        tokenStore: await apiTokenStore(),
      ),
    );
    await viewModel.loadTasks();

    expect(viewModel.tasks, hasLength(1));
    expect(viewModel.proofPreviewPath, isNull);

    final task = viewModel.tasks.first;
    final success = await viewModel.submitProof(
      task,
      proofPath: proofFile.path,
    );

    expect(success, isTrue);
    expect(viewModel.proofPreviewPath, isNull);

    final updated = viewModel.tasks.firstWhere((item) => item.id == task.id);
    expect(updated.isCompleted, isTrue);
    expect(updated.proofPath, 'timesheets/proof.jpg');
    expect(updated.completedAt, isNotNull);

    viewModel.dispose();
    await proofDir.delete(recursive: true);
  });

  test('view model rejects submission without a proof image', () async {
    final client = MockClient.streaming(
      (request, stream) => streamedData(<dynamic>[]),
    );
    final viewModel = TimesheetViewModel(
      repository: TimesheetRepository(
        client: client,
        tokenStore: await apiTokenStore(),
      ),
    );
    await viewModel.loadTasks();

    final success = await viewModel.submitProof(ownerTask(DateTime.now()));
    expect(success, isFalse);
    expect(viewModel.errorMessage, AppStrings.proofPickError);

    viewModel.dispose();
  });

  testWidgets('timesheet renders empty state before admin assigns tasks', (
    tester,
  ) async {
    final client = MockClient.streaming(
      (request, stream) => streamedData(<dynamic>[]),
    );
    final viewModel = TimesheetViewModel(
      repository: TimesheetRepository(
        client: client,
        tokenStore: await apiTokenStore(),
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<TimesheetViewModel>.value(
        value: viewModel,
        child: const MaterialApp(home: TimesheetScreen()),
      ),
    );
    await tester.pump();
    await settle(tester, 6);

    expect(viewModel.tasks, isEmpty);
    expect(find.text(AppStrings.noTasksTitle), findsOneWidget);
    expect(find.text(AppStrings.noTasksBody), findsOneWidget);

    viewModel.dispose();
  });
}
