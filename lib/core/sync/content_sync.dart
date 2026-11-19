import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/content/content_database.dart';
import 'api_client.dart';
import 'sync_config.dart';

/// Hasil pengecekan konten terbaru dari admin.
class ContentSyncResult {
  const ContentSyncResult({
    required this.updated,
    required this.version,
    required this.words,
  });

  final bool updated;
  final int version;
  final int words;
}

/// Menarik perubahan kosakata dari panel admin ke `vocab.db`.
///
/// ID kata asli dipertahankan sehingga progres pengguna tidak yatim. Aset
/// tetap menjadi fallback offline bila server tidak tersedia.
class ContentSync {
  ContentSync(this._api, this._db, this._prefs);

  final ApiClient _api;
  final ContentDatabase _db;
  final SharedPreferences _prefs;

  Future<ContentSyncResult> syncIfNewer() async {
    final manifest = await _api.get('/api/v1/content/manifest') as Map<String, dynamic>;
    final version = (manifest['version'] as num?)?.toInt() ?? 0;
    final stored = _prefs.getInt(SyncConfig.contentVersionKey) ?? 0;
    if (version <= stored) {
      return ContentSyncResult(updated: false, version: version, words: 0);
    }

    final delta = await _api.get('/api/v1/content/delta?since=$stored')
        as Map<String, dynamic>;

    for (final item in (delta['categories'] as List? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      await _db.into(_db.categories).insertOnConflictUpdate(CategoriesCompanion(
            id: Value((item['id'] as num?)?.toInt() ?? 0),
            slug: Value(item['slug']?.toString() ?? ''),
            name: Value(item['name']?.toString() ?? ''),
            description: Value(item['description']?.toString() ?? ''),
            icon: Value(item['icon']?.toString()),
            sortOrder: Value((item['order'] as num?)?.toInt() ?? 0),
          ));
    }

    var count = 0;
    for (final item in (delta['upserts'] as List? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      final word = item['word']?.toString() ?? '';
      if (word.isEmpty) continue;
      await _db.into(_db.vocabularies).insertOnConflictUpdate(VocabulariesCompanion(
            id: Value((item['id'] as num?)?.toInt() ?? 0),
            word: Value(word),
            wordNormalized: Value(word.toLowerCase()),
            translation: Value(item['translation']?.toString() ?? ''),
            definition: Value(item['definition']?.toString() ?? ''),
            pronunciationIpa: Value(item['ipa']?.toString()),
            partOfSpeech: Value(item['pos']?.toString() ?? ''),
            difficultyLevel: Value(item['level']?.toString() ?? 'beginner'),
            cefr: Value(item['cefr']?.toString()),
            categoryId: Value((item['category_id'] as num?)?.toInt() ?? 0),
            exampleSentence: Value(item['example']?.toString() ?? ''),
            exampleTranslation: Value(item['example_id']?.toString() ?? ''),
            synonyms: Value(jsonEncode(item['synonyms'] ?? const <String>[])),
            antonyms: Value(jsonEncode(item['antonyms'] ?? const <String>[])),
            audioUrl: Value(item['audio']?.toString()),
            createdAt: Value(_createdAt(item)),
          ));
      count++;
    }

    await _prefs.setInt(SyncConfig.contentVersionKey, version);
    return ContentSyncResult(updated: true, version: version, words: count);
  }

  static String _createdAt(Map<String, dynamic> item) {
    final raw = item['created_at']?.toString();
    if (raw != null && DateTime.tryParse(raw) != null) return raw;
    return DateTime.now().toIso8601String();
  }
}
