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

  static const double radiusCard = 16;
  static const double radiusInput = 12;
  static const double pagePadding = 24;

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

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: primaryDeepBlue.withValues(alpha: 0.92),
      displayColor: primaryDeepBlue,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return base.copyWith(
      scaffoldBackgroundColor: surfaceLight,
      textTheme: textTheme,
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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: skyBlue.withValues(alpha: 0.6)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: skyBlue.withValues(alpha: 0.35),
        selectedColor: lightBlue.withValues(alpha: 0.35),
        labelStyle: textTheme.labelMedium?.copyWith(color: primaryDeepBlue),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: skyBlue.withValues(alpha: 0.7)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cleanWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: skyBlue.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: skyBlue.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: lightBlue, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: cleanWhite,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: buttonPadding,
          shape: buttonShape,
          side: const BorderSide(color: primaryBlue, width: 1.4),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDeepBlue,
        contentTextStyle: const TextStyle(color: cleanWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cleanWhite,
        indicatorColor: lightBlue.withValues(alpha: 0.25),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cleanWhite,
        selectedIconTheme: const IconThemeData(color: primaryBlue),
        unselectedIconTheme:
            IconThemeData(color: primaryDeepBlue.withValues(alpha: 0.45)),
        indicatorColor: lightBlue.withValues(alpha: 0.18),
        labelType: NavigationRailLabelType.all,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
      ),
    );
  }
}
