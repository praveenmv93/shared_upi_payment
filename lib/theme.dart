import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Gen-Z SuperMoney-inspired Palette
  static const Color primary = Color(0xFF4D43FE);        // SuperMoney purple
  static const Color primaryLight = Color(0xFF7B74FF);   // Light purple
  static const Color accent = Color(0xFFFFE234);         // Electric yellow
  static const Color accentGreen = Color(0xFF00E676);    // Neon green
  static const Color accentPink = Color(0xFFFF4081);     // Hot pink
  static const Color accentOrange = Color(0xFFFF6D00);   // Vibrant orange
  static const Color backgroundDark = Color(0xFF0B0B1A); // Ultra dark
  static const Color surface = Color(0xFF12122A);        // Card surface
  static const Color surfaceElevated = Color(0xFF1A1A38);// Elevated surface
  static const Color borderColor = Color(0xFF2A2A50);    // Subtle border
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF8888BB);       // Muted purple-grey
  static const Color textMuted = Color(0xFF55556A);

  // Legacy aliases for backward compat
  static const Color primaryIndigo = surface;
  static const Color accentLime = accentGreen;
  static const Color accentViolet = primary;
  static const Color cardBg = surface;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        brightness: Brightness.dark,
        surface: backgroundDark,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: textWhite,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(color: textWhite, fontSize: 16),
        labelLarge: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
          color: textGrey,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: borderColor, width: 1),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: TextStyle(color: textMuted),
        labelStyle: TextStyle(color: textGrey),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textWhite,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: textWhite),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: textGrey,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: TextStyle(color: textWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primary.withOpacity(0.4)
                : borderColor),
      ),
    );
  }
}
