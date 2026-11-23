import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static bool dark = false;

  static const navy = Color(0xFF0B1F3A);
  static const yellow = Color(0xFFFFC600);
  static const onYellow = Color(0xFF1F1A00);

  static Color get blue =>
      dark ? const Color(0xFF4A8BEF) : const Color(0xFF0A4DA2);
  static Color get blueDeep =>
      dark ? const Color(0xFF1F4F94) : const Color(0xFF083D82);
  static Color get paper =>
      dark ? const Color(0xFF121418) : const Color(0xFFF7F9FC);
  static Color get surface => dark ? const Color(0xFF1B1E24) : Colors.white;
  static Color get surface2 =>
      dark ? const Color(0xFF23272E) : const Color(0xFFF3F6FB);
  static Color get tint =>
      dark ? const Color(0xFF1C2B42) : const Color(0xFFE3ECF8);
  static Color get ink =>
      dark ? const Color(0xFFE7EAEE) : const Color(0xFF16202E);
  static Color get muted =>
      dark ? const Color(0xFF9AA4B1) : const Color(0xFF6B7788);
  static Color get line =>
      dark ? const Color(0xFF2E333B) : const Color(0xFFDDE3EC);
  static Color get ok =>
      dark ? const Color(0xFF45C287) : const Color(0xFF1E8E5A);
  static Color get okBg =>
      dark ? const Color(0xFF15301F) : const Color(0xFFE7F5EE);
  static Color get warnBg =>
      dark ? const Color(0xFF3A3113) : const Color(0xFFFFF3C4);
  static Color get warnFg =>
      dark ? const Color(0xFFFFD866) : const Color(0xFF8A6500);
  static Color get danger =>
      dark ? const Color(0xFFFF8A80) : const Color(0xFFC62828);
  static Color get shadow => dark
      ? Colors.black.withValues(alpha: 0.35)
      : navy.withValues(alpha: 0.06);
}

final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

void cycleThemeMode() {
  themeMode.value = switch (themeMode.value) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  };
}

class ThemeToggleButton extends StatelessWidget {
  final Color? color;
  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (_, mode, __) {
        final (icon, tip) = switch (mode) {
          ThemeMode.system => (Icons.brightness_auto_outlined, 'Theme: system'),
          ThemeMode.light => (Icons.light_mode_outlined, 'Theme: light'),
          ThemeMode.dark => (Icons.dark_mode_outlined, 'Theme: dark'),
        };
        return IconButton(
          tooltip: tip,
          color: color,
          icon: Icon(icon),
          onPressed: cycleThemeMode,
        );
      },
    );
  }
}

class ThemeSync extends StatefulWidget {
  final Widget child;
  const ThemeSync({super.key, required this.child});

  @override
  State<ThemeSync> createState() => _ThemeSyncState();
}

class _ThemeSyncState extends State<ThemeSync> {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (C.dark != dark) {
      C.dark = dark;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        void mark(Element e) {
          e.markNeedsBuild();
          e.visitChildren(mark);
        }

        (context as Element).visitChildren(mark);
      });
    }
    return widget.child;
  }
}

ThemeData buildTheme(Brightness brightness) {
  final prev = C.dark;
  C.dark = brightness == Brightness.dark;
  final dark = C.dark;

  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0A4DA2),
    brightness: brightness,
  ).copyWith(
    primary: C.blue,
    onPrimary: Colors.white,
    secondary: C.yellow,
    onSecondary: C.onYellow,
    surface: C.surface,
    onSurface: C.ink,
    surfaceContainerHighest: C.surface2,
    surfaceContainerHigh: C.surface2,
    surfaceContainer: C.surface,
    surfaceContainerLow: C.surface,
    outline: C.line,
    outlineVariant: C.line,
    error: C.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.paper,
    canvasColor: C.surface,
    dividerColor: C.line,
  );
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
      .apply(bodyColor: C.ink, displayColor: C.ink);
  final r12 = BorderRadius.circular(12);

  final theme = base.copyWith(
    textTheme: text,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? C.surface : C.blue,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: C.shadow,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(
          color: dark ? C.ink : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20),
      iconTheme: IconThemeData(color: dark ? C.ink : Colors.white),
      actionsIconTheme: IconThemeData(color: dark ? C.ink : Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: C.yellow.withValues(alpha: dark ? 0.22 : 0.35),
      indicatorShape: RoundedRectangleBorder(borderRadius: r12),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? C.blue : C.muted,
          size: 24)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? C.blue : C.muted,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: C.surface,
      indicatorColor: C.yellow.withValues(alpha: dark ? 0.22 : 0.35),
      indicatorShape: RoundedRectangleBorder(borderRadius: r12),
      selectedIconTheme: IconThemeData(color: C.blue),
      unselectedIconTheme: IconThemeData(color: C.muted),
      selectedLabelTextStyle:
          TextStyle(color: C.blue, fontWeight: FontWeight.w800, fontSize: 12),
      unselectedLabelTextStyle:
          TextStyle(color: C.muted, fontWeight: FontWeight.w600, fontSize: 12),
    ),
    cardTheme: CardThemeData(
      color: C.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: C.line)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle:
          text.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: C.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: r12, side: BorderSide(color: C.line)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? C.surface2 : C.navy,
      contentTextStyle: TextStyle(
          color: dark ? C.ink : Colors.white, fontWeight: FontWeight.w600),
      actionTextColor: C.yellow,
      shape: RoundedRectangleBorder(borderRadius: r12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: C.line,
        shape: RoundedRectangleBorder(borderRadius: r12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.blue,
        side: BorderSide(color: C.blue, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: r12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.blue,
        shape: RoundedRectangleBorder(borderRadius: r12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: C.yellow,
      foregroundColor: C.onYellow,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: C.surface2,
      selectedColor: C.tint,
      side: BorderSide(color: C.line),
      labelStyle: TextStyle(color: C.ink, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      checkmarkColor: C.blue,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface2,
      labelStyle: TextStyle(color: C.muted),
      hintStyle: TextStyle(color: C.muted),
      prefixIconColor: C.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: r12, borderSide: BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: r12, borderSide: BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: r12, borderSide: BorderSide(color: C.blue, width: 2)),
      disabledBorder: OutlineInputBorder(
          borderRadius: r12,
          borderSide: BorderSide(color: C.line.withValues(alpha: 0.6))),
    ),
    listTileTheme: ListTileThemeData(iconColor: C.blue, textColor: C.ink),
    dividerTheme: DividerThemeData(color: C.line, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: C.blue),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
          color: dark ? C.surface2 : C.navy,
          borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(color: dark ? C.ink : Colors.white, fontSize: 12),
    ),
  );
  C.dark = prev;
  return theme;
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

String fmtDate(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return '${_months[d.month - 1]} ${d.day}, ${d.year}, $h12:${d.minute.toString().padLeft(2, '0')} $ap';
}

BoxDecoration cardBox({Color? color, Color? border}) => BoxDecoration(
      color: color ?? C.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border ?? C.line),
      boxShadow: [
        BoxShadow(color: C.shadow, blurRadius: 12, offset: const Offset(0, 4))
      ],
    );

String fmtDay(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
