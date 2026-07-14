import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Smart Medical Heart palette
  static const Color primaryDeepBlue = Color(0xFF0D3B6E);
  static const Color primaryBlue = Color(0xFF1A5FA8);
  static const Color lightBlue = Color(0xFF5BB5F5);
  static const Color skyBlue = Color(0xFFB8DCFA);
  static const Color cleanWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7FAFE);

  /// Harmonized accent — shifted from teal to light blue for palette cohesion.
  static const Color accentTeal = Color(0xFF4BA3F0);
  static const Color warningAmber = Color(0xFFF9A825);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: lightBlue,
        surface: surfaceLight,
        onPrimary: cleanWhite,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: surfaceLight,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: cleanWhite,
        foregroundColor: primaryDeepBlue,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cleanWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: skyBlue.withValues(alpha: 0.6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cleanWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: skyBlue.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: skyBlue.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBlue, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: cleanWhite,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cleanWhite,
        selectedIconTheme: const IconThemeData(color: primaryBlue),
        unselectedIconTheme: IconThemeData(color: primaryDeepBlue.withValues(alpha: 0.45)),
        indicatorColor: lightBlue.withValues(alpha: 0.18),
        labelType: NavigationRailLabelType.all,
      ),
    );
  }
}
