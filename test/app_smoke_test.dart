import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:field_supervisor_app/app.dart';
import 'package:field_supervisor_app/core/constants/app_strings.dart';
import 'package:field_supervisor_app/data/models/attendance_record.dart'
    show AttendanceStatus;
import 'package:field_supervisor_app/data/mock/mock_user_data.dart';
import 'package:field_supervisor_app/data/remote/auth_remote_data_source.dart';
import 'package:field_supervisor_app/data/repositories/attendance_repository.dart';
import 'package:field_supervisor_app/data/repositories/auth_repository.dart';
import 'package:field_supervisor_app/data/repositories/izin_repository.dart';
import 'package:field_supervisor_app/data/repositories/kunjungan_repository.dart';
import 'package:field_supervisor_app/data/repositories/reimbursement_repository.dart';
import 'package:field_supervisor_app/data/repositories/timesheet_repository.dart';
import 'package:field_supervisor_app/data/repositories/user_repository.dart';
import 'package:field_supervisor_app/services/camera_service.dart';
import 'package:field_supervisor_app/services/in_memory_token_store.dart';
import 'package:field_supervisor_app/services/location_service.dart';
import 'package:field_supervisor_app/services/photo_storage_service.dart';
import 'package:field_supervisor_app/services/selfie_storage_service.dart';
import 'package:field_supervisor_app/services/token_store.dart';
import 'package:field_supervisor_app/viewmodels/attendance_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/calendar_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/dashboard_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/izin_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/kunjungan_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/login_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/reimbursement_viewmodel.dart';
import 'package:field_supervisor_app/viewmodels/timesheet_viewmodel.dart';
import 'package:field_supervisor_app/views/auth/login_screen.dart';
import 'package:field_supervisor_app/views/shell/main_shell.dart';

import 'test_fakes.dart';

MockClient buildMockApiClient() {
  return MockClient((request) async {
    return http.Response(
      jsonEncode({'status': true, 'message': 'ok', 'data': <dynamic>[]}),
      200,
      headers: {'Content-Type': 'application/json'},
    );
  });
}

Widget buildTestApp() {
  final apiClient = buildMockApiClient();
  return MultiProvider(
    providers: [
      Provider<AuthRemoteDataSource>(create: (_) => MockAuthRemoteDataSource()),
      Provider<TokenStore>(create: (_) => InMemoryTokenStore()),
      Provider<AuthRepository>(
        create: (ctx) => AuthRepository(
          remoteDataSource: ctx.read<AuthRemoteDataSource>(),
          tokenStore: ctx.read<TokenStore>(),
        ),
      ),
      ChangeNotifierProvider<LoginViewModel>(
        create: (ctx) =>
            LoginViewModel(authRepository: ctx.read<AuthRepository>()),
      ),
      Provider<AttendanceRepository>(
        create: (ctx) => AttendanceRepository(
          client: apiClient,
          tokenStore: ctx.read<TokenStore>(),
        ),
      ),
      Provider<ReimbursementRepository>(
        create: (ctx) => ReimbursementRepository(
          client: apiClient,
          tokenStore: ctx.read<TokenStore>(),
        ),
      ),
      Provider<IzinRepository>(
        create: (ctx) => IzinRepository(
          client: apiClient,
          tokenStore: ctx.read<TokenStore>(),
        ),
      ),
      Provider<UserRepository>(create: (_) => UserRepository()),
      Provider<KunjunganRepository>(
        create: (ctx) => KunjunganRepository(
          client: apiClient,
          tokenStore: ctx.read<TokenStore>(),
        ),
      ),
      Provider<TimesheetRepository>(
        create: (ctx) => TimesheetRepository(
          client: apiClient,
          tokenStore: ctx.read<TokenStore>(),
        ),
      ),
      Provider<CameraService>(create: (_) => CameraService()),
      Provider<LocationService>(create: (_) => LocationService()),
      Provider<SelfieStorageService>(create: (_) => SelfieStorageService()),
      Provider<PhotoStorageService>(create: (_) => PhotoStorageService()),
      ChangeNotifierProvider<AttendanceViewModel>(
        create: (ctx) => AttendanceViewModel(
          attendanceRepository: ctx.read<AttendanceRepository>(),
          cameraService: ctx.read<CameraService>(),
          locationService: ctx.read<LocationService>(),
          selfieStorageService: ctx.read<SelfieStorageService>(),
          attendanceStore: MemoryAttendanceStore(),
        ),
      ),
      ChangeNotifierProvider<CalendarViewModel>(
        create: (ctx) => CalendarViewModel(
          attendanceRepository: ctx.read<AttendanceRepository>(),
        ),
      ),
      ChangeNotifierProvider<DashboardViewModel>(
        create: (ctx) => DashboardViewModel(
          userRepository: ctx.read<UserRepository>(),
          attendanceRepository: ctx.read<AttendanceRepository>(),
          reimbursementRepository: ctx.read<ReimbursementRepository>(),
          photoStorageService: ctx.read<PhotoStorageService>(),
          attendanceStore: MemoryAttendanceStore(),
        ),
      ),
      ChangeNotifierProvider<ReimbursementViewModel>(
        create: (ctx) => ReimbursementViewModel(
          reimbursementRepository: ctx.read<ReimbursementRepository>(),
        ),
      ),
      ChangeNotifierProvider<IzinViewModel>(
        create: (ctx) =>
            IzinViewModel(izinRepository: ctx.read<IzinRepository>()),
      ),
      ChangeNotifierProvider<KunjunganViewModel>(
        create: (ctx) => KunjunganViewModel(
          repository: ctx.read<KunjunganRepository>(),
          locationService: ctx.read<LocationService>(),
        ),
      ),
      ChangeNotifierProvider<TimesheetViewModel>(
        create: (ctx) =>
            TimesheetViewModel(repository: ctx.read<TimesheetRepository>()),
      ),
    ],
    child: const FieldSupervisorApp(),
  );
}

void main() {
  Future<void> settle(WidgetTester tester, [int pumps = 4]) async {
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> bootToLogin(WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await settle(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
  }

  Future<void> loginAsDemo(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('login_username_field')),
      MockAuthRemoteDataSource.username,
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      MockUserData.currentUser.password,
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await settle(tester);
    expect(find.byType(MainShell), findsOneWidget);
    await settle(tester, 8);
  }

  Future<void> scrollAndTap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(text));
  }

  testWidgets('app boots into login and demo login reaches KZB dashboard', (
    tester,
  ) async {
    await bootToLogin(tester);

    expect(find.text(AppStrings.loginWelcome), findsOneWidget);
    expect(find.text(AppStrings.loginUsernameField), findsOneWidget);
    expect(find.text(AppStrings.loginPasswordField), findsOneWidget);
    expect(find.text(AppStrings.brandName), findsOneWidget);

    await loginAsDemo(tester);

    expect(find.text(AppStrings.greetingSubtitle), findsOneWidget);
    expect(find.text(AppStrings.checkInCard), findsOneWidget);
    expect(find.text(AppStrings.checkOutCard), findsOneWidget);
    expect(find.text(AppStrings.startVisitCard), findsOneWidget);
    expect(find.text(AppStrings.endVisitCard), findsOneWidget);
    expect(find.text(AppStrings.reimbursementCard), findsOneWidget);
    expect(find.text(AppStrings.timesheetCard), findsOneWidget);
    expect(find.text(AppStrings.navHome), findsOneWidget);
    expect(find.text(AppStrings.navDocuments), findsOneWidget);
    expect(find.text(AppStrings.navMore), findsOneWidget);
    expect(find.byType(ClipOval), findsOneWidget);
  });

  testWidgets('login screen rejects invalid credentials', (tester) async {
    await bootToLogin(tester);

    await tester.enterText(
      find.byKey(const Key('login_username_field')),
      'wrong-user',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await settle(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AppStrings.invalidCredentials), findsOneWidget);
  });

  testWidgets(
    'navigation reaches attendance, reimbursement, calendar and izin',
    (tester) async {
      await bootToLogin(tester);
      await loginAsDemo(tester);

      await scrollAndTap(tester, AppStrings.checkInCard);
      await settle(tester);
      expect(find.text(AppStrings.serverTimeLabel), findsOneWidget);
      expect(find.text(AppStrings.selfiePrompt), findsOneWidget);
      expect(find.text(AppStrings.gpsChipLabel), findsOneWidget);

      await tester.pageBack();
      await settle(tester);

      await scrollAndTap(tester, AppStrings.reimbursementCard);
      await settle(tester, 5);
      expect(find.text(AppStrings.totalPendingAmountLabel), findsWidgets);
      expect(find.text(AppStrings.emptyClaims), findsOneWidget);
      expect(find.text('Rp 0'), findsWidgets);

      await tester.tap(find.text(AppStrings.newClaimAction));
      await settle(tester);
      expect(find.text(AppStrings.reimbActivityField), findsOneWidget);
      expect(find.text(AppStrings.reimbCategoryField), findsOneWidget);
      expect(find.text(AppStrings.submitProcessButton), findsOneWidget);

      await tester.pageBack();
      await settle(tester);
      await tester.pageBack();
      await settle(tester);

      await tester.tap(find.text(AppStrings.navDocuments));
      await settle(tester);

      await scrollAndTap(tester, AppStrings.historyActionLabel);
      await settle(tester);
      expect(find.byType(TableCalendar<AttendanceStatus>), findsOneWidget);
      expect(find.text(AppStrings.legendTitle), findsOneWidget);

      await tester.pageBack();
      await settle(tester);

      await scrollAndTap(tester, AppStrings.izinActionLabel);
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(AppStrings.izinTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.newClaimAction));
      await settle(tester);
      expect(find.text(AppStrings.izinDateField), findsOneWidget);
      expect(find.text(AppStrings.izinReasonField), findsOneWidget);
      expect(find.text(AppStrings.izinSubmitButton), findsOneWidget);

      await tester.pageBack();
      await settle(tester);
      await tester.pageBack();
      await settle(tester);
    },
  );
}
