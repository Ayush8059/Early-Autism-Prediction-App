import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant, kid-friendly and premium colors
  static const Color primary = Color(0xFF7C3AED); // Vivid Purple
  static const Color secondary = Color(0xFFEC4899); // Vibrant Pink
  static const Color accent = Color(0xFF06B6D4); // Cyan
  static const Color backgroundLight = Color(0xFFF8FAFC); // Very light slate
  static const Color backgroundDark = Color(0xFF0F172A); // Deep Slate
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);

  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static bool _isDark = false;

  static void setDarkMode(bool value) {
    _isDark = value;
  }

  static Color get background => _isDark ? backgroundDark : backgroundLight;
  static Color get cardColor => _isDark ? cardDark : cardLight;
  static Color get textPrimary => _isDark ? textPrimaryDark : textPrimaryLight;
  static Color get textSecondary =>
      _isDark ? textSecondaryDark : textSecondaryLight;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white24, Colors.white10],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: cardLight,
        onSurface: textPrimaryLight,
        onBackground: textPrimaryLight,
        tertiary: accent,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.outfit(
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        displaySmall: GoogleFonts.outfit(
          color: textPrimaryLight,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textPrimaryLight,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        titleMedium: GoogleFonts.outfit(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyLarge: GoogleFonts.outfit(color: textPrimaryLight, fontSize: 16),
        bodyMedium: GoogleFonts.outfit(color: textSecondaryLight, fontSize: 14),
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: cardDark,
        onSurface: textPrimaryDark,
        onBackground: textPrimaryDark,
        tertiary: accent,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.outfit(
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        displaySmall: GoogleFonts.outfit(
          color: textPrimaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textPrimaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        titleMedium: GoogleFonts.outfit(
          color: textPrimaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyLarge: GoogleFonts.outfit(color: textPrimaryDark, fontSize: 16),
        bodyMedium: GoogleFonts.outfit(color: textSecondaryDark, fontSize: 14),
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
