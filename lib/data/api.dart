import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

class TwoFactorRequired implements Exception {
  final String challenge;
  final String emailHint;
  TwoFactorRequired(this.challenge, this.emailHint);
}

class Api {
  static const _lanHost = 'YOUR-PC-IP';
  static const _useLan = false;

  static String get baseUrl {
    if (_useLan) return 'http://$_lanHost:5080';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5080';
    }
    return 'http://localhost:5080';
  }

  static String? token;
  static String? role;

  static String? displayName;

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
      final errors = j['errors'];
      if (j['detail'] == null && errors is Map && errors.isNotEmpty) {
        message = [
          for (final v in errors.values)
            if (v is List) ...v.map((e) => e.toString()) else v.toString()
        ].join(' ');
      }
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

  static String _finishLogin(dynamic j) {
    token = j['token'] as String;
    role = j['role'] as String;
    displayName = j['displayName'] as String;
    return displayName!;
  }

  static Future<String> login(
      {required bool admin, required String user, required String pass}) async {
    final j = await post(
      admin ? '/api/auth/admin/login' : '/api/auth/student/login',
      admin
          ? {'username': user.trim(), 'password': pass}
          : {'studentNum': user.trim(), 'password': pass},
    );
    if (j['twoFactorRequired'] == true) {
      throw TwoFactorRequired(
          j['challenge'] as String, (j['emailHint'] ?? '') as String);
    }
    return _finishLogin(j);
  }

  static Future<String> verifyAdmin(String challenge, String code) async =>
      _finishLogin(await post('/api/auth/admin/verify',
          {'challenge': challenge, 'code': code.trim()}));

  static Future<void> resendAdminCode(String challenge) async {
    await post('/api/auth/admin/resend', {'challenge': challenge});
  }

  static void logout() {
    token = null;
    role = null;
    displayName = null;
  }
}

DateTime parseUtc(String s) {
  final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(s);
  return DateTime.parse(hasZone ? s : '${s}Z').toLocal();
}
