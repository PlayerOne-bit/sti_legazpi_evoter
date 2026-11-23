import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'screens/auth.dart';
import 'theme.dart';

void main() => runApp(const EVoterApp());

class EVoterApp extends StatelessWidget {
  const EVoterApp({super.key});

  static final _light = buildTheme(Brightness.light);
  static final _dark = buildTheme(Brightness.dark);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeMode,
        builder: (_, mode, __) => MaterialApp(
          title: 'STI eVoter',
          debugShowCheckedModeBanner: false,
          theme: _light,
          darkTheme: _dark,
          themeMode: mode,
          themeAnimationDuration: Duration.zero,
          builder: (_, child) => ThemeSync(child: child!),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad
            },
          ),
          home: const AuthPage(),
        ),
      );
}
