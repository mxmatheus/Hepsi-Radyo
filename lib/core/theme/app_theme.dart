import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.racingGreenPrimary,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.racingGreenPrimary,
        secondary: AppColors.wineRedAccent,
        surface: AppColors.lightSurface,
        background: AppColors.lightBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme: GoogleFonts.playfairDisplayTextTheme(ThemeData.light().textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(color: AppColors.lightTextPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: AppColors.lightTextSecondary, fontSize: 14),
        titleLarge: GoogleFonts.playfairDisplay(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        titleMedium: GoogleFonts.playfairDisplay(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.racingGreenPrimary,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.racingGreenPrimary,
        secondary: AppColors.wineRedAccent,
        surface: AppColors.darkSurface,
        background: AppColors.darkBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: GoogleFonts.playfairDisplayTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(color: AppColors.darkTextPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: AppColors.darkTextSecondary, fontSize: 14),
        titleLarge: GoogleFonts.playfairDisplay(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        titleMedium: GoogleFonts.playfairDisplay(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      ),
    );
  }
}
