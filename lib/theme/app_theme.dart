import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgPrimary = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFF0EDE8);
  static const Color inputBg = Color(0xFFE8E4DF);

  static const Color navBg = Color(0xFFF0EDE8);
  static const Color navUnselected = Color(0xFFD5D1CB);
  static const Color navSelected = Color(0xFF3D3933);
  static const Color navIndicator = Color(0xFFD5D1CB);

  static const Color buttonBg = Color(0xFFD5D1CB);
  static const Color buttonBorder = Color(0xFF000000);
  static const Color buttonText = Color(0xFF3D3933);

  static const Color textPrimary = Color(0xFF3D3933);
  static const Color textSecondary = Color(0xFF7A7570);
  static const Color textHint = Color(0xFFB0ABA6);

  static const Color bookmarkAccent = Color(0xFFC9A84C);
  static const Color progressFilled = Color(0xFF3D3933);
  static const Color progressTrack = Color(0xFFD5D1CB);
  static const Color starFilled = Color(0xFFC9A84C);
  static const Color tagBg = Color(0xFFE8E4DF);
  static const Color tagBorder = Color(0xFFC5C1BB);
  static const Color tagText = Color(0xFF5A5652);

  static const Color timerTrack = Color(0xFFD5D1CB);
  static const Color timerFilled = Color(0xFF3D3933);
  static const Color timerText = Color(0xFF3D3933);
  static const Color sessionAccent = Color(0xFFC9A84C);

  static TextStyle get appName => GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: textPrimary,
      );

  static TextStyle get screenTitle => GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        color: textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: textPrimary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: textSecondary,
      );

  static TextStyle get buttonLabel => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: buttonText,
      );

  static ButtonStyle get pillButton => ElevatedButton.styleFrom(
        backgroundColor: buttonBg,
        foregroundColor: buttonText,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: buttonBorder, width: 1),
        ),
        textStyle: buttonLabel,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );

  static InputDecoration inputDecoration(String hint) => InputDecoration(
        filled: true,
        fillColor: inputBg,
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: textHint, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: bgPrimary,
        colorScheme: ColorScheme.light(
          primary: textPrimary,
          surface: surface,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: bgPrimary,
          elevation: 0,
          titleTextStyle: appName,
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: navBg,
          selectedItemColor: navSelected,
          unselectedItemColor: navUnselected,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: pillButton),
        useMaterial3: true,
      );
}
