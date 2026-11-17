import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/db/database_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databases = await bootstrapDatabases();

  runApp(
    ProviderScope(
      overrides: [
        contentDbProvider.overrideWithValue(databases.content),
        userDbProvider.overrideWithValue(databases.user),
      ],
      child: const WordlyApp(),
    ),
  );
}
