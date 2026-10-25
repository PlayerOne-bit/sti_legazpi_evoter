import 'package:flutter/material.dart';
import 'admin/admin_shell.dart';
import 'client/home.dart';
import '../data/mock.dart';
import '../theme.dart';
import '../widgets/blue_button.dart';
import '../data/api.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool admin = false;
  bool hide = true;
  bool busy = false;
  String? error;
  final _user = TextEditingController();
  final _pass = TextEditingController();

  Future<void> _submit() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await Api.syncClock();
      await Api.login(admin: admin, user: _user.text, pass: _pass.text);
      if (!mounted) return;
      state.isAdmin = admin;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => admin ? const AdminShell() : const ClientHome(),
      ));
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          busy = false;
          error = e.message;
        });
    }
  }

  Widget _brand({bool large = false}) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 44, height: 5, color: C.yellow),
          const SizedBox(height: 18),
          Text('STI eVoter',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 56 : 36,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Vote from your phone. No paper ballots, no waiting in line.',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: large ? 18 : 15,
                  height: 1.4)),
        ],
      );

  Widget _form() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Student')),
              ButtonSegment(value: true, label: Text('Admin')),
            ],
            selected: {admin},
            onSelectionChanged: (s) => setState(() => admin = s.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _user,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
                labelText: admin ? 'Username' : 'Student number'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _pass,
            obscureText: hide,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => hide = !hide),
              ),
            ),
          ),
          const SizedBox(height: 22),
          BlueButton(label: 'Sign in', onPressed: _submit),
          const SizedBox(height: 14),
          if (error != null)
            Text(error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700)),
          const SizedBox(height: 14),
          BlueButton(
              label: busy ? 'Signing in...' : 'Sign in',
              onPressed: busy ? null : _submit),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          // PC or landscape: brand panel on the left, form on the right
          if (c.maxWidth >= 720) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    color: C.navy,
                    padding: const EdgeInsets.all(48),
                    alignment: Alignment.centerLeft,
                    child: _brand(large: c.maxWidth >= 1000),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _form(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: C.navy,
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 36),
                child: _brand(),
              ),
              Padding(padding: const EdgeInsets.all(24), child: _form()),
            ],
          );
        },
      ),
    );
  }
}
