import 'dart:async';

import '../core/constants/app_strings.dart';
import '../data/remote/auth_remote_data_source.dart';
import '../data/repositories/auth_repository.dart';
import '../services/request_guard.dart';
import 'base_viewmodel.dart';

class LoginViewModel extends BaseViewModel {
  final AuthRepository _authRepository;

  LoginViewModel({required this._authRepository});

  void clearError() {
    setError(null);
  }

  Future<bool> submit({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty) {
      setError(AppStrings.invalidUsername);
      return false;
    }
    if (password.isEmpty) {
      setError(AppStrings.invalidPassword);
      return false;
    }
    setLoading(true);
    setError(null);
    try {
      await RequestGuard.withTimeout(
        _authRepository.login(username: username.trim(), password: password),
      );
      return true;
    } on AuthException {
      setError(AppStrings.invalidCredentials);
      return false;
    } on TimeoutException {
      setError(AppStrings.poorConnectionMessage);
      return false;
    } catch (_) {
      setError(AppStrings.loginFailedMessage);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
