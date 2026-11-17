import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordly/app/app.dart';
import 'package:wordly/core/design/app_palette.dart';
import 'package:wordly/core/settings/settings_controller.dart';

void main() {
  testWidgets('tema berpindah ke terang saat di-toggle', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WordlyApp()),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffold).brightness, Brightness.dark);
    expect(scaffold.palette.bg, AppPalette.dark.bg);

    await container.read(settingsProvider.notifier).toggleTheme();
    await tester.pumpAndSettle();

    final scaffoldAfter = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffoldAfter).brightness, Brightness.light);
    expect(scaffoldAfter.palette.bg, AppPalette.light.bg);
  });

  testWidgets('pengaturan tersimpan ke shared_preferences', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final controller = container.read(settingsProvider.notifier);
    await controller.setDailyGoal(20);
    await controller.setLevel('advanced');
    await controller.setTextScale(1.15);

    expect(prefs.getInt('daily_goal'), 20);
    expect(prefs.getString('learning_level'), 'advanced');
    expect(prefs.getDouble('text_scale'), 1.15);
  });
}
