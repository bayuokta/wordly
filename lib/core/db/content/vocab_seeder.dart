import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content_database.dart';

/// Membaca `assets/vocab/*.json` dan mengisi `vocab.db`.
///
/// Versi konten dihitung dari isi berkas (nama + versi + jumlah kata). Bila
/// berbeda dengan yang tersimpan di `shared_preferences`, konten diimpor ulang.
class VocabSeeder {
  VocabSeeder({required this.db, AssetBundle? bundle, SharedPreferences? prefs})
    : _bundle = bundle ?? rootBundle {
    _prefs = prefs;
  }

  static const String _prefsKey = 'vocab_content_signature';
  static const String _assetPrefix = 'assets/vocab/';

  final ContentDatabase db;
  final AssetBundle _bundle;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Mengembalikan `true` bila konten baru saja diimpor.
  Future<bool> seedIfNeeded() async {
    final files = await _contentFiles();
    if (files.isEmpty) return false;

    final decoded = <String, Map<String, dynamic>>{};
    for (final path in files) {
      final raw = await _bundle.loadString(path);
      decoded[path] = jsonDecode(raw) as Map<String, dynamic>;
    }

    final signature = files
        .map((path) {
          final data = decoded[path]!;
          final words = data['words'] as List<dynamic>? ?? const [];
          return '$path:${data['version']}:${words.length}';
        })
        .join('|');

    final prefs = await _preferences;
    final stored = prefs.getString(_prefsKey);
    final hasContent = await db.vocabularyCount() > 0;

    if (stored == signature && hasContent) return false;

    await _import(decoded);
    await prefs.setString(_prefsKey, signature);
    return true;
  }

  Future<List<String>> _contentFiles() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
      final assets = manifest.listAssets().where(
        (path) => path.startsWith(_assetPrefix) && path.endsWith('.json'),
      );
      return assets.toList()..sort();
    } on Object {
      // Fallback bila manifest tidak tersedia (mis. pada unit test).
      return const [];
    }
  }

  Future<void> _import(Map<String, Map<String, dynamic>> files) async {
    final categories = <CategoriesCompanion>[];
    final words = <VocabulariesCompanion>[];
    final seenIds = <int>{};

    for (final data in files.values) {
      final category = data['category'] as Map<String, dynamic>;
      final categoryId = category['id'] as int;

      categories.add(
        CategoriesCompanion.insert(
          id: Value(categoryId),
          slug: category['slug'] as String,
          name: category['name'] as String,
          description: category['description'] as String,
          icon: Value(category['icon'] as String?),
          sortOrder: Value((category['order'] as int?) ?? categoryId),
        ),
      );

      for (final word in (data['words'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        final id = word['id'] as int;
        if (!seenIds.add(id)) {
          throw FormatException('ID kata ganda: $id');
        }
        words.add(
          VocabulariesCompanion.insert(
            id: Value(id),
            word: word['word'] as String,
            wordNormalized: (word['word'] as String).toLowerCase(),
            translation: word['translation'] as String,
            definition: word['definition'] as String,
            pronunciationIpa: Value(word['ipa'] as String?),
            partOfSpeech: word['pos'] as String,
            difficultyLevel: word['level'] as String,
            cefr: Value(word['cefr'] as String?),
            categoryId: categoryId,
            exampleSentence: word['example'] as String,
            exampleTranslation: word['example_id'] as String,
            synonyms: Value(jsonEncode(word['synonyms'] ?? const <String>[])),
            antonyms: Value(jsonEncode(word['antonyms'] ?? const <String>[])),
            audioUrl: Value(word['audio'] as String?),
            createdAt: (word['created_at'] as String?) ?? DateTime.now().toIso8601String(),
          ),
        );
      }
    }

    await db.clearContent();
    await db.insertContent(categoryRows: categories, vocabularyRows: words);
  }
}
