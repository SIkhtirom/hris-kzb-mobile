import 'dart:async';

import '../core/constants/app_strings.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';
import '../services/photo_storage_service.dart';
import '../services/request_guard.dart';
import 'base_viewmodel.dart';

class SettingsViewModel extends BaseViewModel {
  final UserRepository _userRepository;
  final PhotoStorageService _photoStorageService;

  SettingsViewModel({
    required this._userRepository,
    required this._photoStorageService,
  });

  User? _user;
  String? _profilePicturePath;
  bool _isSaving = false;

  User? get user => _user;
  String? get profilePicturePath => _profilePicturePath;
  bool get isSaving => _isSaving;

  Future<void> load() async {
    setError(null);
    try {
      _user = await RequestGuard.withTimeout(
        _userRepository.fetchCurrentUser(),
      );
      _profilePicturePath = _user?.profilePicturePath;
      notifyListeners();
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
    } catch (_) {
      setError(AppStrings.settingsLoadError);
    }
  }

  void setProfilePicture(String path) {
    _profilePicturePath = path;
    notifyListeners();
  }

  Future<void> stageProfilePicture(String pickedPath) async {
    final permanentPath = await _photoStorageService.copyPhoto(
      sourcePath: pickedPath,
      folder: 'profile',
    );
    if (permanentPath == null) {
      setError(AppStrings.profilePictureSaveError);
      return;
    }
    _profilePicturePath = permanentPath;
    notifyListeners();
  }

  bool _verifyCurrentPassword(String currentPassword) {
    final user = _user;
    return user != null && currentPassword == user.password;
  }

  Future<bool> save({
    required String name,
    required DateTime? dateOfBirth,
    required String currentPassword,
  }) async {
    final user = _user;
    if (user == null || _isSaving) {
      return false;
    }
    if (!_verifyCurrentPassword(currentPassword)) {
      setError(AppStrings.invalidCurrentPassword);
      return false;
    }
    _isSaving = true;
    setError(null);
    notifyListeners();
    try {
      await RequestGuard.withTimeout(
        _userRepository.updateUser(
          user.copyWith(
            name: name.trim(),
            dateOfBirth: dateOfBirth,
            profilePicturePath: _profilePicturePath,
          ),
        ),
      );
      _user = await RequestGuard.withTimeout(
        _userRepository.fetchCurrentUser(),
      );
      return true;
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      return false;
    } catch (_) {
      setError(AppStrings.settingsSaveError);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _user;
    if (user == null || _isSaving) {
      return false;
    }
    if (!_verifyCurrentPassword(currentPassword)) {
      setError(AppStrings.invalidCurrentPassword);
      return false;
    }
    if (newPassword.length < 6) {
      setError(AppStrings.invalidPasswordLength);
      return false;
    }
    _isSaving = true;
    setError(null);
    notifyListeners();
    try {
      await _userRepository.updateUser(user.copyWith(password: newPassword));
      _user = await RequestGuard.withTimeout(
        _userRepository.fetchCurrentUser(),
      );
      return true;
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      return false;
    } catch (_) {
      setError(AppStrings.settingsSaveError);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
