import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Pengendali tema. Tema gelap adalah default produk.
///
/// Belum dipersistensikan; penyimpanan ke `shared_preferences` masuk fase
/// pengaturan (fase 10).
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void set(ThemeMode mode) => state = mode;

  void toggle() => state = switch (state) {
    ThemeMode.dark => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.system => ThemeMode.dark,
  };
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
