import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int status; // 0 = could not reach the server
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

class Api {
  // Only used when testing on a real phone over Wi-Fi.
  static const _lanHost = 'YOUR-PC-IP';
  static const _useLan = false;

  static String get baseUrl {
    if (_useLan) return 'http://$_lanHost:5080';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5080'; // Android emulator
    }
    return 'http://localhost:5080'; // Chrome, Windows
  }

  static String? token;
  static String? role;

  /// serverTime minus phone time. Add it to DateTime.now() for a correct clock.
  static Duration clockOffset = Duration.zero;
  static DateTime get now => DateTime.now().add(clockOffset);

  static Future<dynamic> _send(String method, String path,
      {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final payload = body == null ? null : jsonEncode(body);

    late http.Response res;
    try {
      final req = switch (method) {
        'GET' => http.get(uri, headers: headers),
        'POST' => http.post(uri, headers: headers, body: payload),
        'PUT' => http.put(uri, headers: headers, body: payload),
        'DELETE' => http.delete(uri, headers: headers),
        _ => throw ArgumentError(method),
      };
      res = await req.timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ApiException(
          0, 'Cannot reach the server. Check your connection and try again.');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    var message = 'Something went wrong (${res.statusCode}).';
    try {
      final j = jsonDecode(res.body);
      message = (j['detail'] ?? j['title'] ?? message).toString();
    } catch (_) {}
    if (res.statusCode == 401 && token != null)
      message = 'Your session expired. Please sign in again.';
    throw ApiException(res.statusCode, message);
  }

  static Future<dynamic> get(String path) => _send('GET', path);
  static Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);
  static Future<dynamic> put(String path, Object body) =>
      _send('PUT', path, body: body);
  static Future<dynamic> delete(String path) => _send('DELETE', path);

  static String? absUrl(String? rel) {
    if (rel == null || rel.isEmpty) return null;
    return rel.startsWith('http') ? rel : '$baseUrl$rel';
  }

  static void syncFrom(String serverTime) {
    clockOffset =
        parseUtc(serverTime).toUtc().difference(DateTime.now().toUtc());
  }

  static Future<void> syncClock() async {
    final j = await get('/api/time');
    syncFrom(j['serverTime'] as String);
  }

  static Future<String> login(
      {required bool admin, required String user, required String pass}) async {
    final j = await post(
      admin ? '/api/auth/admin/login' : '/api/auth/student/login',
      admin
          ? {'username': user.trim(), 'password': pass}
          : {'studentNum': user.trim(), 'password': pass},
    );
    token = j['token'] as String;
    role = j['role'] as String;
    return j['displayName'] as String;
  }

  static void logout() {
    token = null;
    role = null;
  }
}

DateTime parseUtc(String s) {
  final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(s);
  return DateTime.parse(hasZone ? s : '${s}Z').toLocal();
}
