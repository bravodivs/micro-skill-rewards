import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF15251D);
  static const mutedInk = Color(0xFF627069);
  static const canvas = Color(0xFFF2F1E9);
  static const paper = Color(0xFFFFFEF8);
  static const lime = Color(0xFFC9F25F);
  static const mint = Color(0xFFC7F0DB);
  static const lilac = Color(0xFFE2D6FF);
  static const peach = Color(0xFFFFD7B5);
  static const yellow = Color(0xFFFFE58F);
  static const coral = Color(0xFFFF765E);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          brightness: Brightness.light,
          surface: AppColors.paper,
        ).copyWith(
          primary: AppColors.ink,
          onPrimary: Colors.white,
          secondary: AppColors.lime,
          onSecondary: AppColors.ink,
          error: AppColors.coral,
          surface: AppColors.paper,
          onSurface: AppColors.ink,
          outline: AppColors.ink.withValues(alpha: 0.16),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 42,
          height: 1.03,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: AppColors.ink,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.9,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 25,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(fontSize: 17, height: 1.45, color: AppColors.ink),
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: AppColors.mutedInk,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 70,
        indicatorColor: AppColors.lime,
        backgroundColor: AppColors.paper,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
