import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/api.dart';
import '../../theme.dart';

/// Password calls for /api/admin/students.
class StudentPasswords {
  /// Adds a student with a generated password. Returns the new id and the password.
  static Future<({int id, String password})> create({
    required String studentNum,
    required String fullName,
    required int gradeLevelId,
    int? programId,
  }) async {
    final j = await Api.post('/api/admin/students', {
      'studentNum': studentNum.trim(),
      'fullName': fullName.trim(),
      'gradeLevelId': gradeLevelId,
      'password': '', // empty = generate on the server
      'programId': programId,
    });
    return (
      id: j['student']['id'] as int,
      password: j['password'] as String,
    );
  }

  static Future<String> reveal(int id) async =>
      (await Api.get('/api/admin/students/$id/password'))['password'] as String;

  static Future<String> reset(int id) async =>
      (await Api.post('/api/admin/students/$id/password/reset'))['password']
          as String;
}

/// Shows a student's password. Pass [known] right after creating a student to skip the lookup.
Future<void> showStudentPassword(
  BuildContext context, {
  required int id,
  required String name,
  required String studentNum,
  String? known,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _PasswordDialog(
          id: id, name: name, studentNum: studentNum, known: known),
    );

class _PasswordDialog extends StatefulWidget {
  final int id;
  final String name;
  final String studentNum;
  final String? known;
  const _PasswordDialog(
      {required this.id,
      required this.name,
      required this.studentNum,
      this.known});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  String? password;
  String? message;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    password = widget.known;
    if (password == null) _run(() => StudentPasswords.reveal(widget.id));
  }

  Future<void> _run(Future<String> Function() call) async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final p = await call();
      if (!mounted) return;
      setState(() {
        password = p;
        loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        message = e.message;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.name),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student number ${widget.studentNum}',
                style: const TextStyle(color: C.muted)),
            const SizedBox(height: 14),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (password != null)
              Row(
                children: [
                  Expanded(
                    child: SelectableText(password!,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontFamily: 'monospace')),
                  ),
                  IconButton(
                    tooltip: 'Copy password',
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: password!));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password copied.')));
                    },
                  ),
                ],
              ),
            if (message != null)
              Text(message!, style: TextStyle(color: Colors.red.shade700)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading
              ? null
              : () => _run(() => StudentPasswords.reset(widget.id)),
          child: const Text('Reset password'),
        ),
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    );
  }
}
