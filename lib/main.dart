import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'screens/auth.dart';
import 'theme.dart';

void main() => runApp(const EVoterApp());

class EVoterApp extends StatelessWidget {
  const EVoterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'STI eVoter',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // lets mouse and trackpad drag the carousel on PC
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
        ),
        home: const AuthPage(),
      );
}
