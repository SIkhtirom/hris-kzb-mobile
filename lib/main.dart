import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/remote/auth_remote_data_source.dart';
import 'data/repositories/attendance_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/izin_repository.dart';
import 'data/repositories/kunjungan_repository.dart';
import 'data/repositories/reimbursement_repository.dart';
import 'data/repositories/timesheet_repository.dart';
import 'data/repositories/user_repository.dart';
import 'services/attendance_local_store.dart';
import 'services/camera_service.dart';
import 'services/location_service.dart';
import 'services/photo_storage_service.dart';
import 'services/secure_token_store.dart';
import 'services/selfie_storage_service.dart';
import 'services/token_store.dart';
import 'viewmodels/attendance_viewmodel.dart';
import 'viewmodels/calendar_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/izin_viewmodel.dart';
import 'viewmodels/kunjungan_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/reimbursement_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/timesheet_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRemoteDataSource>(
          create: (_) =>
              HttpAuthRemoteDataSource(baseUrl: AppConfig.apiBaseUrl),
        ),
        Provider<TokenStore>(create: (_) => SecureTokenStore()),
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
        Provider<AttendanceRepository>(create: (_) => AttendanceRepository()),
        Provider<ReimbursementRepository>(
          create: (_) => ReimbursementRepository(),
        ),
        Provider<IzinRepository>(create: (_) => IzinRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<KunjunganRepository>(create: (_) => KunjunganRepository()),
        Provider<TimesheetRepository>(create: (_) => TimesheetRepository()),
        Provider<CameraService>(create: (_) => CameraService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<SelfieStorageService>(create: (_) => SelfieStorageService()),
        Provider<PhotoStorageService>(create: (_) => PhotoStorageService()),
        Provider<AttendanceLocalStore>(create: (_) => AttendanceLocalStore()),
        ChangeNotifierProvider<AttendanceViewModel>(
          create: (ctx) => AttendanceViewModel(
            attendanceRepository: ctx.read<AttendanceRepository>(),
            cameraService: ctx.read<CameraService>(),
            locationService: ctx.read<LocationService>(),
            selfieStorageService: ctx.read<SelfieStorageService>(),
            attendanceStore: ctx.read<AttendanceLocalStore>(),
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
            attendanceStore: ctx.read<AttendanceLocalStore>(),
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
        ChangeNotifierProvider<SettingsViewModel>(
          create: (ctx) => SettingsViewModel(
            userRepository: ctx.read<UserRepository>(),
            photoStorageService: ctx.read<PhotoStorageService>(),
          ),
        ),
      ],
      child: const FieldSupervisorApp(),
    ),
  );
}
