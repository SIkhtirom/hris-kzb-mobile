import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/request_guard.dart';
import '../mock/mock_user_data.dart';
import '../models/auth_result.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;

  static ApiException fromResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final message = json['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return ApiException(message);
      }
    } catch (_) {}
    return const ApiException(
      'Gagal menyimpan data: File terlalu besar atau format salah',
    );
  }
}

abstract class AuthRemoteDataSource {
  Future<AuthResult> login({
    required String username,
    required String password,
  });
}

class HttpAuthRemoteDataSource implements AuthRemoteDataSource {
  final http.Client _client;
  final String baseUrl;

  HttpAuthRemoteDataSource({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login');
    final response = await RequestGuard.withTimeout(
      _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'username': username, 'password': password}),
      ),
    );
    if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 422) {
      throw const AuthException('Invalid credentials');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException('Server error (${response.statusCode})');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthResult.fromJson(json);
  }
}

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  static const String username = 'andi';
  static const String email = 'andi@cvkazimberkah.co.id';
  static const Duration _latency = Duration(milliseconds: 500);

  @override
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    final user = MockUserData.currentUser;
    final validUser =
        username.compareTo(MockAuthRemoteDataSource.username) == 0 ||
        username.toLowerCase().compareTo(MockAuthRemoteDataSource.email) == 0;
    if (!validUser || password != user.password) {
      throw const AuthException('Invalid credentials');
    }
    return AuthResult(
      accessToken: 'demo-access-token',
      refreshToken: 'demo-refresh-token',
      user: user,
    );
  }
}
