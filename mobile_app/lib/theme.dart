import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg = Color(0xFF0A0A0A);
  static const Color card = Color(0xFF1C1C1E);
  static const Color accent = Color(0xFFFF5C5C); // Coral
  static const Color text = Colors.white;
  static const Color textSecondary = Color(0xFF8E8E93);
  
  static const Color urgent = Color(0xFFFF453A);
  static const Color high = Color(0xFFFF9F0A);
  static const Color medium = Color(0xFF5E5CE6);
  static const Color low = Color(0xFF30D158);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: card,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: text),
        displayMedium: GoogleFonts.inter(fontWeight: FontWeight.bold, color: text),
        displaySmall: GoogleFonts.inter(fontWeight: FontWeight.bold, color: text),
        headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: text),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: text),
        bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w500, color: text),
        bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, color: text),
        labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, color: textSecondary, fontSize: 10, letterSpacing: 1.2),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFF48484A),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  static TextStyle get monoStyle => GoogleFonts.jetBrainsMono();
}
