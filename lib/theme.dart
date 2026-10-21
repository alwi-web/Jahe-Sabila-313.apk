import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna yang sama dengan desain di kanvas.
class AppColors {
  static const ink = Color(0xFF2B1B14);
  static const muted = Color(0xFF6B5648);
  static const brand = Color(0xFFA8321F);
  static const brown = Color(0xFF7A4A1E);
  static const line = Color(0xFFEADFD2);
  static const field = Color(0xFFD9C9B6);
  static const cream = Color(0xFFF6EFE6);
  static const paper = Color(0xFFFBF7F2);
  static const kraft = Color(0xFFD6B88E);
  static const kraftTop = Color(0xFFC4A272);
  static const kraftEdge = Color(0xFFBFA074);
  static const whatsapp = Color(0xFF1F7A4D);
  static const success = Color(0xFF1F6440);
  static const successBg = Color(0xFFE1F2E8);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
  );

  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(AppColors.field),
      enabledBorder: border(AppColors.field),
      focusedBorder: border(AppColors.brand, 2),
      errorBorder: border(Colors.red.shade700),
      focusedErrorBorder: border(Colors.red.shade700, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.field),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
    ),
  );
}
