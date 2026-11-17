import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/db/database_providers.dart';
import 'core/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databases = await bootstrapDatabases();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        contentDbProvider.overrideWithValue(databases.content),
        userDbProvider.overrideWithValue(databases.user),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const WordlyApp(),
    ),
  );
}
