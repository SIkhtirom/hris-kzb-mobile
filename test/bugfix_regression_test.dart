import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:field_supervisor_app/core/constants/api_constants.dart';
import 'package:field_supervisor_app/core/constants/app_strings.dart';
import 'package:field_supervisor_app/core/widgets/record_photo.dart';
import 'package:field_supervisor_app/data/mock/mock_user_data.dart';
import 'package:field_supervisor_app/data/models/attendance_record.dart';
import 'package:field_supervisor_app/data/models/geo_location.dart';
import 'package:field_supervisor_app/data/models/izin_record.dart';
import 'package:field_supervisor_app/data/models/kunjungan_record.dart';
import 'package:field_supervisor_app/data/models/reimbursement_claim.dart';
import 'package:field_supervisor_app/data/remote/auth_remote_data_source.dart';
import 'package:field_supervisor_app/data/repositories/attendance_repository.dart';
import 'package:field_supervisor_app/data/repositories/auth_repository.dart';
import 'package:field_supervisor_app/data/repositories/izin_repository.dart';
import 'package:field_supervisor_app/data/repositories/kunjungan_repository.dart';
import 'package:field_supervisor_app/data/repositories/reimbursement_repository.dart';
import 'package:field_supervisor_app/data/repositories/user_repository.dart';
import 'package:field_supervisor_app/services/camera_service.dart';
import 'package:field_supervisor_app/services/in_memory_token_store.dart';
import 'package:field_supervisor_app/services/location_service.dart';
import 'package:field_supervisor_app/services/photo_storage_service.dart';
import 'package:field_supervisor_app/services/selfie_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_supervisor_app/viewmodels/attendance_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/calendar_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/dashboard_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/izin_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/kunjungan_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/reimbursement_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/settings_viewmodel.dart';
import 'package:field_supervisor_app/views/attendance/attendance_screen.dart';
import 'package:field_supervisor_app/views/calendar/calendar_screen.dart';
import 'package:field_supervisor_app/views/home/home_screen.dart';
import 'package:field_supervisor_app/views/izin/izin_form_screen.dart';
import 'package:field_supervisor_app/views/kunjungan/kunjungan_screen.dart';
import 'package:field_supervisor_app/views/reimbursement/reimbursement_form_screen.dart';
import 'package:field_supervisor_app/views/settings/settings_screen.dart';
import 'package:field_supervisor_app/views/shell/main_shell.dart';

import 'test_fakes.dart';

class _FakeLocationService extends LocationService {
  @override
  Future<bool> requestLocationPermission() async => true;

  @override
  Future<GeoLocation> getCurrentLocation() async => const GeoLocation(
    latitude: -6.2,
    longitude: 106.8,
    address: 'Test Address',
  );
}

class _FakeCameraService extends CameraService {
  String path = '';

  @override
  Future<String?> takeSelfie() async => path;
}

void main() {
  Future<void> settle(WidgetTester tester, [int pumps = 6]) async {
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<InMemoryTokenStore> apiTokenStore() async {
    final store = InMemoryTokenStore();
    await store.writeTokens(accessToken: 'test-token');
    return store;
  }

  MockClient apiClientWith(List<Map<String, dynamic>> items) {
    return MockClient((request) async {
      return http.Response(
        jsonEncode({'status': true, 'message': 'ok', 'data': items}),
        200,
        headers: {'Content-Type': 'application/json'},
      );
    });
  }

  Future<http.StreamedResponse> streamedData(
    Object data, [
    int code = 201,
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

  Map<String, dynamic> checkInJson({
    required String id,
    required DateTime timestamp,
    String address = 'Site Konstruksi Menara B',
    double latitude = -6.2259,
    double longitude = 106.8162,
    String? photoPath,
  }) {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'event_type': 'check_in',
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'present',
      'photo_path': photoPath,
    };
  }

  Map<String, dynamic> checkOutJson({
    required String id,
    required DateTime timestamp,
    String address = 'Site Konstruksi Menara B',
    double latitude = -6.2259,
    double longitude = 106.8162,
    String? photoPath,
  }) {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'event_type': 'check_out',
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'present',
      'photo_path': photoPath,
    };
  }

  testWidgets(
    'checkout starts blank and isolated after check-in exists today',
    (tester) async {
      final client = apiClientWith([
        checkInJson(
          id: 'ATT-TODAY-CHECKIN',
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          photoPath: 'C:\\fake\\checkin_selfie.jpg',
        ),
      ]);

      final viewModel = AttendanceViewModel(
        attendanceRepository: AttendanceRepository(
          client: client,
          tokenStore: await apiTokenStore(),
        ),
        cameraService: CameraService(),
        locationService: LocationService(),
        selfieStorageService: SelfieStorageService(),
        attendanceStore: MemoryAttendanceStore(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AttendanceViewModel>.value(value: viewModel),
          ],
          child: const MaterialApp(
            home: AttendanceScreen(action: ClockEventType.checkOut),
          ),
        ),
      );
      await tester.pump();
      await settle(tester);

      expect(viewModel.hasClockedInToday, isTrue);
      expect(viewModel.nextAction, ClockEventType.checkOut);
      expect(viewModel.selfiePath, isNull);
      expect(viewModel.latitude, isNull);
      expect(viewModel.longitude, isNull);
      expect(viewModel.address, AppStrings.locationNotObtained);
      expect(viewModel.canCheckOut, isFalse);
      expect(viewModel.showActionButton, isFalse);
      expect(find.text(AppStrings.checkOutAction), findsNothing);
      expect(find.text(AppStrings.checkOutWaitingLabel), findsOneWidget);
      expect(find.text(AppStrings.selfiePrompt), findsOneWidget);

      viewModel.dispose();
    },
  );

  testWidgets('kunjungan time field is read-only and stable', (tester) async {
    final viewModel = KunjunganViewModel(
      repository: KunjunganRepository(),
      locationService: _FakeLocationService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<KunjunganViewModel>.value(value: viewModel),
        ],
        child: const MaterialApp(
          home: KunjunganScreen(mode: KunjunganMode.start),
        ),
      ),
    );
    await tester.pump();
    await settle(tester, 3);

    expect(find.byType(DropdownButtonFormField<String>), findsNothing);

    final timeField = tester.widget<TextFormField>(
      find.byKey(const Key('kunjungan_time_field')),
    );
    final shown = timeField.controller!.text;
    expect(shown, isNotEmpty);

    await tester.tap(find.byKey(const Key('kunjungan_time_field')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DropdownMenuItem<String>), findsNothing);

    await tester.pump(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 30));
    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('kunjungan_time_field')))
          .controller!
          .text,
      shown,
    );

    viewModel.dispose();
  });

  testWidgets('izin reason dropdown value stays within items', (tester) async {
    final viewModel = IzinViewModel(izinRepository: IzinRepository());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<IzinViewModel>.value(value: viewModel),
        ],
        child: const MaterialApp(home: IzinFormScreen()),
      ),
    );
    await tester.pump();
    await settle(tester, 3);

    final dropdown = find.byType(DropdownButtonFormField<IzinReason>);
    expect(dropdown, findsOneWidget);

    for (var i = 0; i < IzinReason.values.length; i++) {
      await tester.tap(dropdown);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(
        find.text(AppStrings.izinReasonLabel(IzinReason.values[i])).last,
      );
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester, 3);
      expect(tester.takeException(), isNull);
    }

    viewModel.dispose();
  });

  testWidgets(
    'reimbursement category and currency dropdowns keep valid values',
    (tester) async {
      final viewModel = ReimbursementViewModel(
        reimbursementRepository: ReimbursementRepository(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ReimbursementViewModel>.value(
              value: viewModel,
            ),
          ],
          child: const MaterialApp(home: ReimbursementFormScreen()),
        ),
      );
      await tester.pump();
      await settle(tester, 3);

      final categoryDropdown = find.byType(
        DropdownButtonFormField<ExpenseCategory>,
      );
      expect(categoryDropdown, findsOneWidget);
      for (var i = 0; i < ExpenseCategory.values.length; i++) {
        await tester.tap(categoryDropdown);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(
          find
              .text(AppStrings.expenseCategoryLabel(ExpenseCategory.values[i]))
              .last,
        );
        await tester.pump(const Duration(milliseconds: 400));
        await settle(tester, 3);
        expect(tester.takeException(), isNull);
      }

      final currencyDropdown = find.byType(DropdownButtonFormField<String>);
      expect(currencyDropdown, findsOneWidget);
      await tester.tap(currencyDropdown);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(AppStrings.usd).last);
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester, 3);
      expect(tester.takeException(), isNull);

      viewModel.dispose();
    },
  );

  testWidgets('check-in screen shows captured selfie timestamp and status', (
    tester,
  ) async {
    final now = DateTime.now();
    final client = apiClientWith([
      checkInJson(
        id: 'ATT-TODAY-VERIFICATION',
        timestamp: DateTime(now.year, now.month, now.day, 8, 30, 15),
        photoPath: 'C:\\fake\\verification_selfie.jpg',
      ),
    ]);

    final viewModel = AttendanceViewModel(
      attendanceRepository: AttendanceRepository(
        client: client,
        tokenStore: await apiTokenStore(),
      ),
      cameraService: CameraService(),
      locationService: LocationService(),
      selfieStorageService: SelfieStorageService(),
      attendanceStore: MemoryAttendanceStore(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AttendanceViewModel>.value(value: viewModel),
        ],
        child: const MaterialApp(
          home: AttendanceScreen(action: ClockEventType.checkIn),
        ),
      ),
    );
    await tester.pump();
    await settle(tester, 3);

    expect(viewModel.verificationRecord, isNotNull);
    expect(viewModel.selfiePath, 'C:\\fake\\verification_selfie.jpg');
    expect(viewModel.verificationTimeLabel, '08:30:15');
    expect(
      find.textContaining(AppStrings.attendanceRecordedLabel),
      findsOneWidget,
    );
    expect(find.textContaining(viewModel.verificationTimeLabel), findsWidgets);

    viewModel.dispose();
  });

  testWidgets(
    'check-in screen restores selfie address coordinates on re-entry',
    (tester) async {
      final now = DateTime.now();
      final client = apiClientWith([
        checkInJson(
          id: 'ATT-TODAY-RESTORE',
          timestamp: DateTime(now.year, now.month, now.day, 7, 45, 10),
          address: 'Kantor Site, Menara Riverside',
          latitude: -6.2069,
          longitude: 106.8489,
          photoPath: 'C:\\fake\\restore_selfie.jpg',
        ),
      ]);

      final viewModel = AttendanceViewModel(
        attendanceRepository: AttendanceRepository(
          client: client,
          tokenStore: await apiTokenStore(),
        ),
        cameraService: CameraService(),
        locationService: LocationService(),
        selfieStorageService: SelfieStorageService(),
        attendanceStore: MemoryAttendanceStore(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AttendanceViewModel>.value(value: viewModel),
          ],
          child: const MaterialApp(
            home: AttendanceScreen(action: ClockEventType.checkIn),
          ),
        ),
      );
      await tester.pump();
      await settle(tester, 3);

      expect(viewModel.verificationRecord, isNotNull);
      expect(viewModel.selfiePath, 'C:\\fake\\restore_selfie.jpg');
      expect(viewModel.address, 'Kantor Site, Menara Riverside');
      expect(viewModel.latitude, closeTo(-6.2069, 0.00001));
      expect(viewModel.longitude, closeTo(106.8489, 0.00001));
      expect(find.text(AppStrings.addressLabel), findsWidgets);
      expect(find.text('Kantor Site, Menara Riverside'), findsWidgets);
      expect(find.textContaining('-6.20690'), findsWidgets);
      expect(find.textContaining('106.84890'), findsWidgets);

      viewModel.dispose();
    },
  );

  test(
    'attendance repository persists selfie address and coordinates',
    () async {
      final repository = AttendanceRepository();
      final now = DateTime.now();
      final record = AttendanceRecord(
        id: 'ATT-PERSIST-UNIT',
        timestamp: now,
        eventType: ClockEventType.checkIn,
        address: 'Jl. Jend. Sudirman No. 45, Jakarta',
        latitude: -6.2088,
        longitude: 106.8456,
        status: AttendanceStatus.present,
        photoPath: 'C:\\fake\\persist_selfie.jpg',
      );

      await repository.add(record);

      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      final loaded = await repository.fetchByDateRange(start: start, end: end);
      final saved = loaded.firstWhere((item) => item.id == record.id);

      expect(saved.photoPath, record.photoPath);
      expect(saved.address, record.address);
      expect(saved.latitude, record.latitude);
      expect(saved.longitude, record.longitude);
      expect(saved.timestamp, record.timestamp);
      expect(saved.eventType, record.eventType);
    },
  );

  testWidgets('history day detail renders selfie address and coordinates', (
    tester,
  ) async {
    final now = DateTime.now();
    final client = apiClientWith([
      checkInJson(
        id: 'ATT-HISTORY-IN',
        timestamp: DateTime(now.year, now.month, now.day, 8, 2, 11),
        address: 'Kantor Site, Menara Riverside',
        latitude: -6.2069,
        longitude: 106.8489,
        photoPath: 'C:\\fake\\history_checkin.jpg',
      ),
      checkOutJson(
        id: 'ATT-HISTORY-OUT',
        timestamp: DateTime(now.year, now.month, now.day, 16, 30, 55),
        address: 'Kantor Site, Menara Riverside',
        latitude: -6.2069,
        longitude: 106.8489,
      ),
    ]);

    final viewModel = CalendarViewModel(
      attendanceRepository: AttendanceRepository(
        client: client,
        tokenStore: await apiTokenStore(),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CalendarViewModel>.value(value: viewModel),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pump();
    await settle(tester, 3);

    await tester.tap(find.text('${now.day}'), warnIfMissed: false);
    await tester.pump();
    await settle(tester, 2);

    expect(find.text(AppStrings.dayDetailTitle), findsOneWidget);
    expect(
      find.text(AppStrings.eventTypeLabel(ClockEventType.checkIn)),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.eventTypeLabel(ClockEventType.checkOut)),
      findsOneWidget,
    );
    expect(find.textContaining('08:02:11'), findsOneWidget);
    expect(find.textContaining('16:30:55'), findsOneWidget);
    expect(find.text('Kantor Site, Menara Riverside'), findsNWidgets(2));
    expect(find.textContaining('-6.20690'), findsNWidgets(2));
    expect(find.textContaining('106.84890'), findsNWidgets(2));
    expect(find.text(AppStrings.noPhotoLabel), findsNWidgets(2));

    viewModel.dispose();
  });

  testWidgets('home blocks repeat check-in while checkout stays open', (
    tester,
  ) async {
    final now = DateTime.now();
    final attendanceClient = apiClientWith([
      checkInJson(
        id: 'ATT-TODAY-DIALOG-CHECKIN',
        timestamp: now.subtract(const Duration(minutes: 120)),
      ),
      checkOutJson(
        id: 'ATT-TODAY-DIALOG-CHECKOUT',
        timestamp: now.subtract(const Duration(minutes: 100)),
      ),
    ]);
    final tokenStore = await apiTokenStore();

    final viewModel = DashboardViewModel(
      userRepository: UserRepository(),
      attendanceRepository: AttendanceRepository(
        client: attendanceClient,
        tokenStore: tokenStore,
      ),
      reimbursementRepository: ReimbursementRepository(
        client: apiClientWith([]),
        tokenStore: tokenStore,
      ),
      photoStorageService: PhotoStorageService(),
      attendanceStore: MemoryAttendanceStore(),
    );
    final attendanceViewModel = AttendanceViewModel(
      attendanceRepository: AttendanceRepository(
        client: apiClientWith([]),
        tokenStore: tokenStore,
      ),
      cameraService: CameraService(),
      locationService: LocationService(),
      selfieStorageService: SelfieStorageService(),
      attendanceStore: MemoryAttendanceStore(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DashboardViewModel>.value(value: viewModel),
          ChangeNotifierProvider<AttendanceViewModel>.value(
            value: attendanceViewModel,
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text(AppStrings.checkInCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AppStrings.alreadyClockedTodayMessage), findsOneWidget);
    await tester.tap(find.text(AppStrings.okActionLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(AppStrings.checkOutCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AppStrings.alreadyClockedTodayMessage), findsOneWidget);
    await tester.tap(find.text(AppStrings.okActionLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    viewModel.dispose();
    attendanceViewModel.dispose();
  });

  test(
    'SelfieStorageService copies captured photo to permanent directory',
    () async {
      final captureDir = await Directory.systemTemp.createTemp(
        'selfie_unit_capture',
      );
      final documentsDir = await Directory.systemTemp.createTemp(
        'selfie_unit_documents',
      );
      final source = File(
        '${captureDir.path}${Platform.pathSeparator}photo.png',
      );
      await source.writeAsString('png-bytes');

      final service = SelfieStorageService(
        directoryProvider: () async => documentsDir,
      );

      final saved = await service.copyToPermanent(source.path);
      expect(saved, isNotNull);
      saved!;
      expect(
        saved,
        startsWith('${documentsDir.path}${Platform.pathSeparator}selfies'),
      );
      expect(saved, endsWith('.png'));
      expect(File(saved).existsSync(), isTrue);
      expect(await File(saved).readAsString(), 'png-bytes');

      expect(
        await service.copyToPermanent(
          '${captureDir.path}${Platform.pathSeparator}missing.jpg',
        ),
        isNull,
      );

      await captureDir.delete(recursive: true);
      await documentsDir.delete(recursive: true);
    },
  );

  test(
    'attendance submission persists selfie permanently and survives re-entry',
    () async {
      final now = DateTime.now();
      final captureDir = await Directory.systemTemp.createTemp(
        'selfie_capture',
      );
      final documentsDir = await Directory.systemTemp.createTemp(
        'selfie_documents',
      );
      final source = File(
        '${captureDir.path}${Platform.pathSeparator}captured.jpg',
      );
      await source.writeAsString('fake-captured-image');

      final camera = _FakeCameraService()..path = source.path;
      final storage = SelfieStorageService(
        directoryProvider: () async => documentsDir,
      );
      final store = MemoryAttendanceStore();
      final tokenStore = await apiTokenStore();
      final savedJson = {
        'id': 'ATT-LIVE-1',
        'timestamp': now.toIso8601String(),
        'event_type': 'check_in',
        'address': 'Test Address',
        'latitude': -6.2,
        'longitude': 106.8,
        'status': 'present',
        'photo_path': 'attendances/live.jpg',
      };
      final client = MockClient.streaming((request, stream) {
        if (request.method == 'GET') {
          return streamedData([savedJson]);
        }
        return streamedData(savedJson);
      });
      final repository = AttendanceRepository(
        client: client,
        tokenStore: tokenStore,
      );
      final viewModel = AttendanceViewModel(
        attendanceRepository: repository,
        cameraService: camera,
        locationService: _FakeLocationService(),
        selfieStorageService: storage,
        attendanceStore: store,
      );

      final submitted = await viewModel.submit();
      expect(submitted, isTrue);

      final permanentPath = viewModel.selfiePath!;
      expect(
        permanentPath,
        startsWith('${documentsDir.path}${Platform.pathSeparator}selfies'),
      );
      expect(File(permanentPath).existsSync(), isTrue);
      expect(await File(permanentPath).readAsString(), 'fake-captured-image');
      expect(viewModel.verificationRecord, isNotNull);
      expect(viewModel.verificationTimeLabel, isNotEmpty);
      expect(store.checkInRecord?.photoPath, permanentPath);

      viewModel.configure(ClockEventType.checkIn);
      await viewModel.loadInitialState();
      expect(viewModel.verificationRecord, isNotNull);
      expect(viewModel.selfiePath, 'attendances/live.jpg');
      expect(viewModel.address, 'Test Address');
      expect(viewModel.latitude, closeTo(-6.2, 0.00001));
      expect(viewModel.longitude, closeTo(106.8, 0.00001));

      viewModel.dispose();
      await captureDir.delete(recursive: true);
      await documentsDir.delete(recursive: true);
    },
  );

  test('dashboard seeds active user synchronously without loading', () {
    final viewModel = DashboardViewModel(
      userRepository: UserRepository(),
      attendanceRepository: AttendanceRepository(),
      reimbursementRepository: ReimbursementRepository(),
      photoStorageService: PhotoStorageService(),
      attendanceStore: MemoryAttendanceStore(),
    );

    expect(viewModel.user?.name, 'Andi Pratama');

    viewModel.dispose();
  });

  test('profile photo change syncs between dashboard and settings', () async {
    final captureDir = await Directory.systemTemp.createTemp(
      'profile_sync_capture',
    );
    final documentsDir = await Directory.systemTemp.createTemp(
      'profile_sync_documents',
    );
    final source = File(
      '${captureDir.path}${Platform.pathSeparator}avatar.jpg',
    );
    await source.writeAsString('avatar-bytes');

    final photos = PhotoStorageService(
      directoryProvider: () async => documentsDir,
    );
    final dashboard = DashboardViewModel(
      userRepository: UserRepository(),
      attendanceRepository: AttendanceRepository(),
      reimbursementRepository: ReimbursementRepository(),
      photoStorageService: photos,
      attendanceStore: MemoryAttendanceStore(),
    );

    final updated = await dashboard.updateProfilePicture(source.path);
    expect(updated, isTrue);
    final photoPath = dashboard.user?.profilePicturePath;
    expect(photoPath, isNotNull);
    expect(File(photoPath!).existsSync(), isTrue);

    final settings = SettingsViewModel(
      userRepository: UserRepository(),
      photoStorageService: photos,
    );
    await settings.load();
    expect(settings.user?.profilePicturePath, photoPath);

    dashboard.dispose();
    settings.dispose();
    await captureDir.delete(recursive: true);
    await documentsDir.delete(recursive: true);
  });

  test('attendance day state survives view model recreation', () async {
    final captureDir = await Directory.systemTemp.createTemp(
      'attendance_restart_capture',
    );
    final documentsDir = await Directory.systemTemp.createTemp(
      'attendance_restart_documents',
    );
    final source = File(
      '${captureDir.path}${Platform.pathSeparator}captured.jpg',
    );
    await source.writeAsString('restart-bytes');
    final store = MemoryAttendanceStore();
    final tokenStore = await apiTokenStore();
    final savedJson = {
      'id': 'ATT-RESTART-1',
      'timestamp': DateTime.now().toIso8601String(),
      'event_type': 'check_in',
      'address': 'Test Address',
      'latitude': -6.2,
      'longitude': 106.8,
      'status': 'present',
      'photo_path': 'attendances/restart.jpg',
    };
    final submitClient = MockClient.streaming(
      (request, stream) => streamedData(savedJson),
    );

    final first = AttendanceViewModel(
      attendanceRepository: AttendanceRepository(
        client: submitClient,
        tokenStore: tokenStore,
      ),
      cameraService: _FakeCameraService()..path = source.path,
      locationService: _FakeLocationService(),
      selfieStorageService: SelfieStorageService(
        directoryProvider: () async => documentsDir,
      ),
      attendanceStore: store,
    );
    expect(await first.submit(), isTrue);
    final permanentPath = first.selfiePath!;
    first.dispose();

    final emptyClient = apiClientWith([]);
    final dashboard = DashboardViewModel(
      userRepository: UserRepository(),
      attendanceRepository: AttendanceRepository(
        client: emptyClient,
        tokenStore: tokenStore,
      ),
      reimbursementRepository: ReimbursementRepository(
        client: emptyClient,
        tokenStore: tokenStore,
      ),
      photoStorageService: PhotoStorageService(),
      attendanceStore: store,
    );
    await dashboard.loadDashboard();
    expect(dashboard.hasClockedInToday, isTrue);

    final second = AttendanceViewModel(
      attendanceRepository: AttendanceRepository(
        client: emptyClient,
        tokenStore: tokenStore,
      ),
      cameraService: CameraService(),
      locationService: LocationService(),
      selfieStorageService: SelfieStorageService(),
      attendanceStore: store,
    );
    second.configure(ClockEventType.checkIn);
    await second.loadInitialState();
    expect(second.hasClockedInToday, isTrue);
    expect(second.verificationRecord, isNotNull);
    expect(second.selfiePath, permanentPath);
    expect(File(second.selfiePath!).existsSync(), isTrue);
    expect(second.address, 'Test Address');
    expect(second.latitude, closeTo(-6.2, 0.00001));
    expect(second.longitude, closeTo(106.8, 0.00001));

    dashboard.dispose();
    second.dispose();
    await captureDir.delete(recursive: true);
    await documentsDir.delete(recursive: true);
  });

  testWidgets('attendance load times out with poor connection message', (
    tester,
  ) async {
    final hangingClient = MockClient.streaming(
      (request, stream) => Completer<http.StreamedResponse>().future,
    );
    final viewModel = AttendanceViewModel(
      attendanceRepository: AttendanceRepository(
        client: hangingClient,
        tokenStore: await apiTokenStore(),
      ),
      cameraService: CameraService(),
      locationService: LocationService(),
      selfieStorageService: SelfieStorageService(),
      attendanceStore: MemoryAttendanceStore(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AttendanceViewModel>.value(value: viewModel),
        ],
        child: const MaterialApp(
          home: AttendanceScreen(action: ClockEventType.checkIn),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));

    expect(viewModel.errorMessage, AppStrings.poorConnectionMessage);
    expect(find.text(AppStrings.poorConnectionMessage), findsWidgets);

    viewModel.dispose();
  });

  testWidgets('checkout stays locked before three hours pass', (tester) async {
    final client = apiClientWith([
      checkInJson(
        id: 'ATT-REPEAT',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ]);
    final viewModel = AttendanceViewModel(
      attendanceRepository: AttendanceRepository(
        client: client,
        tokenStore: await apiTokenStore(),
      ),
      cameraService: CameraService(),
      locationService: LocationService(),
      selfieStorageService: SelfieStorageService(),
      attendanceStore: MemoryAttendanceStore(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AttendanceViewModel>.value(value: viewModel),
        ],
        child: const MaterialApp(
          home: AttendanceScreen(action: ClockEventType.checkIn),
        ),
      ),
    );
    await tester.pump();
    await settle(tester, 3);

    expect(viewModel.hasClockedInToday, isTrue);
    expect(viewModel.canCheckOut, isFalse);
    expect(viewModel.showActionButton, isFalse);
    expect(find.text(AppStrings.checkOutWaitingLabel), findsOneWidget);

    viewModel.dispose();
  });

  test(
    'profile photo and birth date persist across repository instances',
    () async {
      SharedPreferences.setMockInitialValues({});
      final original = MockUserData.currentUser;
      final repository = UserRepository();
      final updated = await repository.updateUser(
        original.copyWith(
          profilePicturePath: '/docs/profile/avatar.jpg',
          dateOfBirth: DateTime(1995, 5, 20),
        ),
      );
      expect(updated.profilePicturePath, '/docs/profile/avatar.jpg');

      final reloaded = await UserRepository().fetchCurrentUser();
      expect(reloaded.profilePicturePath, '/docs/profile/avatar.jpg');
      expect(reloaded.dateOfBirth, DateTime(1995, 5, 20));

      MockUserData.currentUser = original;
      SharedPreferences.setMockInitialValues({});
    },
  );

  testWidgets('profile screen pre-fills saved date of birth', (tester) async {
    final original = MockUserData.currentUser;
    MockUserData.currentUser = original.copyWith(
      dateOfBirth: DateTime(1995, 5, 20),
    );
    final settingsViewModel = SettingsViewModel(
      userRepository: UserRepository(),
      photoStorageService: PhotoStorageService(),
    );
    final dashboardViewModel = DashboardViewModel(
      userRepository: UserRepository(),
      attendanceRepository: AttendanceRepository(
        client: apiClientWith([]),
        tokenStore: await apiTokenStore(),
      ),
      reimbursementRepository: ReimbursementRepository(
        client: apiClientWith([]),
        tokenStore: await apiTokenStore(),
      ),
      photoStorageService: PhotoStorageService(),
      attendanceStore: MemoryAttendanceStore(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsViewModel>.value(
            value: settingsViewModel,
          ),
          ChangeNotifierProvider<DashboardViewModel>.value(
            value: dashboardViewModel,
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump();
    await settle(tester);

    expect(
      find.text(AppStrings.shortDate(DateTime(1995, 5, 20))),
      findsOneWidget,
    );

    settingsViewModel.dispose();
    dashboardViewModel.dispose();
    MockUserData.currentUser = original;
  });

  testWidgets('reimbursement date field shows solid selected date', (
    tester,
  ) async {
    final viewModel = ReimbursementViewModel(
      reimbursementRepository: ReimbursementRepository(
        client: apiClientWith([]),
        tokenStore: await apiTokenStore(),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReimbursementViewModel>.value(
            value: viewModel,
          ),
        ],
        child: const MaterialApp(home: ReimbursementFormScreen()),
      ),
    );
    await tester.pump();
    await settle(tester, 2);

    expect(find.text(AppStrings.fullDate(DateTime.now())), findsOneWidget);

    viewModel.dispose();
  });

  test('file url resolves server paths and keeps absolute urls', () {
    final host = Uri.parse(ApiConstants.baseUrl).host;
    final url = ApiConstants.fileUrl('attendances/selfie.jpg');
    expect(url, contains(host));
    expect(url, endsWith('/storage/attendances/selfie.jpg'));
    final absolute = Uri(
      scheme: 'https',
      host: 'cdn.example.com',
      path: 'x.png',
    ).toString();
    expect(ApiConstants.fileUrl(absolute), absolute);
    expect(ApiConstants.isLocalFilePath('C:\\fake\\x.jpg'), isTrue);
    expect(ApiConstants.isLocalFilePath('/data/x.jpg'), isTrue);
    expect(ApiConstants.isLocalFilePath('attendances/x.jpg'), isFalse);
  });

  testWidgets('profile photo and name survive settings dashboard round trip', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final original = MockUserData.currentUser;
    late Directory captureDir;
    late Directory documentsDir;
    late File source;
    await tester.runAsync(() async {
      captureDir = await Directory.systemTemp.createTemp('roundtrip_capture');
      documentsDir = await Directory.systemTemp.createTemp(
        'roundtrip_documents',
      );
      source = File('${captureDir.path}${Platform.pathSeparator}avatar.jpg');
      await source.writeAsString('avatar-bytes');
    });
    final photos = PhotoStorageService(
      directoryProvider: () async => documentsDir,
    );
    final tokenStore = await apiTokenStore();
    final emptyClient = apiClientWith([]);

    DashboardViewModel buildDashboard() => DashboardViewModel(
      userRepository: UserRepository(),
      attendanceRepository: AttendanceRepository(
        client: emptyClient,
        tokenStore: tokenStore,
      ),
      reimbursementRepository: ReimbursementRepository(
        client: emptyClient,
        tokenStore: tokenStore,
      ),
      photoStorageService: photos,
      attendanceStore: MemoryAttendanceStore(),
    );
    SettingsViewModel buildSettings() => SettingsViewModel(
      userRepository: UserRepository(),
      photoStorageService: photos,
    );

    final dashboardViewModel = buildDashboard();
    final settingsViewModel = buildSettings();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DashboardViewModel>.value(
            value: dashboardViewModel,
          ),
          ChangeNotifierProvider<SettingsViewModel>.value(
            value: settingsViewModel,
          ),
          Provider<AuthRepository>(
            create: (_) => AuthRepository(
              remoteDataSource: MockAuthRemoteDataSource(),
              tokenStore: InMemoryTokenStore(),
            ),
          ),
        ],
        child: const MaterialApp(home: MainShell()),
      ),
    );
    await tester.pump();
    await settle(tester);

    final photoUpdated = await tester.runAsync(
      () => dashboardViewModel.updateProfilePicture(source.path),
    );
    expect(photoUpdated, isTrue);
    final photoPath = dashboardViewModel.user?.profilePicturePath;
    expect(photoPath, isNotNull);
    await tester.pump();
    await settle(tester, 2);

    RecordPhoto homeAvatar() => tester
        .widgetList<RecordPhoto>(find.byType(RecordPhoto))
        .firstWhere((widget) => widget.path == photoPath);
    expect(homeAvatar().path, photoPath);

    await tester.tap(find.text(AppStrings.navMore));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text(AppStrings.profileLabel));
    await tester.pump();
    await settle(tester, 3);

    expect(
      tester
          .widgetList<RecordPhoto>(find.byType(RecordPhoto))
          .any((widget) => widget.path == photoPath),
      isTrue,
    );

    await tester.enterText(find.byType(TextFormField).first, 'Budi Santoso');
    await tester.pump();

    await tester.tap(
      find.text(AppStrings.dateOfBirthHint),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('OK'));
    await tester.pump();
    await settle(tester, 2);

    await tester.tap(find.text(AppStrings.saveButton));
    await tester.pump();
    await settle(tester, 6);

    expect(dashboardViewModel.user?.name, 'Budi Santoso');
    expect(dashboardViewModel.user?.dateOfBirth, isNotNull);
    expect(dashboardViewModel.user?.profilePicturePath, photoPath);

    await tester.tap(find.text(AppStrings.profileLabel));
    await tester.pump();
    await settle(tester, 3);

    expect(find.text('Budi Santoso'), findsWidgets);
    expect(
      tester
          .widgetList<RecordPhoto>(find.byType(RecordPhoto))
          .any((widget) => widget.path == photoPath),
      isTrue,
    );

    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.text(AppStrings.navHome));
    await tester.pump();
    await settle(tester, 2);

    expect(find.text('Budi Santoso'), findsNothing);
    expect(
      tester
          .widgetList<RecordPhoto>(find.byType(RecordPhoto))
          .any((widget) => widget.path == photoPath),
      isTrue,
    );
    expect(dashboardViewModel.user?.profilePicturePath, photoPath);

    dashboardViewModel.dispose();
    settingsViewModel.dispose();
    MockUserData.currentUser = original;
    await tester.runAsync(() async {
      await captureDir.delete(recursive: true);
      await documentsDir.delete(recursive: true);
    });
  });
}
