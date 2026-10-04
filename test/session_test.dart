import 'package:flutter_test/flutter_test.dart';

import 'package:field_supervisor_app/data/mock/mock_user_data.dart';
import 'package:field_supervisor_app/data/remote/auth_remote_data_source.dart';
import 'package:field_supervisor_app/data/repositories/auth_repository.dart';
import 'package:field_supervisor_app/services/in_memory_token_store.dart';

void main() {
  AuthRepository repositoryFor(InMemoryTokenStore store) => AuthRepository(
    remoteDataSource: MockAuthRemoteDataSource(),
    tokenStore: store,
  );

  test('fresh session stays authenticated and refreshes last opened', () async {
    final store = InMemoryTokenStore();
    final repository = repositoryFor(store);
    final now = DateTime(2026, 9, 22, 9, 0, 0);

    await store.writeTokens(accessToken: 'token', refreshToken: 'refresh');
    await store.writeLastOpened(now.subtract(const Duration(days: 1)));

    expect(await repository.validateSession(now: now), isTrue);
    expect(await repository.isAuthenticated(), isTrue);

    final refreshed = await store.readLastOpened();
    expect(refreshed, isNotNull);
    expect(
      refreshed!.difference(now).abs(),
      lessThan(const Duration(seconds: 5)),
    );
  });

  test('session at exactly three days is still accepted', () async {
    final store = InMemoryTokenStore();
    final repository = repositoryFor(store);
    final now = DateTime(2026, 9, 22, 9, 0, 0);

    await store.writeTokens(accessToken: 'token', refreshToken: 'refresh');
    await store.writeLastOpened(now.subtract(const Duration(days: 3)));

    expect(await repository.validateSession(now: now), isTrue);
    expect(await repository.isAuthenticated(), isTrue);
  });

  test('stale session older than three days is cleared to login', () async {
    final store = InMemoryTokenStore();
    final repository = repositoryFor(store);
    final now = DateTime(2026, 9, 22, 9, 0, 0);

    await store.writeTokens(accessToken: 'token', refreshToken: 'refresh');
    await store.writeLastOpened(now.subtract(const Duration(days: 4)));

    expect(await repository.validateSession(now: now), isFalse);
    expect(await repository.isAuthenticated(), isFalse);
    expect(await store.readLastOpened(), isNull);
  });

  test('token without last opened timestamp is treated as expired', () async {
    final store = InMemoryTokenStore();
    final repository = repositoryFor(store);

    await store.writeTokens(accessToken: 'token', refreshToken: 'refresh');

    expect(await repository.validateSession(), isFalse);
    expect(await repository.isAuthenticated(), isFalse);
  });

  test('login stores last opened timestamp', () async {
    final store = InMemoryTokenStore();
    final repository = repositoryFor(store);

    await repository.login(
      username: MockAuthRemoteDataSource.username,
      password: MockUserData.currentUser.password,
    );

    expect(await repository.isAuthenticated(), isTrue);
    expect(await store.readLastOpened(), isNotNull);
  });
}
