import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../services/request_guard.dart';
import '../../services/secure_token_store.dart';
import '../../services/token_store.dart';
import '../models/kunjungan_record.dart';
import '../remote/auth_remote_data_source.dart';

class KunjunganRepository {
  static const Duration _latency = Duration(milliseconds: 500);

  final http.Client _client;
  final TokenStore _tokenStore;
  final List<KunjunganRecord> _records = <KunjunganRecord>[];

  KunjunganRepository({http.Client? client, TokenStore? tokenStore})
    : _client = client ?? http.Client(),
      _tokenStore = tokenStore ?? SecureTokenStore();

  Future<List<KunjunganRecord>> fetchAll() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_records.reversed);
  }

  Future<void> add(KunjunganRecord record) async {
    await Future<void>.delayed(_latency);
    _records.add(record);
  }

  Future<List<KunjunganRecord>> fetchVisits() async {
    final json = await _getJson(Uri.parse(ApiConstants.visits));
    final items = json['data'] as List<dynamic>;
    return items
        .map((item) => KunjunganRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<KunjunganRecord> startVisit({
    required String timeLabel,
    required String clientName,
    required String notes,
    double? latitude,
    double? longitude,
    String? address,
    String? evidencePath,
  }) async {
    final fields = <String, String>{
      'time_label': timeLabel,
      'client_name': clientName,
      'notes': notes,
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
    final data = await _postMultipart(
      ApiConstants.visits,
      fields,
      files: evidencePath == null ? null : {'evidence': evidencePath},
    );
    return KunjunganRecord.fromJson(data);
  }

  Future<KunjunganRecord> finishVisit({
    required String id,
    String? timeLabel,
    String? notes,
    double? latitude,
    double? longitude,
    String? address,
    String? evidencePath,
  }) async {
    final fields = <String, String>{};
    if (timeLabel != null) {
      fields['time_label'] = timeLabel;
    }
    if (notes != null) {
      fields['notes'] = notes;
    }
    if (latitude != null) {
      fields['latitude'] = '$latitude';
    }
    if (longitude != null) {
      fields['longitude'] = '$longitude';
    }
    if (address != null) {
      fields['address'] = address;
    }
    final data = await _postMultipart(
      '${ApiConstants.visits}/$id',
      fields,
      files: evidencePath == null ? null : {'evidence': evidencePath},
    );
    return KunjunganRecord.fromJson(data);
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
