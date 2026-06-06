import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BearWaveTheme {
  // Authentic BearWave Dark Navy Colors
  static const Color bgA = Color(0xFF0F141B);
  static const Color bgB = Color(0xFF131B25);

  // Eyecatcher Space Gradients (Vibrant Mockup Colors)
  static const Color spaceDark = Color(0xFF070B19);
  static const Color spaceDeepBlue = Color(0xFF0B1930);
  static const Color spaceLightBlue = Color(0xFF1B75BB); // Lighter blue at the top

  static const LinearGradient spaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [spaceLightBlue, spaceDeepBlue, spaceDark],
    stops: [0.0, 0.4, 1.0],
  );

  // Card/Panel colors
  static const Color panel = Color(0xFF121B2A);
  static const Color card = Color(0xFF172336);
  static const Color cardHover = Color(0xFF1D2C44);
  static const Color cardBorder = Color(0xFF243654);

  // Accents
  static const Color accent = Color(0xFF2BB0FF); // BearWave Accent Blue
  static const Color accentVariant = Color(0xFF1D99F3);

  // Text
  static const Color textMain = Color(0xFFEAF1FB);
  static const Color textMuted = Color(0xFF9EB1C9);
  static const Color warn = Color(0xFFFF8B8B);

  // No gradient for authentic KDE look
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [bgA, bgA],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentVariant],
  );

  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.outfitTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentVariant,
        surface: panel,
        error: warn,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: textMain,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: textMain,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: textMain,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: textMain,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: textMain,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: textMain),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textMain),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textMain),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: textMuted),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: accent,
          fontWeight: FontWeight.bold,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: accent),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: textMuted),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bgB,
          elevation: 4,
          shadowColor: accent.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static String getFlagEmoji(String countryCode) {
    if (countryCode.length != 2) return '🌎';
    final codePoints = countryCode
        .toUpperCase()
        .codeUnits
        .map((code) => 127397 + code)
        .toList();
    return String.fromCharCodes(codePoints);
  }
}
