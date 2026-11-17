import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/design/app_theme.dart';
import '../core/settings/settings_controller.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import 'router.dart';

class WordlyApp extends ConsumerWidget {
  const WordlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Belum onboarding: tampilkan layar perkenalan dulu, tanpa router.
    if (!settings.onboardingDone) {
      return MaterialApp(
        title: 'Wordly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settings.themeMode,
        builder: (context, child) => _scaled(context, child, settings.textScale),
        home: const OnboardingPage(),
      );
    }

    return MaterialApp.router(
      title: 'Wordly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: appRouter,
      builder: (context, child) => _scaled(context, child, settings.textScale),
    );
  }

  /// Menerapkan ukuran teks pilihan pengguna (0.85–1.3).
  Widget _scaled(BuildContext context, Widget? child, double scale) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(scale)),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
