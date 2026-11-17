import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/notification_service.dart';
import 'app_settings.dart';

/// Diisi di `main()` lewat override; agar pengaturan bisa dibaca sinkron.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('SharedPreferences belum di-bootstrap'),
);

class SettingsController extends Notifier<AppSettings> {
  static const _kLevel = 'learning_level';
  static const _kGoal = 'daily_goal';
  static const _kTextScale = 'text_scale';
  static const _kTheme = 'theme_mode';
  static const _kOnboarding = 'onboarding_done';
  static const _kAutoplay = 'audio_autoplay';
  static const _kNotifEnabled = 'notifications_enabled';
  static const _kNotifMinutes = 'notification_time';

  static const String reminderBody =
      'Luangkan beberapa menit untuk mengulang kosakata hari ini.';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = _prefs;
    return AppSettings(
      level: prefs.getString(_kLevel) ?? AppSettings.defaults.level,
      dailyGoal: prefs.getInt(_kGoal) ?? AppSettings.defaults.dailyGoal,
      textScale: prefs.getDouble(_kTextScale) ?? AppSettings.defaults.textScale,
      themeMode: switch (prefs.getString(_kTheme)) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      },
      onboardingDone: prefs.getBool(_kOnboarding) ?? false,
      audioAutoplay: prefs.getBool(_kAutoplay) ?? false,
      notificationsEnabled: prefs.getBool(_kNotifEnabled) ?? false,
      notificationMinutes: prefs.getInt(_kNotifMinutes) ?? AppSettings.defaults.notificationMinutes,
    );
  }

  Future<void> setLevel(String level) async {
    state = state.copyWith(level: level);
    await _prefs.setString(_kLevel, level);
  }

  Future<void> setDailyGoal(int goal) async {
    state = state.copyWith(dailyGoal: goal);
    await _prefs.setInt(_kGoal, goal);
  }

  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale);
    await _prefs.setDouble(_kTextScale, scale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_kTheme, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    });
  }

  Future<void> toggleTheme() => setThemeMode(
    state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
  );

  Future<void> setAudioAutoplay({required bool enabled}) async {
    state = state.copyWith(audioAutoplay: enabled);
    await _prefs.setBool(_kAutoplay, enabled);
  }

  /// Mengaktifkan/mematikan pengingat harian.
  ///
  /// Mengembalikan `false` bila izin notifikasi ditolak perangkat.
  Future<bool> setNotificationsEnabled({required bool enabled, String? body}) async {
    final service = ref.read(notificationServiceProvider);

    if (enabled) {
      final granted = await service.requestPermission();
      if (!granted) return false;
      await service.scheduleDaily(
        minutes: state.notificationMinutes,
        body: body ?? reminderBody,
      );
      await service.showTest();
    } else {
      await service.cancelDaily();
    }

    state = state.copyWith(notificationsEnabled: enabled);
    await _prefs.setBool(_kNotifEnabled, enabled);
    return true;
  }

  Future<void> setNotificationTime(int minutes) async {
    state = state.copyWith(notificationMinutes: minutes);
    await _prefs.setInt(_kNotifMinutes, minutes);
    if (state.notificationsEnabled) {
      await ref.read(notificationServiceProvider).scheduleDaily(
        minutes: minutes,
        body: reminderBody,
      );
    }
  }

  /// Dipanggil saat onboarding selesai, sekaligus menyimpan level & target.
  Future<void> completeOnboarding({required String level, required int goal}) async {
    state = state.copyWith(level: level, dailyGoal: goal, onboardingDone: true);
    await _prefs.setString(_kLevel, level);
    await _prefs.setInt(_kGoal, goal);
    await _prefs.setBool(_kOnboarding, true);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
