import 'package:material_ui/material_ui.dart';

/// Token warna Wordly.
///
/// Sumber kebenaran: `src/assets/app.css` (mockup). Semua warna yang dipakai UI
/// harus berasal dari sini — jangan menulis `Color(0x...)` langsung di widget.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSoft,
    required this.textSecondary,
    required this.textDim,
    required this.eyebrow,
    required this.ipa,
    required this.chevron,
    required this.statusForeground,
    required this.iconSoft,
    required this.track,
    required this.divider,
    required this.fieldBg,
    required this.chipBg,
    required this.chipBorder,
    required this.ghostBg,
    required this.navBg,
    required this.navBorder,
    required this.navInactive,
    required this.quoteBg,
    required this.tabOnBg,
    required this.tabOnLine,
    required this.heroGradient,
    required this.heroBorder,
    required this.heroGlow,
    required this.flashGradient,
    required this.flashBorder,
    required this.brandGradient,
    required this.avatarGradient,
    required this.cardShadow,
    required this.primarySoft,
    required this.primaryLine,
    required this.primaryText,
    required this.accentSoft,
    required this.accentLine,
    required this.accentText,
    required this.successSoft,
    required this.successLine,
    required this.successText,
    required this.warningSoft,
    required this.warningLine,
    required this.warningText,
    required this.errorSoft,
    required this.errorLine,
    required this.errorText,
  });

  final Brightness brightness;

  final Color bg;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color textPrimary;
  final Color textSoft;
  final Color textSecondary;
  final Color textDim;
  final Color eyebrow;
  final Color ipa;
  final Color chevron;
  final Color statusForeground;
  final Color iconSoft;
  final Color track;
  final Color divider;
  final Color fieldBg;
  final Color chipBg;
  final Color chipBorder;
  final Color ghostBg;
  final Color navBg;
  final Color navBorder;
  final Color navInactive;
  final Color quoteBg;
  final Color tabOnBg;
  final Color tabOnLine;

  /// Panel "kata hari ini" dan kartu flashcard.
  final LinearGradient heroGradient;
  final Color heroBorder;
  final Color heroGlow;
  final LinearGradient flashGradient;
  final Color flashBorder;

  /// Logo & avatar.
  final LinearGradient brandGradient;
  final LinearGradient avatarGradient;

  final List<BoxShadow> cardShadow;

  final Color primarySoft;
  final Color primaryLine;
  final Color primaryText;
  final Color accentSoft;
  final Color accentLine;
  final Color accentText;
  final Color successSoft;
  final Color successLine;
  final Color successText;
  final Color warningSoft;
  final Color warningLine;
  final Color warningText;
  final Color errorSoft;
  final Color errorLine;
  final Color errorText;

  bool get isDark => brightness == Brightness.dark;

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0E1116),
    surface: Color(0xFF171B22),
    surfaceElevated: Color(0xFF1F2430),
    border: Color(0xFF2A3040),
    primary: Color(0xFF7C9CFF),
    onPrimary: Color(0xFF0A0E18),
    accent: Color(0xFFF2C46D),
    success: Color(0xFF4FD1A1),
    warning: Color(0xFFF5A25D),
    error: Color(0xFFF27C8D),
    textPrimary: Color(0xFFF2F4F8),
    textSoft: Color(0xFFD9DFEC),
    textSecondary: Color(0xFF9AA3B5),
    textDim: Color(0xFF6C778E),
    eyebrow: Color(0xFF7E89A0),
    ipa: Color(0xFFAEB8CC),
    chevron: Color(0xFF5C667A),
    statusForeground: Color(0xFFE7EAF2),
    iconSoft: Color(0xFFC3CAD8),
    track: Color(0xFF262D3C),
    divider: Color(0xBF2A3040),
    fieldBg: Color(0xFF12161E),
    chipBg: Color(0xFF1F2430),
    chipBorder: Color(0xFF2A3040),
    ghostBg: Color(0xB81F2430),
    navBg: Color(0xF70E1116),
    navBorder: Color(0xD92A3040),
    navInactive: Color(0xFF6C778E),
    quoteBg: Color(0xFF141922),
    tabOnBg: Color(0xFF232A38),
    tabOnLine: Color(0xFF333C50),
    heroGradient: LinearGradient(
      begin: Alignment(0.7, -1),
      end: Alignment(-0.3, 1),
      colors: [Color(0xFF202736), Color(0xFF171B22)],
      stops: [0, 0.72],
    ),
    heroBorder: Color(0xFF303A50),
    heroGlow: Color(0x3D7C9CFF),
    flashGradient: LinearGradient(
      begin: Alignment(-0.6, -1),
      end: Alignment(0.4, 1),
      colors: [Color(0xFF1D2432), Color(0xFF171B22)],
      stops: [0, 0.75],
    ),
    flashBorder: Color(0xFF313B52),
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF93ACFF), Color(0xFF7C9CFF), Color(0xFF5F7FE6)],
    ),
    avatarGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFA9BDFF), Color(0xFF7C9CFF), Color(0xFF6C8BF0)],
    ),
    cardShadow: <BoxShadow>[],
    primarySoft: Color(0x217C9CFF),
    primaryLine: Color(0x527C9CFF),
    primaryText: Color(0xFFCBD7FF),
    accentSoft: Color(0x1FF2C46D),
    accentLine: Color(0x47F2C46D),
    accentText: Color(0xFFF6D494),
    successSoft: Color(0x1F4FD1A1),
    successLine: Color(0x4D4FD1A1),
    successText: Color(0xFF8FE7C6),
    warningSoft: Color(0x1FF5A25D),
    warningLine: Color(0x4DF5A25D),
    warningText: Color(0xFFF8BD88),
    errorSoft: Color(0x1FF27C8D),
    errorLine: Color(0x4DF27C8D),
    errorText: Color(0xFFF6A3AE),
  );

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF7F8FB),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF0F3F9),
    border: Color(0xFFE3E7EF),
    primary: Color(0xFF4A6BE0),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFD99A2B),
    success: Color(0xFF168A63),
    warning: Color(0xFFB4691C),
    error: Color(0xFFC64258),
    textPrimary: Color(0xFF151922),
    textSoft: Color(0xFF2C3342),
    textSecondary: Color(0xFF5C6578),
    textDim: Color(0xFF6A7386),
    eyebrow: Color(0xFF6E7789),
    ipa: Color(0xFF5C6578),
    chevron: Color(0xFF9AA3B5),
    statusForeground: Color(0xFF151922),
    iconSoft: Color(0xFF4E5A70),
    track: Color(0xFFE7EBF3),
    divider: Color(0xFFE8ECF3),
    fieldBg: Color(0xFFF1F4FA),
    chipBg: Color(0xFFF2F5FA),
    chipBorder: Color(0xFFE1E5EE),
    ghostBg: Color(0xFFF2F5FA),
    navBg: Color(0xF7F7F8FB),
    navBorder: Color(0xFFE3E7EF),
    navInactive: Color(0xFF5C6578),
    quoteBg: Color(0xFFF5F7FC),
    tabOnBg: Color(0xFFFFFFFF),
    tabOnLine: Color(0xFFDCE3F0),
    heroGradient: LinearGradient(
      begin: Alignment(0.7, -1),
      end: Alignment(-0.3, 1),
      colors: [Color(0xFFF3F6FF), Color(0xFFFFFFFF)],
      stops: [0, 0.72],
    ),
    heroBorder: Color(0xFFD8E0F5),
    heroGlow: Color(0x294A6BE0),
    flashGradient: LinearGradient(
      begin: Alignment(-0.6, -1),
      end: Alignment(0.4, 1),
      colors: [Color(0xFFF2F6FF), Color(0xFFFFFFFF)],
      stops: [0, 0.75],
    ),
    flashBorder: Color(0xFFD8E0F5),
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7C96FF), Color(0xFF4A6BE0), Color(0xFF3C59C2)],
    ),
    avatarGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8CA4FF), Color(0xFF4A6BE0), Color(0xFF3C59C2)],
    ),
    cardShadow: [
      BoxShadow(color: Color(0x0D151922), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x2E151922), offset: Offset(0, 10), blurRadius: 24, spreadRadius: -16),
    ],
    primarySoft: Color(0x144A6BE0),
    primaryLine: Color(0x424A6BE0),
    primaryText: Color(0xFF3A5BD0),
    accentSoft: Color(0x1AD99A2B),
    accentLine: Color(0x57D99A2B),
    accentText: Color(0xFF8A5A0E),
    successSoft: Color(0x17168A63),
    successLine: Color(0x52168A63),
    successText: Color(0xFF147355),
    warningSoft: Color(0x17B4691C),
    warningLine: Color(0x52B4691C),
    warningText: Color(0xFF97560F),
    errorSoft: Color(0x17C64258),
    errorLine: Color(0x52C64258),
    errorText: Color(0xFFB03A4E),
  );

  /// Pergantian tema bersifat instan (tanpa animasi), jadi lerp cukup memilih
  /// palet terdekat.
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }

  @override
  AppPalette copyWith({Brightness? brightness}) => this;
}

/// Akses cepat: `context.palette.primary`.
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
