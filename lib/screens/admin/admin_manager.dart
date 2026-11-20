import 'package:flutter/material.dart';
import '../../data/admin_accounts.dart';
import '../../data/api.dart';
import '../../theme.dart';
import '../../widgets/blue_button.dart';

class _Field {
  final String key;
  final String label;
  final bool secret;
  final String initial;
  final TextInputType? keyboard;
  const _Field(this.key, this.label,
      {this.secret = false, this.initial = '', this.keyboard});
}

/// A small form dialog. [onSubmit] returns an error message, or null when it worked.
/// Returns true when the form was submitted successfully.
Future<bool> _formDialog(
  BuildContext context, {
  required String title,
  String? intro,
  required List<_Field> fields,
  required String submitLabel,
  required Future<String?> Function(Map<String, String> values) onSubmit,
}) async {
  final ctls = {
    for (final f in fields) f.key: TextEditingController(text: f.initial)
  };
  String? error;
  bool saving = false;
  bool ok = false;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (intro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(intro,
                        style: const TextStyle(color: C.muted, fontSize: 13)),
                  ),
                for (final f in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: ctls[f.key],
                      obscureText: f.secret,
                      keyboardType: f.keyboard,
                      decoration: InputDecoration(labelText: f.label),
                    ),
                  ),
                if (error != null)
                  Text(error!, style: TextStyle(color: Colors.red.shade700)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setS(() {
                      saving = true;
                      error = null;
                    });
                    final err = await onSubmit(
                        {for (final e in ctls.entries) e.key: e.value.text});
                    if (err != null) {
                      setS(() {
                        saving = false;
                        error = err;
                      });
                      return;
                    }
                    ok = true;
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
            child: Text(saving ? 'Please wait...' : submitLabel),
          ),
        ],
      ),
    ),
  );
  for (final c in ctls.values) {
    c.dispose();
  }
  return ok;
}

Future<String?> _try(Future<void> Function() call) async {
  try {
    await call();
    return null;
  } on ApiException catch (e) {
    return e.message;
  }
}

/// Your account (password, and for the super admin the username and two-step
/// verification) and, for the super admin, the list of administrators.
class AdminManagerPage extends StatefulWidget {
  const AdminManagerPage({super.key});

  @override
  State<AdminManagerPage> createState() => _AdminManagerPageState();
}

class _AdminManagerPageState extends State<AdminManagerPage> {
  AccountInfo? me;
  List<AdminInfo> admins = [];
  String? loadError;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final account = await AdminApi.account();
      Api.displayName = account.username;
      final list = account.isSuper ? await AdminApi.list() : <AdminInfo>[];
      if (!mounted) return;
      setState(() {
        me = account;
        admins = list;
        loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        loadError = e.message;
        loading = false;
      });
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------------- my account ----------------

  Future<void> _editAccount() async {
    final account = me!;
    final ok = await _formDialog(
      context,
      title: 'Change username or password',
      intro: account.isSuper
          ? 'Leave a field as it is to keep it.'
          : 'Enter a new password. Only the super admin can change the username.',
      fields: [
        if (account.isSuper)
          _Field('username', 'Username', initial: account.username),
        const _Field('newPassword', 'New password (at least 8 characters)',
            secret: true),
        const _Field('confirm', 'Repeat the new password', secret: true),
        const _Field('current', 'Current password', secret: true),
      ],
      submitLabel: 'Save',
      onSubmit: (v) async {
        final newPass = v['newPassword'] ?? '';
        if (newPass != (v['confirm'] ?? ''))
          return 'The new passwords do not match.';
        final name = (v['username'] ?? account.username).trim();
        return _try(() async {
          await AdminApi.update(
            currentPassword: v['current'] ?? '',
            newUsername: name == account.username ? null : name,
            newPassword: newPass.isEmpty ? null : newPass,
          );
        });
      },
    );
    if (ok) {
      _toast('Account updated.');
      _load();
    }
  }

  Future<void> _setUpEmail() async {
    var sent = false;
    final started = await _formDialog(
      context,
      title: 'Turn on two-step verification',
      intro: 'We email a 6-digit code to this address every time you sign in. '
          'First we send a code to confirm the address.',
      fields: const [
        _Field('email', 'Email address', keyboard: TextInputType.emailAddress),
        _Field('current', 'Current password', secret: true),
      ],
      submitLabel: 'Send code',
      onSubmit: (v) => _try(() async {
        await AdminApi.startEmail(v['email'] ?? '', v['current'] ?? '');
        sent = true;
      }),
    );
    if (!started || !sent || !mounted) return;
    final confirmed = await _formDialog(
      context,
      title: 'Enter the code',
      intro: 'Check your inbox. The code expires in 10 minutes.',
      fields: const [
        _Field('code', '6-digit code', keyboard: TextInputType.number),
      ],
      submitLabel: 'Confirm',
      onSubmit: (v) => _try(() async => AdminApi.confirmEmail(v['code'] ?? '')),
    );
    if (confirmed) {
      _toast('Two-step verification is on.');
      _load();
    }
  }

  Future<void> _disableEmail() async {
    final ok = await _formDialog(
      context,
      title: 'Turn off two-step verification?',
      intro: 'Signing in will only need your password.',
      fields: const [_Field('current', 'Current password', secret: true)],
      submitLabel: 'Turn off',
      onSubmit: (v) =>
          _try(() async => AdminApi.disableEmail(v['current'] ?? '')),
    );
    if (ok) {
      _toast('Two-step verification is off.');
      _load();
    }
  }

  // ---------------- administrators ----------------

  Future<void> _addAdmin() async {
    final ok = await _formDialog(
      context,
      title: 'Add administrator',
      intro: 'They sign in with this username and password. They can manage '
          'seasons, students and candidates, but not other administrators.',
      fields: const [
        _Field('username', 'Username'),
        _Field('password', 'Password (at least 8 characters)', secret: true),
      ],
      submitLabel: 'Add admin',
      onSubmit: (v) =>
          _try(() => AdminApi.create(v['username'] ?? '', v['password'] ?? '')),
    );
    if (ok) {
      _toast('Administrator added.');
      _load();
    }
  }

  Future<void> _resetPassword(AdminInfo a) async {
    final ok = await _formDialog(
      context,
      title: 'New password for ${a.username}',
      fields: const [
        _Field('password', 'New password (at least 8 characters)',
            secret: true),
      ],
      submitLabel: 'Set password',
      onSubmit: (v) =>
          _try(() => AdminApi.resetPassword(a.id, v['password'] ?? '')),
    );
    if (ok) _toast('Password changed for ${a.username}.');
  }

  Future<void> _remove(AdminInfo a) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${a.username}?'),
        content: const Text(
            'They will no longer be able to sign in once their current session ends.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    final err = await _try(() => AdminApi.remove(a.id));
    _toast(err ?? '${a.username} was removed.');
    if (err == null) _load();
  }

  // ---------------- build ----------------

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
      );

  Widget _accountCard(AccountInfo a) => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: C.navy,
                  child: Text(a.username.characters.first.toUpperCase(),
                      style: const TextStyle(
                          color: C.yellow,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.username,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      a.isSuper
                          ? _chip('Super admin', const Color(0xFFFFF3C4),
                              const Color(0xFF8A6500))
                          : _chip('Admin', const Color(0xFFE3ECF8), C.blue),
                    ],
                  ),
                ),
              ],
            ),
            if (a.isSuper) ...[
              const Divider(height: 28),
              Row(
                children: [
                  Icon(
                      a.twoFactor ? Icons.verified_user : Icons.shield_outlined,
                      color: a.twoFactor ? C.ok : C.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            a.twoFactor
                                ? 'Two-step verification is on'
                                : 'Two-step verification is off',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                            a.twoFactor
                                ? 'Codes are sent to ${a.email}'
                                : 'Add an email to get a code every time you sign in.',
                            style:
                                const TextStyle(color: C.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: a.twoFactor ? _disableEmail : _setUpEmail,
                    child: Text(a.twoFactor ? 'Turn off' : 'Set up'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            BlueButton(
              label:
                  a.isSuper ? 'Change username or password' : 'Change password',
              icon: Icons.manage_accounts_outlined,
              outlined: true,
              onPressed: _editAccount,
            ),
          ],
        ),
      );

  Widget _adminTile(AdminInfo a) {
    final self = a.id == me?.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: cardBox(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE3ECF8),
            child: Text(a.username.characters.first.toUpperCase(),
                style: const TextStyle(
                    color: C.blue, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(self ? '${a.username} (you)' : a.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                    a.isSuper
                        ? 'Super admin${a.twoFactor ? ', two-step on' : ''}'
                        : 'Admin',
                    style: const TextStyle(color: C.muted, fontSize: 13)),
              ],
            ),
          ),
          if (!a.isSuper) ...[
            IconButton(
              tooltip: 'Set a new password',
              icon: const Icon(Icons.key_outlined),
              onPressed: () => _resetPassword(a),
            ),
            IconButton(
              tooltip: 'Remove administrator',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _remove(a),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading && me == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final account = me;
    if (account == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loadError ?? 'Could not load your account.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        _accountCard(account),
        if (account.isSuper) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text('Administrators',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: C.blue),
                onPressed: _addAdmin,
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Add admin'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final a in admins) _adminTile(a),
        ],
      ],
    );
  }
}
