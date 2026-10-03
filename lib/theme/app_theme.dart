import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primaryFont = Color(0xFF292D32);
  static const secondaryFont = Color(0xFF505050);
  static const mutedFont = Color(0xFF8A8A8A);
  static const primaryAccent = Color(0xFF036679);
  static const buttonText = Color(0xFFFFFFFF);
  static const errorText = Color(0xFFB64035);
  static const background = Color(0xFFF7F8F9);
  static const cardBackground = Color(0xFFFFFFFF);
  static const border = Color(0xFFE3E5E8);
}

class AppTheme {
  static ThemeData get theme {
    final textTheme = GoogleFonts.tajawalTextTheme().apply(
      bodyColor: AppColors.primaryFont,
      displayColor: AppColors.primaryFont,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAccent,
        primary: AppColors.primaryAccent,
        error: AppColors.errorText,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      fontFamily: GoogleFonts.tajawal().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.buttonText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          color: AppColors.buttonText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.buttonText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.mutedFont),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerColor: AppColors.border,
    );
  }
}