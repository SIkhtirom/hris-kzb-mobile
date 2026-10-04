import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:field_supervisor_app/core/constants/api_constants.dart';
import 'package:field_supervisor_app/data/remote/auth_remote_data_source.dart';

void main() {
  test(
    'http login posts username to sanctum endpoint and parses token',
    () async {
      Uri? seenUri;
      Map<String, String>? seenHeaders;
      Map<String, dynamic>? seenBody;

      final client = MockClient((request) async {
        seenUri = request.url;
        seenHeaders = request.headers;
        seenBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'access_token': 'sanctum-token',
            'token_type': 'Bearer',
            'user': {
              'id': '2',
              'name': 'Andi Pratama',
              'email': 'andi@cvkazimberkah.co.id',
              'role': 'mandor',
            },
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final source = HttpAuthRemoteDataSource(
        baseUrl: ApiConstants.baseUrl,
        client: client,
      );
      final result = await source.login(
        username: 'andi',
        password: 'mandor123',
      );

      expect(seenUri.toString(), '${ApiConstants.baseUrl}/login');
      expect(seenHeaders?['Content-Type'], contains('application/json'));
      expect(seenHeaders?['Accept'], contains('application/json'));
      expect(seenBody?['username'], 'andi');
      expect(seenBody?['password'], 'mandor123');
      expect(result.accessToken, 'sanctum-token');
      expect(result.user.name, 'Andi Pratama');
      expect(result.user.role, 'mandor');
    },
  );

  test('http login throws AuthException on 401 and 422', () async {
    for (final code in [401, 422]) {
      final client = MockClient(
        (_) async => http.Response('{"message":"Unauthorized"}', code),
      );
      final source = HttpAuthRemoteDataSource(
        baseUrl: ApiConstants.baseUrl,
        client: client,
      );
      await expectLater(
        source.login(username: 'andi', password: 'salah'),
        throwsA(isA<AuthException>()),
      );
    }
  });
}
