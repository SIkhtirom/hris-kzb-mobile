import 'token_store.dart';

class InMemoryTokenStore implements TokenStore {
  String? _accessToken;
  String? _refreshToken;
  DateTime? _lastOpened;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> writeTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<DateTime?> readLastOpened() async => _lastOpened;

  @override
  Future<void> writeLastOpened(DateTime openedAt) async {
    _lastOpened = openedAt;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _lastOpened = null;
  }
}
