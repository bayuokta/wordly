import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../auth/session_controller.dart';
import 'content_sync.dart';
import 'sync_service.dart';

/// Menjalankan sinkronisasi di latar belakang, tanpa memblokir alur belajar.
class SyncCoordinator {
  SyncCoordinator(this._prefs, this._sync, this._content);

  static const _lastRunKey = 'sync_last_run';
  static const _minInterval = Duration(seconds: 60);

  final SharedPreferences _prefs;
  final SyncService _sync;
  final ContentSync _content;

  Future<void> start(SessionState session) async {
    // Tamu tidak memiliki akun server; tidak ada data untuk disinkronkan.
    if (session.isGuest || !session.signedIn) return;

    final last = _prefs.getInt(_lastRunKey) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - last <
        _minInterval.inMilliseconds) {
      return;
    }
    await _prefs.setInt(_lastRunKey, DateTime.now().millisecondsSinceEpoch);

    try {
      final content = await _content.syncIfNewer();
      if (content.updated) {
        developer.log(
          'Konten diperbarui: ${content.words} kata (v${content.version})',
          name: 'wordly.sync',
        );
      }
    } on Object catch (error) {
      developer.log('Gagal menarik konten', name: 'wordly.sync', error: error);
    }

    try {
      final progress = await _sync.syncProgress(session.userId);
      if (!progress.isEmpty) {
        developer.log(
          'Sinkronisasi progres: ${progress.pushed} terkirim, ${progress.pulled} diterima',
          name: 'wordly.sync',
        );
      }
    } on Object catch (error) {
      developer.log('Gagal menyinkronkan progres', name: 'wordly.sync', error: error);
    }
  }
}
