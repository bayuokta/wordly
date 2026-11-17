import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/auth/session_controller.dart';
import '../core/design/app_palette.dart';
import '../core/design/app_theme.dart';
import '../core/settings/settings_controller.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import 'router.dart';

class WordlyApp extends ConsumerWidget {
  const WordlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final session = ref.watch(sessionProvider);

    return MaterialApp.router(
      title: 'Wordly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(settings.textScale)),
          child: _gate(child, settings.onboardingDone, session),
        );
      },

    );
  }

  /// Urutan gerbang: onboarding → akun/tamu → aplikasi.
  Widget _gate(Widget? child, bool onboardingDone, SessionState session) {
    if (!onboardingDone) return const OnboardingPage();
    if (session.isInitializing) return const _SessionLoading();
    if (!session.signedIn && !session.isGuest) return const AuthPage();
    return child ?? const SizedBox.shrink();
  }
}

class _SessionLoading extends StatelessWidget {
  const _SessionLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: context.palette.primary),
      ),
    );
  }
}
