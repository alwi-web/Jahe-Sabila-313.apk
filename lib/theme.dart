import 'package:flutter/material.dart';

/// Warna yang sama dengan desain di kanvas.
class AppColors {
  static const ink = Color(0xFF2B1B14);
  static const muted = Color(0xFF6B5648);
  static const brand = Color(0xFFA8321F);
  static const brandDark = Color(0xFF7E2214);
  static const brown = Color(0xFF7A4A1E);
  static const line = Color(0xFFEADFD2);
  static const field = Color(0xFFD9C9B6);
  static const cream = Color(0xFFF6EFE6);
  static const paper = Color(0xFFFBF7F2);

  /// Latar semua layar: krem sangat muda, supaya kartu putih terlihat terpisah.
  static const background = Color(0xFFFAF6F1);
  static const kraft = Color(0xFFD6B88E);
  static const kraftTop = Color(0xFFC4A272);
  static const kraftEdge = Color(0xFFBFA074);
  static const whatsapp = Color(0xFF1F7A4D);
  static const success = Color(0xFF1F6440);
  static const successBg = Color(0xFFE1F2E8);
}

/// Skala teks aplikasi (font Plus Jakarta Sans). Pakai ini, bukan ukuran bebas.
class AppText {
  static const family = 'PlusJakartaSans';

  /// Judul besar di halaman (mis. "Produk kami", "Masuk").
  static const display = TextStyle(
      fontFamily: AppText.family, fontSize: 24, fontWeight: FontWeight.w800, height: 1.25, letterSpacing: -0.3);

  /// Judul bagian di dalam halaman (mis. "Kenapa memilih Sabila 313?").
  static const section = TextStyle(
      fontFamily: AppText.family, fontSize: 18, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.2);

  /// Judul kartu / nama produk di daftar.
  static const cardTitle =
      TextStyle(fontFamily: AppText.family, fontSize: 15, fontWeight: FontWeight.w700, height: 1.35);

  /// Teks isi.
  static const body = TextStyle(fontFamily: AppText.family, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  /// Teks isi yang perlu ditekankan (label, nilai).
  static const bodyStrong =
      TextStyle(fontFamily: AppText.family, fontSize: 14, fontWeight: FontWeight.w600, height: 1.45);

  /// Keterangan kecil berwarna redup.
  static const caption = TextStyle(
      fontFamily: AppText.family, fontSize: 13, fontWeight: FontWeight.w500, height: 1.45, color: AppColors.muted);

  /// Harga.
  static const price =
      TextStyle(fontFamily: AppText.family, fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brand);
}

/// Skala jarak: 4, 8, 12, 16, 24, 32. Tepi halaman 20.
class Gap {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
  static const page = 20.0;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    primary: AppColors.brand,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppText.family,
    scaffoldBackgroundColor: AppColors.background,
  );

  final text = base.textTheme
      .copyWith(
        headlineSmall: AppText.display,
        titleLarge:
            const TextStyle(fontFamily: AppText.family, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        titleMedium: AppText.cardTitle,
        titleSmall: AppText.bodyStrong,
        bodyLarge: const TextStyle(fontFamily: AppText.family, fontSize: 15, height: 1.5),
        bodyMedium: AppText.body,
        bodySmall: AppText.caption,
        labelLarge: const TextStyle(fontFamily: AppText.family, fontSize: 15, fontWeight: FontWeight.w700),
        labelMedium: const TextStyle(fontFamily: AppText.family, fontSize: 13, fontWeight: FontWeight.w600),
      )
      .apply(fontFamily: AppText.family, bodyColor: AppColors.ink, displayColor: AppColors.ink);

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(fontFamily: AppText.family, color: Color(0xFF9C887A), fontWeight: FontWeight.w400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border(AppColors.field),
      enabledBorder: border(AppColors.field),
      focusedBorder: border(AppColors.brand, 1.6),
      errorBorder: border(Colors.red.shade700),
      focusedErrorBorder: border(Colors.red.shade700, 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.field,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.field),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontFamily: AppText.family, fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.cream,
      height: 68,
      elevation: 0,
      shadowColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: AppText.family,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? AppColors.brand : AppColors.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? AppColors.brand : AppColors.muted,
          )),
    ),
    listTileTheme: const ListTileThemeData(
      titleTextStyle:
          TextStyle(fontFamily: AppText.family, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
      subtitleTextStyle: AppText.caption,
      iconColor: AppColors.brown,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.brand),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle:
          const TextStyle(fontFamily: AppText.family, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: AppText.section.copyWith(color: AppColors.ink),
      contentTextStyle: AppText.body.copyWith(color: AppColors.muted),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
  );
}
