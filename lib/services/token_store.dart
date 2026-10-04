abstract class TokenStore {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> writeTokens({required String accessToken, String? refreshToken});

  Future<DateTime?> readLastOpened();

  Future<void> writeLastOpened(DateTime openedAt);

  Future<void> clear();
}
