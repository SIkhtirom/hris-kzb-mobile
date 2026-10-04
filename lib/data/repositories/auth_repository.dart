import '../../services/token_store.dart';
import '../models/auth_result.dart';
import '../remote/auth_remote_data_source.dart';

class AuthRepository {
  static const Duration sessionMaxAge = Duration(days: 3);

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStore _tokenStore;

  AuthRepository({required this._remoteDataSource, required this._tokenStore});

  Future<bool> isAuthenticated() async {
    final token = await _tokenStore.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> validateSession({DateTime? now}) async {
    final current = now ?? DateTime.now();
    if (!await isAuthenticated()) {
      return false;
    }
    final lastOpened = await _tokenStore.readLastOpened();
    if (lastOpened == null || current.difference(lastOpened) > sessionMaxAge) {
      await _tokenStore.clear();
      return false;
    }
    await _tokenStore.writeLastOpened(current);
    return true;
  }

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final result = await _remoteDataSource.login(
      username: username,
      password: password,
    );
    await _tokenStore.writeTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await _tokenStore.writeLastOpened(DateTime.now());
    return result;
  }

  Future<void> logout() => _tokenStore.clear();
}
