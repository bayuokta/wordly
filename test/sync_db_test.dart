import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordly/core/db/content/content_database.dart';
import 'package:wordly/core/db/user/user_database.dart';
import 'package:wordly/core/sync/api_client.dart';
import 'package:wordly/core/sync/sync_config.dart';
import 'package:wordly/core/sync/sync_service.dart';

void main() {
  test('kata nonaktif disembunyikan dari daftar & pencarian', () async {
    final db = ContentDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: const Value(1), slug: 'uji', name: 'Uji', description: '',
          ),
        );
    for (final id in [1001, 1002]) {
      await db.into(db.vocabularies).insert(
            VocabulariesCompanion.insert(
              id: Value(id),
              word: 'word$id',
              wordNormalized: 'word$id',
              translation: 'kata$id',
              definition: 'definisi',
              partOfSpeech: 'noun',
              difficultyLevel: 'beginner',
              categoryId: 1,
              exampleSentence: 'contoh',
              exampleTranslation: 'contoh',
              createdAt: '2026-11-19T00:00:00Z',
            ),
          );
    }

    expect((await db.allWords()).length, 2);
    await (db.update(db.vocabularies)
          ..where((row) => row.id.equals(1002)))
        .write(const VocabulariesCompanion(isActive: Value(false)));

    expect((await db.allWords()).length, 1);
    expect(await db.vocabularyById(1002), isNull);
    expect((await db.vocabulariesByIds([1001, 1002])).length, 1);
    final counts = await db.categoryCounts();
    expect(counts.single.total, 1);
  });

  test('review_log dari pull tidak diduplikasi saat sync ulang', () async {
    SharedPreferences.setMockInitialValues({SyncConfig.tokenKey: 'token-uji'});
    final prefs = await SharedPreferences.getInstance();

    final change = {
      'client_id': 'rl_1001_123',
      'entity': 'review_log',
      'payload': {
        'vocab_id': 1001,
        'mode': 'quiz',
        'quality': 4,
        'is_correct': true,
        'reviewed_at': '2026-11-19T10:00:00.000Z',
      },
      'updated_at': '2026-11-19T10:00:00.000Z',
      'server_seq': 1,
    };
    final client = MockClient((_) async {
      return http.Response(
        '{"server_seq":1,"changes":[${_json(change)}]}',
        200,
      );
    });

    final userDb = UserDatabase(NativeDatabase.memory());
    addTearDown(userDb.close);
    final api = ApiClient(client: client, baseUrl: 'http://uji')..token = 'token-uji';
    final service = SyncService(api, userDb, prefs);

    await service.syncProgress(1);
    expect((await userDb.select(userDb.reviewLogs).get()).length, 1);

    // Server mengembalikan perubahan yang sama; harus tetap satu baris.
    await service.syncProgress(1);
    expect((await userDb.select(userDb.reviewLogs).get()).length, 1);
  });
}

String _json(Map<String, Object?> value) =>
    '{${value.entries.map((e) => '"${e.key}":${_value(e.value)}').join(',')}}';

String _value(Object? value) => switch (value) {
      String() => '"$value"',
      Map() => '{${value.entries.map((e) => '"${e.key}":${_value(e.value)}').join(',')}}',
      _ => '$value',
    };
