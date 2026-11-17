import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wordly/app/app.dart';
import 'package:wordly/core/design/app_palette.dart';
import 'package:wordly/features/settings/presentation/theme_controller.dart';

void main() {
  testWidgets('tema berpindah ke terang saat di-toggle', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WordlyApp()),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffold).brightness, Brightness.dark);
    expect(scaffold.palette.bg, AppPalette.dark.bg);

    container.read(themeModeProvider.notifier).toggle();
    await tester.pumpAndSettle();

    final scaffoldAfter = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffoldAfter).brightness, Brightness.light);
    expect(scaffoldAfter.palette.bg, AppPalette.light.bg);
  });
}
