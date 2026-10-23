import 'package:flutter/material.dart';
import '../../admin/pages/admin_shell.dart';
import '../../client/pages/home.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../components/blue_button.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool admin = false;
  bool hide = true;
  final _user = TextEditingController();
  final _pass = TextEditingController();

  void _submit() {
    state.isAdmin = admin;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => admin ? const AdminShell() : const ClientHome(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: C.navy,
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 44, height: 5, color: C.yellow),
                const SizedBox(height: 18),
                const Text('STI eVoter',
                    style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Vote from your phone. No paper ballots, no waiting in line.',
                    style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
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
                  decoration: InputDecoration(labelText: admin ? 'Username' : 'Student number'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pass,
                  obscureText: hide,
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
                const Text('Prototype: any credentials work.',
                    textAlign: TextAlign.center, style: TextStyle(color: C.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
