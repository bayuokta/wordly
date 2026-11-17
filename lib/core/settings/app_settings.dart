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
    required this.notificationsEnabled,
    required this.notificationMinutes,
    required this.audioSpeed,
    required this.soundEffects,
  });

  /// `beginner` | `intermediate` | `advanced`.
  final String level;
  final int dailyGoal;

  /// Faktor ukuran teks: 0.85 / 1.0 / 1.15 / 1.3.
  final double textScale;
  final ThemeMode themeMode;
  final bool onboardingDone;
  final bool audioAutoplay;

  /// Pengingat harian (jam disimpan sebagai menit sejak tengah malam).
  final bool notificationsEnabled;
  final int notificationMinutes;

  /// Pengali kecepatan TTS: 0.75 atau 1.0.
  final double audioSpeed;

  /// Efek suara benar/salah saat latihan.
  final bool soundEffects;

  static const AppSettings defaults = AppSettings(
    level: 'intermediate',
    dailyGoal: 10,
    textScale: 1,
    themeMode: ThemeMode.dark,
    onboardingDone: false,
    audioAutoplay: false,
    notificationsEnabled: false,
    notificationMinutes: 19 * 60,
    audioSpeed: 1,
    soundEffects: false,
  );

  /// Contoh: `19:00`.
  String get notificationTimeLabel {
    final hour = (notificationMinutes ~/ 60).toString().padLeft(2, '0');
    final minute = (notificationMinutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static const List<int> goalOptions = [5, 10, 20];
  static const List<double> textScaleOptions = [0.85, 1, 1.15, 1.3];
  static const List<double> audioSpeedOptions = [0.75, 1];
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

  String get audioSpeedLabel => audioSpeed < 1 ? '0,75x' : '1x';

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
    bool? notificationsEnabled,
    int? notificationMinutes,
    double? audioSpeed,
    bool? soundEffects,
  }) {
    return AppSettings(
      level: level ?? this.level,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      textScale: textScale ?? this.textScale,
      themeMode: themeMode ?? this.themeMode,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      audioAutoplay: audioAutoplay ?? this.audioAutoplay,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationMinutes: notificationMinutes ?? this.notificationMinutes,
      audioSpeed: audioSpeed ?? this.audioSpeed,
      soundEffects: soundEffects ?? this.soundEffects,
    );
  }
}
