import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_providers.dart';
import '../settings/settings_controller.dart';
import 'api_client.dart';
import 'content_sync.dart';
import 'sync_coordinator.dart';
import 'sync_service.dart';
import 'server_settings.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiClient(baseUrl: ServerSettings.current(prefs));
});

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(
      ref.watch(apiClientProvider),
      ref.watch(userDbProvider),
      ref.watch(sharedPreferencesProvider),
    ));

final contentSyncProvider = Provider<ContentSync>((ref) => ContentSync(
      ref.watch(apiClientProvider),
      ref.watch(contentDbProvider),
      ref.watch(sharedPreferencesProvider),
    ));

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) => SyncCoordinator(
      ref.watch(sharedPreferencesProvider),
      ref.watch(syncServiceProvider),
      ref.watch(contentSyncProvider),
    ));
