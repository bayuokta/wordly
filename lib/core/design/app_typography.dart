import 'package:material_ui/material_ui.dart';

import 'app_palette.dart';

/// Nama keluarga font yang terdaftar di `pubspec.yaml`.
abstract final class AppFonts {
  /// Font tampilan: judul, angka, kata utama.
  static const String display = 'PlusJakartaSans';

  /// Font isi.
  static const String body = 'Inter';

  /// Font simbol fonetik (IPA).
  static const String ipa = 'NotoSans';
}

/// Skala tipografi dari design system.
///
/// Nilai mengikuti `src/assets/app.css` (mockup) dan bagian 4.3 dokumen
/// perancangan, lalu diselaraskan dengan ukuran yang benar-benar dipakai layar.
TextTheme appTextTheme(AppPalette p) {
  final base = Typography.material2021(platform: TargetPlatform.android).white;
  return base
      .copyWith(
        displayLarge: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 40,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
          color: p.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 33,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: p.textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 26,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: p.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 19,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: p.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: p.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 18,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 15,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: p.textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 15,
          height: 1.55,
          fontWeight: FontWeight.w400,
          color: p.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w400,
          color: p.textSoft,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11.5,
          height: 1.45,
          fontWeight: FontWeight.w400,
          color: p.textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: p.textSecondary,
        ),
        labelMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11.5,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: p.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 10.5,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.9,
          color: p.eyebrow,
        ),
      )
      .apply(
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
        fontFamily: AppFonts.body,
      );
}

/// Gaya teks khusus yang tidak masuk skala Material.
extension AppTextStyles on BuildContext {
  AppPalette get _p => palette;

  /// Label kecil huruf besar di atas judul ("KATA HARI INI").
  TextStyle get eyebrow => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 10.5,
    height: 1,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
    color: _p.eyebrow,
  );

  /// Kata utama (detail kata, kartu kata hari ini).
  TextStyle get wordTitle => TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 40,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    color: _p.textPrimary,
  );

  /// Transekap fonetik.
  TextStyle get ipaText => TextStyle(
    fontFamily: AppFonts.ipa,
    fontSize: 13,
    height: 1.3,
    letterSpacing: 0.2,
    color: _p.ipa,
  );

  /// Teks kecil pendukung.
  TextStyle get tiny => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 11.5,
    height: 1.45,
    color: _p.textDim,
  );

  /// Teks kecil yang lebih redup.
  TextStyle get small => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12.5,
    height: 1.5,
    color: _p.textSecondary,
  );
}
