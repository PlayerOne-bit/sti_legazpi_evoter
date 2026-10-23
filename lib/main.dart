import 'package:flutter/material.dart';

import 'screens/auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STI Legazpi eVoter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 0, 255),
        ),
      ),
      home: const AuthScreen(title: 'STI Legazpi eVoter'),
    );
  }
}
