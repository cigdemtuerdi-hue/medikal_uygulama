import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MedGift visual tokens with WCAG 2.1 AA-oriented contrast for text and UI chrome.
class AppTheme {
  // Smart Medical Heart palette
  static const Color primaryDeepBlue = Color(0xFF0D3B6E);
  static const Color primaryBlue = Color(0xFF1A5FA8);
  static const Color lightBlue = Color(0xFF5BB5F5);
  static const Color skyBlue = Color(0xFFB8DCFA);
  static const Color cleanWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7FAFE);

  /// Fill/icon accent (pastel). Prefer [accentOnSurface] for text on light fills.
  static const Color accentTeal = Color(0xFF4BA3F0);

  /// Text-safe accent on white / light surfaces (≥4.5:1).
  static const Color accentOnSurface = Color(0xFF0B4F8C);

  /// Warning fill. Prefer [warningOnSurface] for text on warning chips.
  static const Color warningAmber = Color(0xFFF9A825);

  /// Text-safe warning on light amber fills (≥4.5:1).
  static const Color warningOnSurface = Color(0xFF6B3F00);

  /// Unselected / muted icons on white (≥3:1 UI contrast).
  static const Color mutedIcon = Color(0xFF4A668A);

  static const double radiusCard = 16;
  static const double radiusInput = 12;
  static const double pagePadding = 24;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      onPrimary: cleanWhite,
      secondary: accentOnSurface,
      onSecondary: cleanWhite,
      surface: surfaceLight,
      onSurface: primaryDeepBlue,
      error: const Color(0xFFB3261E),
      onError: cleanWhite,
      errorContainer: const Color(0xFFF9DEDC),
      onErrorContainer: const Color(0xFF410E0B),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: primaryDeepBlue.withValues(alpha: 0.92),
      displayColor: primaryDeepBlue,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    final focusSide = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (states.contains(WidgetState.focused)) {
        return const BorderSide(color: primaryDeepBlue, width: 2.5);
      }
      return null;
    });

    return base.copyWith(
      scaffoldBackgroundColor: surfaceLight,
      textTheme: textTheme,
      focusColor: primaryBlue.withValues(alpha: 0.18),
      hoverColor: primaryBlue.withValues(alpha: 0.06),
      splashColor: primaryBlue.withValues(alpha: 0.12),
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
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: textTheme.bodyMedium?.copyWith(color: mutedIcon),
        floatingLabelStyle:
            textTheme.bodyMedium?.copyWith(color: primaryBlue),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: mutedIcon.withValues(alpha: 0.85),
        ),
        helperStyle: textTheme.bodySmall?.copyWith(color: mutedIcon),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: skyBlue.withValues(alpha: 0.9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: mutedIcon.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: cleanWhite,
          disabledBackgroundColor: mutedIcon.withValues(alpha: 0.35),
          disabledForegroundColor: cleanWhite,
          padding: buttonPadding,
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ).copyWith(
          side: focusSide,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return primaryDeepBlue.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: buttonPadding,
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          side: const BorderSide(color: primaryBlue, width: 1.4),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: primaryDeepBlue, width: 2.5);
            }
            return const BorderSide(color: primaryBlue, width: 1.4);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          minimumSize: const Size(48, 44),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ).copyWith(
          side: focusSide,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primaryDeepBlue,
          minimumSize: const Size(48, 48),
          focusColor: primaryBlue.withValues(alpha: 0.18),
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
          textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: primaryDeepBlue,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryBlue);
          }
          return const IconThemeData(color: mutedIcon);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cleanWhite,
        selectedIconTheme: const IconThemeData(color: primaryBlue),
        unselectedIconTheme: const IconThemeData(color: mutedIcon),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: primaryBlue,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: mutedIcon,
        ),
        indicatorColor: lightBlue.withValues(alpha: 0.18),
        labelType: NavigationRailLabelType.all,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cleanWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
    );
  }
}
