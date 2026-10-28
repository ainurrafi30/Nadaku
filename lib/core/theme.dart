import 'package:flutter/material.dart';

/// Palet warna Nadaku: nila malam (indigo batik) dengan aksen kunyit.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF0E1230);
  static const Color surface = Color(0xFF171C42);
  static const Color surfaceHigh = Color(0xFF222862);
  static const Color accent = Color(0xFFFFC53D);
  static const Color onAccent = Color(0xFF1A1300);
  static const Color textPrimary = Color(0xFFF2F0FA);
  static const Color textSecondary = Color(0xFF9EA3CF);
  static const Color heart = Color(0xFFFF7F9E);
  static const Color danger = Color(0xFFFF8A80);
}

ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.danger,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.accent.withAlpha(46),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: Color(0x33FFFFFF),
      thumbColor: AppColors.accent,
      overlayColor: Color(0x29FFC53D),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}
