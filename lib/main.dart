import 'package:flutter/material.dart';
import 'shared/pages/auth.dart';
import 'theme.dart';

void main() => runApp(const EVoterApp());

class EVoterApp extends StatelessWidget {
  const EVoterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'STI eVoter',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AuthPage(),
      );
}
