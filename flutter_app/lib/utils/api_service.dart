// lib/utils/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiException implements Exception {
  final String message;
  final int?   statusCode;
  ApiException(this.message, [this.statusCode]);
  @override String toString() => message;
}

class ApiService {
  // Change to your machine's LAN IP when running on a physical device.
  // Android emulator: 10.0.2.2  |  iOS simulator: 127.0.0.1
  static const _base = 'http://localhost:8000/api';

  static final _client = http.Client();

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  // ── Helpers ──────────────────────────────────────────────────────────────

  static dynamic _decode(http.Response res, {bool allowEmpty = false}) {
    if (allowEmpty && (res.statusCode == 204 || res.body.isEmpty)) return null;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    String msg = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        // DRF error shapes: {"detail": "..."} or {"field": ["msg"]}
        msg = body['detail']?.toString() ??
              body.values.first?.toString() ??
              msg;
      }
    } catch (_) {}
    throw ApiException(msg, res.statusCode);
  }

  // ── Tasks CRUD ───────────────────────────────────────────────────────────

  static Future<List<Task>> listTasks({String? search, String? status}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final uri = Uri.parse('$_base/tasks/').replace(queryParameters: params);
    final res = await _client.get(uri, headers: _headers);
    final data = _decode(res) as List<dynamic>;
    return data.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Task> createTask(Map<String, dynamic> body) async {
    final res = await _client.post(
      Uri.parse('$_base/tasks/'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return Task.fromJson(_decode(res) as Map<String, dynamic>);
  }

  static Future<Task> updateTask(String id, Map<String, dynamic> body) async {
    final res = await _client.patch(
      Uri.parse('$_base/tasks/$id/'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return Task.fromJson(_decode(res) as Map<String, dynamic>);
  }

  static Future<void> deleteTask(String id) async {
    final res = await _client.delete(
      Uri.parse('$_base/tasks/$id/'),
      headers: _headers,
    );
    _decode(res, allowEmpty: true);
  }

  static Future<void> reorderTasks(List<String> orderedIds) async {
    final res = await _client.post(
      Uri.parse('$_base/tasks/reorder/'),
      headers: _headers,
      body: jsonEncode({'ordered_ids': orderedIds}),
    );
    _decode(res, allowEmpty: true);
  }
}
