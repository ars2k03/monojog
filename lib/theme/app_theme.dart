import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Premium Dark Palette ──
  static const Color primaryColor = Color(0xFF00E5FF); // Cyan accent
  static const Color secondaryColor = Color(0xFF2979FF); // Blue accent
  static const Color primaryLight = Color(0xFF2979FF); // Blue accent
  static const Color primaryDark = Color(0xFF0A0A0F); // Ultra-deep background
  static const Color accentPurple = Color(0xFF7C4DFF);

  // Functional colors
  static const Color goldColor = Color(0xFFFFD700);
  static const Color gemColor = Color(0xFF00F5D4);
  static const Color healthRed = Color(0xFFFF4D6D);
  static const Color xpYellow = Color(0xFFFEE440);
  static const Color successColor = Color(0xFF00F5D4);
  static const Color warningColor = Color(0xFFFEE440);
  static const Color errorColor = Color(0xFFFF4D6D);

  // Task difficulty colors
  static const Color easyGreen = Color(0xFF00F5D4);
  static const Color mediumYellow = Color(0xFFFEE440);
  static const Color hardRed = Color(0xFFFF4D6D);

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E2E), Color(0xFF16161F)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1AFFFFFF), Color(0x05FFFFFF)],
  );

  // Light theme (Neumorphic)
  static const Color lightBg = Color(0xFFE0E5EC);
  static const Color lightSurface = Color(0xFFE0E5EC);
  static const Color lightCard = Color(0xFFE0E5EC);
  static const Color lightText = Color(0xFF212529);
  static const Color lightTextSec = Color(0xFF6C757D);
  static const Color lightBorder = Color(0xFFDEE2E6);

  // Dark theme (Neumorphic) - Enhanced
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF16161F);
  static const Color darkCard = Color(0xFF1E1E2E);
  static const Color darkText = Color(0xFFF8F9FA);
  static const Color darkTextSec = Color(0xFF8B8FA3);

  static TextTheme _buildTextTheme(TextTheme base, Brightness brightness) {
    final color = brightness == Brightness.dark ? darkText : lightText;
    final secColor =
        brightness == Brightness.dark ? darkTextSec : lightTextSec;
    return GoogleFonts.interTextTheme(base).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        color: color,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        color: secColor,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBg,
    textTheme: _buildTextTheme(ThemeData.light().textTheme, Brightness.light),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: primaryLight,
      tertiary: goldColor,
      surface: lightSurface,
      error: errorColor,
      onPrimary: Colors.white,
      onSurface: lightText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: lightText),
      titleTextStyle: GoogleFonts.inter(
        color: lightText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: lightBg,
      selectedItemColor: primaryColor,
      unselectedItemColor: lightTextSec,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle:
          GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle:
          GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      hintStyle: const TextStyle(color: lightTextSec),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBg,
    textTheme: _buildTextTheme(ThemeData.dark().textTheme, Brightness.dark),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryLight,
      tertiary: goldColor,
      surface: darkSurface,
      error: errorColor,
      onPrimary: Colors.black,
      onSurface: darkText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkBg,
      selectedItemColor: primaryColor,
      unselectedItemColor: darkTextSec,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle:
          GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle:
          GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: darkTextSec),
    ),
  );

  /// Difficulty color
  static Color difficultyColor(int d) {
    switch (d) {
      case 1:
        return easyGreen;
      case 3:
        return hardRed;
      default:
        return mediumYellow;
    }
  }
}
