import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/user/user_database.dart';
import 'api_client.dart';
import 'sync_config.dart';

/// Hasil satu siklus sinkronisasi progres.
class SyncResult {
  const SyncResult({this.pushed = 0, this.pulled = 0, this.skipped = false});

  final int pushed;
  final int pulled;
  final bool skipped;

  bool get isEmpty => pushed == 0 && pulled == 0;
}

/// Push progres lokal ke server dan pull perubahan dari perangkat lain.
///
/// Dipanggil hanya saat aplikasi dibuka / setelah sesi belajar, bukan dari
/// halaman latihan. Kegagalan jaringan tidak mengganggu proses belajar.
class SyncService {
  SyncService(this._api, this._db, this._prefs);

  final ApiClient _api;
  final UserDatabase _db;
  final SharedPreferences _prefs;

  /// Buat/pulihkan akun server memakai kredensial akun lokal.
  /// Dipanggil sekali setelah login lokal berhasil.
  Future<void> ensureAccount({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final saved = _prefs.getString(SyncConfig.tokenKey);
    if (saved != null && saved.isNotEmpty) {
      _api.token = saved;
      return;
    }

    try {
      final data = await _api.post('/api/v1/user/auth/register', {
        'email': email,
        'display_name': displayName,
        'password': password,
      }) as Map<String, dynamic>;
      await _storeToken(data['access_token'] as String);
    } on ApiException catch (error) {
      if (error.statusCode != 409) rethrow;
      final data = await _api.post('/api/v1/user/auth/login', {
        'email': email,
        'password': password,
      }) as Map<String, dynamic>;
      await _storeToken(data['access_token'] as String);
    }
  }

  Future<void> _storeToken(String token) async {
    _api.token = token;
    await _prefs.setString(SyncConfig.tokenKey, token);
  }

  Future<SyncResult> syncProgress(int userId) async {
    if (_api.token == null || _api.token!.isEmpty) {
      return const SyncResult(skipped: true);
    }

    final changes = <Map<String, dynamic>>[];
    final words = await (_db.select(_db.userWords)
          ..where((row) => row.userId.equals(userId)))
        .get();
    for (final word in words) {
      if (word.syncState == 'synced') continue;
      changes.add({
        'client_id': 'uw_${word.vocabId}',
        'entity': 'user_word',
        'payload': {
          'vocab_id': word.vocabId,
          'status': word.status,
          'is_favorite': word.isFavorite,
          'repetitions': word.repetitions,
          'ease_factor': word.easeFactor,
          'interval_days': word.intervalDays,
          'due_at': word.dueAt?.toIso8601String(),
          'lapses': word.lapses,
          'correct_count': word.correctCount,
          'wrong_count': word.wrongCount,
          'first_seen_at': word.firstSeenAt?.toIso8601String(),
          'last_reviewed_at': word.lastReviewedAt?.toIso8601String(),
          'updated_at': word.updatedAt.toIso8601String(),
        },
        'updated_at': word.updatedAt.toIso8601String(),
      });
    }

    final reviews = await (_db.select(_db.reviewLogs)
          ..where((row) => row.userId.equals(userId)))
        .get();
    for (final log in reviews) {
      changes.add({
        'client_id': 'rl_${log.vocabId}_${log.reviewedAt.microsecondsSinceEpoch}',
        'entity': 'review_log',
        'payload': {
          'vocab_id': log.vocabId,
          'mode': log.mode,
          'quality': log.quality,
          'is_correct': log.isCorrect,
          'reviewed_at': log.reviewedAt.toIso8601String(),
        },
        'updated_at': log.reviewedAt.toIso8601String(),
      });
    }

    final days = await (_db.select(_db.dailyActivities)
          ..where((row) => row.userId.equals(userId)))
        .get();
    for (final day in days) {
      changes.add({
        'client_id': 'da_${day.day}',
        'entity': 'daily_activity',
        'payload': {
          'day': day.day,
          'words_learned': day.wordsLearned,
          'reviews_done': day.reviewsDone,
          'correct': day.correct,
          'wrong': day.wrong,
          'goal_met': day.goalMet,
        },
        'updated_at': '${day.day}T00:00:00Z',
      });
    }

    var pushed = 0;
    if (changes.isNotEmpty) {
      final response = await _api.post('/api/v1/sync/push', {'changes': changes})
          as Map<String, dynamic>;
      pushed = (response['applied'] as num?)?.toInt() ?? 0;
    }

    final lastSeq = _prefs.getInt(SyncConfig.lastSeqKey) ?? 0;
    final pulled = await _api.get('/api/v1/sync/pull?since_seq=$lastSeq')
        as Map<String, dynamic>;
    var applied = 0;
    for (final item in (pulled['changes'] as List? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      if (await _applyChange(item, userId)) applied++;
    }
    final serverSeq = (pulled['server_seq'] as num?)?.toInt() ?? lastSeq;
    if (serverSeq > lastSeq) {
      await _prefs.setInt(SyncConfig.lastSeqKey, serverSeq);
    }

    for (final word in words) {
      if (word.syncState == 'synced') continue;
      await (_db.update(_db.userWords)
            ..where((row) => row.userId.equals(userId))
            ..where((row) => row.vocabId.equals(word.vocabId)))
          .write(UserWordsCompanion(syncState: Value('synced')));
    }

    return SyncResult(pushed: pushed, pulled: applied);
  }

  /// Terapkan perubahan dari perangkat lain. Mengembalikan true bila dipakai.
  Future<bool> _applyChange(Map<String, dynamic> change, int userId) async {
    final entity = change['entity'] as String?;
    final payload = change['payload'];
    if (payload is! Map<String, dynamic>) return false;

    if (entity == 'user_word') {
      final vocabId = (payload['vocab_id'] as num?)?.toInt();
      if (vocabId == null) return false;
      await _db.into(_db.userWords).insertOnConflictUpdate(UserWordsCompanion(
            userId: Value(userId),
            vocabId: Value(vocabId),
            status: Value(payload['status']?.toString() ?? 'new'),
            isFavorite: Value(payload['is_favorite'] as bool? ?? false),
            repetitions: Value((payload['repetitions'] as num?)?.toInt() ?? 0),
            easeFactor: Value((payload['ease_factor'] as num?)?.toDouble() ?? 2.5),
            intervalDays: Value((payload['interval_days'] as num?)?.toInt() ?? 0),
            dueAt: Value(_date(payload['due_at'])),
            lapses: Value((payload['lapses'] as num?)?.toInt() ?? 0),
            correctCount: Value((payload['correct_count'] as num?)?.toInt() ?? 0),
            wrongCount: Value((payload['wrong_count'] as num?)?.toInt() ?? 0),
            firstSeenAt: Value(_date(payload['first_seen_at'])),
            lastReviewedAt: Value(_date(payload['last_reviewed_at'])),
            updatedAt: Value(_date(payload['updated_at']) ?? DateTime.now()),
            syncState: const Value('synced'),
          ));
      return true;
    }

    if (entity == 'daily_activity') {
      final day = payload['day'] as String?;
      if (day == null) return false;
      await _db.into(_db.dailyActivities).insertOnConflictUpdate(DailyActivitiesCompanion(
            userId: Value(userId),
            day: Value(day),
            wordsLearned: Value((payload['words_learned'] as num?)?.toInt() ?? 0),
            reviewsDone: Value((payload['reviews_done'] as num?)?.toInt() ?? 0),
            correct: Value((payload['correct'] as num?)?.toInt() ?? 0),
            wrong: Value((payload['wrong'] as num?)?.toInt() ?? 0),
            goalMet: Value(payload['goal_met'] as bool? ?? false),
          ));
      return true;
    }

    if (entity == 'review_log') {
      final vocabId = (payload['vocab_id'] as num?)?.toInt();
      final reviewedAt = _date(payload['reviewed_at']);
      if (vocabId == null || reviewedAt == null) return false;

      // client_id memakai vocab_id + reviewedAt, jadi kombinasi ini unik.
      final existing = await (_db.select(_db.reviewLogs)
            ..where((row) => row.userId.equals(userId))
            ..where((row) => row.vocabId.equals(vocabId))
            ..where((row) => row.reviewedAt.equals(reviewedAt)))
          .get();
      if (existing.isNotEmpty) return false;

      await _db.into(_db.reviewLogs).insert(ReviewLogsCompanion.insert(
            userId: Value(userId),
            vocabId: vocabId,
            mode: payload['mode']?.toString() ?? 'quiz',
            quality: (payload['quality'] as num?)?.toInt() ?? 0,
            isCorrect: payload['is_correct'] as bool? ?? false,
            reviewedAt: reviewedAt,
          ));
      return true;
    }

    return false;
  }

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  /// Hapus token saat pengguna keluar.
  Future<void> clearSession() async {
    _api.token = null;
    await _prefs.remove(SyncConfig.tokenKey);
    await _prefs.setInt(SyncConfig.lastSeqKey, 0);
  }

}
