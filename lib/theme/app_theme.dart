import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class AppTheme {
  // ================ SCENTVIEW.PK LUXURY PALETTE ================
  static const Color primaryColor = Color(0xFF000000);     // Pure Black
  static const Color secondaryColor = Color(0xFF8E8E93);   // Muted Gray
  static const Color accentColor = Color(0xFFC5A059);
  static const Color backgroundColor = Color(0xFFFFFFFF);  // Pure White
  
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF444444);
  static const Color textTertiary = Color(0xFF8E8E93);
  
  static const Color borderColor = Color(0xFFEEEEEE);      // Very light border
  static const Color dividerColor = Color(0xFFF5F5F5);
  
  static const Color errorColor = Color(0xFF000000);       // Error also black for minimalism
  static const Color successColor = Color(0xFF000000);

  // ================ TEXT STYLES (Serif for luxury) ================
  static TextStyle get headingSerif => GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w700, 
    color: textPrimary,
    letterSpacing: 0.5,
  );
  
  static TextStyle get bodySans => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.3,
  );
  
  static TextStyle get priceStyle => GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: accentColor,
  );

  // ================ MAIN THEME ================
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: Colors.black,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black, size: 22),
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        shape: const Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryColor,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // SHARP CORNERS
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // SHARP CORNERS
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),

      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // SHARP CORNERS
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
        labelStyle: GoogleFonts.montserrat(color: secondaryColor, fontSize: 13),
        hintStyle: GoogleFonts.montserrat(color: secondaryColor.withOpacity(0.5), fontSize: 13),
      ),
    );
  }
}
