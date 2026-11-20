import 'api.dart';

class AccountInfo {
  final int id;
  final String username;
  final bool isSuper;
  final String? email;
  final String? pendingEmail;
  const AccountInfo(
      this.id, this.username, this.isSuper, this.email, this.pendingEmail);

  bool get twoFactor => email != null;

  factory AccountInfo.fromJson(dynamic j) => AccountInfo(
      j['id'], j['username'], j['isSuper'], j['email'], j['pendingEmail']);
}

class AdminInfo {
  final int id;
  final String username;
  final bool isSuper;
  final bool twoFactor;
  const AdminInfo(this.id, this.username, this.isSuper, this.twoFactor);
}

class AdminApi {
  static Future<AccountInfo> account() async =>
      AccountInfo.fromJson(await Api.get('/api/admin/account'));

  static Future<AccountInfo> update({
    required String currentPassword,
    String? newUsername,
    String? newPassword,
  }) async =>
      AccountInfo.fromJson(await Api.put('/api/admin/account', {
        'currentPassword': currentPassword,
        'newUsername': newUsername,
        'newPassword': newPassword,
      }));

  static Future<void> startEmail(String email, String currentPassword) async {
    await Api.post('/api/admin/account/email/start',
        {'email': email.trim(), 'currentPassword': currentPassword});
  }

  static Future<AccountInfo> confirmEmail(String code) async =>
      AccountInfo.fromJson(await Api.post(
          '/api/admin/account/email/confirm', {'code': code.trim()}));

  static Future<AccountInfo> disableEmail(String currentPassword) async =>
      AccountInfo.fromJson(await Api.post('/api/admin/account/email/disable',
          {'currentPassword': currentPassword}));

  static Future<List<AdminInfo>> list() async => [
        for (final a in await Api.get('/api/admin/admins') as List)
          AdminInfo(
              a['id'], a['username'], a['isSuper'], a['twoFactorEnabled']),
      ];

  static Future<void> create(String username, String password) async {
    await Api.post('/api/admin/admins',
        {'username': username.trim(), 'password': password});
  }

  static Future<void> resetPassword(int id, String newPassword) async {
    await Api.post(
        '/api/admin/admins/$id/password', {'newPassword': newPassword});
  }

  static Future<void> remove(int id) async {
    await Api.delete('/api/admin/admins/$id');
  }
}
