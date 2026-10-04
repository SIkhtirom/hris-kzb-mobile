import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../services/request_guard.dart';
import '../../services/secure_token_store.dart';
import '../../services/token_store.dart';
import '../mock/mock_attendance_data.dart';
import '../models/attendance_record.dart';
import '../remote/auth_remote_data_source.dart';

class AttendanceRepository {
  static const Duration _latency = Duration(milliseconds: 500);

  final http.Client _client;
  final TokenStore _tokenStore;

  AttendanceRepository({http.Client? client, TokenStore? tokenStore})
    : _client = client ?? http.Client(),
      _tokenStore = tokenStore ?? SecureTokenStore();

  Future<List<AttendanceRecord>> fetchByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    await Future<void>.delayed(_latency);
    final records = MockAttendanceData.records;
    return records
        .where((r) => !r.timestamp.isBefore(start) && !r.timestamp.isAfter(end))
        .toList();
  }

  Future<void> add(AttendanceRecord record) async {
    await Future<void>.delayed(_latency);
    MockAttendanceData.add(record);
  }

  Future<List<AttendanceRecord>> fetchHistory({
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final query = <String, String>{};
      if (start != null) {
        query['start_date'] = _dateKey(start);
      }
      if (end != null) {
        query['end_date'] = _dateKey(end);
      }
      final uri = Uri.parse(ApiConstants.attendances)
          .replace(queryParameters: query.isEmpty ? null : query);
      final json = await _getJson(uri);
      final items = json['data'] as List<dynamic>;
      return items
          .map(
            (item) => AttendanceRecord.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      debugPrint('fetchHistory failed: $error');
      rethrow;
    }
  }

  Future<AttendanceRecord> submitAttendance({
    required ClockEventType eventType,
    double? latitude,
    double? longitude,
    String? address,
    String? photoPath,
    DateTime? timestamp,
  }) async {
    final fields = <String, String>{
      'type': eventType == ClockEventType.checkIn ? 'check_in' : 'check_out',
    };
    if (latitude != null) {
      fields['latitude'] = '$latitude';
    }
    if (longitude != null) {
      fields['longitude'] = '$longitude';
    }
    if (address != null) {
      fields['address'] = address;
    }
    if (timestamp != null) {
      fields['timestamp'] = timestamp.toIso8601String();
    }
    final data = await _postMultipart(
      ApiConstants.attendances,
      fields,
      files: photoPath == null ? null : {'photo': photoPath},
    );
    return AttendanceRecord.fromJson(data);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenStore.readAccessToken();
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await RequestGuard.withTimeout(
      _client.get(uri, headers: await _authHeaders()),
    );
    if (response.statusCode == 422) {
      throw ApiException.fromResponse(response.body);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForStatus(response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _postMultipart(
    String url,
    Map<String, String> fields, {
    Map<String, String>? files,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(await _authHeaders());
    request.fields.addAll(fields);
    if (files != null) {
      for (final entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value),
        );
      }
    }
    final streamed = await RequestGuard.withTimeout(_client.send(request));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 422) {
      throw ApiException.fromResponse(response.body);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForStatus(response.statusCode);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['data'] as Map<String, dynamic>;
  }

  Never _throwForStatus(int status) {
    if (status == 401 || status == 403) {
      throw const AuthException('Invalid credentials');
    }
    throw Exception('Request failed ($status)');
  }
}
