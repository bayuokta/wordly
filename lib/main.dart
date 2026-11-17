import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/db/database_providers.dart';
import 'core/notifications/notification_service.dart';
import 'core/settings/app_settings.dart';
import 'core/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databases = await bootstrapDatabases();
  final prefs = await SharedPreferences.getInstance();
  final notifications = await NotificationService.create();

  // Jadwalkan ulang pengingat harian (mis. setelah ponsel restart atau update).
  final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
  if (notificationsEnabled) {
    await notifications.scheduleDaily(
      minutes: prefs.getInt('notification_time') ?? AppSettings.defaults.notificationMinutes,
      body: SettingsController.reminderBody,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        contentDbProvider.overrideWithValue(databases.content),
        userDbProvider.overrideWithValue(databases.user),
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const WordlyApp(),
    ),
  );
}
