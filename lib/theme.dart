import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const blue = Color(0xFF0A4DA2);
  static const navy = Color(0xFF0B1F3A);
  static const yellow = Color(0xFFFFC600);
  static const paper = Color(0xFFF4F6FA);
  static const ink = Color(0xFF16202E);
  static const muted = Color(0xFF6B7788);
  static const line = Color(0xFFDDE3EC);
  static const ok = Color(0xFF1E8E5A);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.blue, primary: C.blue),
    scaffoldBackgroundColor: C.paper,
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: C.ink, displayColor: C.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.paper,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: C.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: C.line),
      ),
    ),
  );
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String fmtDate(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return '${_months[d.month - 1]} ${d.day}, ${d.year}, $h12:${d.minute.toString().padLeft(2, '0')} $ap';
}

BoxDecoration cardBox({Color color = Colors.white, Color border = C.line}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border),
    );
