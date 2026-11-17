import 'package:material_ui/material_ui.dart';

import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema Wordly: gelap sebagai tema utama, terang sebagai alternatif.
abstract final class AppTheme {
  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData light() => _build(AppPalette.light);

  static ThemeData _build(AppPalette p) {
    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primarySoft,
      onPrimaryContainer: p.primaryText,
      secondary: p.accent,
      onSecondary: p.onPrimary,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.accentText,
      tertiary: p.success,
      onTertiary: p.onPrimary,
      error: p.error,
      onError: p.onPrimary,
      surface: p.surface,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.surfaceElevated,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      fontFamily: AppFonts.body,
      textTheme: appTextTheme(p),
      extensions: <ThemeExtension<dynamic>>[p],
      splashFactory: InkSparkle.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: p.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: p.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: p.textPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceElevated,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          color: p.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primarySoft : p.track,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primarySoft,
        selectionHandleColor: p.primary,
      ),
    );
  }
}
