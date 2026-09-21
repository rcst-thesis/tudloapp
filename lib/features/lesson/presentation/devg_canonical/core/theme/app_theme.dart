import 'package:flutter/material.dart';

/// Central color tokens for Tudlo.
///
/// Prefer using these constants instead of hard-coded colors so the app stays
/// visually consistent across onboarding, map, lessons, translation, and tests.
class TudloColors {
  static const navy = Color(0xFF17324D);
  static const blue = Color(0xFF18A8FF);
  static const cloud = Color(0xFFFFFFFF);
  static const meadow = Color(0xFFCBEF4A);
  static const forest = Color(0xFF38A800);
  static const brightGreen = Color(0xFF79D900);
  static const softGreen = Color(0xFFA6F4E0);

  static const sky = Color(0xFF42C7FF);
  static const mint = softGreen;
  static const ink = navy;
  static const muted = Color(0xFF32607A);
  static const paper = Color(0xFFF7FFE7);
  static const line = Color(0xFFBDEFFF);
  static const coral = Color(0xFFFF6B00);
  static const gold = Color(0xFFFFD429);
  static const orange = Color(0xFFFF9F1C);
  static const green = brightGreen;
}

/// Global Flutter theme shared by the whole app.
///
/// Screen-specific designs can still customize layout, but base colors,
/// typography, and button defaults should start here.
class TudloTheme {
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TudloColors.meadow, TudloColors.softGreen],
  );

  static final theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TudloColors.sky,
      primary: TudloColors.sky,
      secondary: TudloColors.forest,
      surface: TudloColors.paper,
    ),
    scaffoldBackgroundColor: TudloColors.paper,
    fontFamily: 'Arial',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: TudloColors.ink,
        fontSize: 32,
        fontWeight: FontWeight.w900,
      ),
      titleLarge: TextStyle(
        color: TudloColors.ink,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
      bodyMedium: TextStyle(
        color: TudloColors.muted,
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w800,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TudloColors.brightGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: TudloColors.line,
        disabledForegroundColor: TudloColors.muted,
        elevation: 4,
        shadowColor: TudloColors.forest,
        minimumSize: const Size(64, 64),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

/// Reusable white card with Tudlo's border, radius, and soft shadow.
///
/// Use this for general content panels when a screen does not need a custom
/// card design.
class TudloCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const TudloCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TudloColors.line, width: 3),
        boxShadow: [
          BoxShadow(
            color: TudloColors.ink.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Shared soft green page background used by simple form-like screens.
class TudloPageBackground extends StatelessWidget {
  final Widget child;

  const TudloPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: TudloTheme.gradient),
      child: SafeArea(child: child),
    );
  }
}
