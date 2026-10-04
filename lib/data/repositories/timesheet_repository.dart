import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../services/request_guard.dart';
import '../../services/secure_token_store.dart';
import '../../services/token_store.dart';
import '../models/timesheet_task.dart';
import '../remote/auth_remote_data_source.dart';

class TimesheetRepository {
  static const Duration _latency = Duration(milliseconds: 500);

  final http.Client _client;
  final TokenStore _tokenStore;
  final List<TimesheetTask> _tasks = <TimesheetTask>[];

  TimesheetRepository({http.Client? client, TokenStore? tokenStore})
    : _client = client ?? http.Client(),
      _tokenStore = tokenStore ?? SecureTokenStore();

  Future<List<TimesheetTask>> fetchForDate(DateTime date) async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(
      _tasks.where((task) => _isSameDate(task.assignedDate, date)),
    );
  }

  Future<void> add(TimesheetTask task) async {
    await Future<void>.delayed(_latency);
    _tasks.add(task);
  }

  Future<void> update(TimesheetTask task) async {
    await Future<void>.delayed(_latency);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  Future<void> completeTask(
    String taskId,
    String proofPath,
    DateTime completedAt,
  ) async {
    await Future<void>.delayed(_latency);
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].markCompleted(proofPath, completedAt);
    }
  }

  Future<List<TimesheetTask>> fetchTasks(DateTime date) async {
    final day = _dateKey(date);
    final uri = Uri.parse('${ApiConstants.timesheets}?date=$day');
    final json = await _getJson(uri);
    final items = json['data'] as List<dynamic>;
    return items
        .map((item) => TimesheetTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TimesheetTask> completeTaskRemote({
    required String taskId,
    required String proofPath,
  }) async {
    final data = await _postMultipart(
      '${ApiConstants.timesheets}/$taskId',
      {'status': 'completed'},
      files: {'proof': proofPath},
    );
    return TimesheetTask.fromJson(data);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
