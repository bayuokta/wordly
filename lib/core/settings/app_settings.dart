import 'package:material_ui/material_ui.dart' show ThemeMode, immutable;

/// Preferensi pengguna yang dipakai lintas fitur.
@immutable
class AppSettings {
  const AppSettings({
    required this.level,
    required this.dailyGoal,
    required this.textScale,
    required this.themeMode,
    required this.onboardingDone,
    required this.audioAutoplay,
  });

  /// `beginner` | `intermediate` | `advanced`.
  final String level;
  final int dailyGoal;

  /// Faktor ukuran teks: 0.85 / 1.0 / 1.15 / 1.3.
  final double textScale;
  final ThemeMode themeMode;
  final bool onboardingDone;
  final bool audioAutoplay;

  static const AppSettings defaults = AppSettings(
    level: 'intermediate',
    dailyGoal: 10,
    textScale: 1,
    themeMode: ThemeMode.dark,
    onboardingDone: false,
    audioAutoplay: false,
  );

  static const List<int> goalOptions = [5, 10, 20];
  static const List<double> textScaleOptions = [0.85, 1, 1.15, 1.3];
  static const List<String> levelOptions = ['beginner', 'intermediate', 'advanced'];

  String get levelLabel => switch (level) {
    'beginner' => 'Pemula',
    'advanced' => 'Mahir',
    _ => 'Menengah',
  };

  String get levelDetail => switch (level) {
    'beginner' => 'A1–A2',
    'advanced' => 'C1–C2',
    _ => 'B1–B2',
  };

  String get textScaleLabel => switch (textScale) {
    0.85 => 'Kecil',
    1.15 => 'Besar',
    1.3 => 'Sangat besar',
    _ => 'Normal',
  };

  AppSettings copyWith({
    String? level,
    int? dailyGoal,
    double? textScale,
    ThemeMode? themeMode,
    bool? onboardingDone,
    bool? audioAutoplay,
  }) {
    return AppSettings(
      level: level ?? this.level,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      textScale: textScale ?? this.textScale,
      themeMode: themeMode ?? this.themeMode,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      audioAutoplay: audioAutoplay ?? this.audioAutoplay,
    );
  }
}
