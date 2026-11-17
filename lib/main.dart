import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/router.dart';
import 'core/db/database_providers.dart';
import 'core/db/user/user_database.dart';
import 'core/notifications/notification_service.dart';
import 'core/settings/app_settings.dart';
import 'core/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databases = await bootstrapDatabases();
  final prefs = await SharedPreferences.getInstance();
  final notifications = await NotificationService.create(
    onSelect: (route) => appRouter.push(route),
  );

  // Jadwalkan ulang pengingat harian (setelah restart/update) dengan teks yang
  // menyebut jumlah kata jatuh tempo saat ini.
  final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
  if (notificationsEnabled) {
    final userId = prefs.getInt('session_user_id') ?? guestUserId;
    final due = await databases.user.countDue(userId, DateTime.now());
    await notifications.scheduleDaily(
      minutes: prefs.getInt('notification_time') ?? AppSettings.defaults.notificationMinutes,
      body: due > 0 ? '$due kata menunggu diulang hari ini.' : SettingsController.reminderBody,
    );
  }

  // Dibuka dari notifikasi saat aplikasi belum berjalan.
  final initialRoute = await notifications.initialRoute();

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

  if (initialRoute != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => appRouter.push(initialRoute));
  }
}
