import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'content_tables.dart';

part 'content_database.g.dart';

/// Database konten kosakata (`vocab.db`).
///
/// Read-only saat aplikasi berjalan; diisi oleh [VocabSeeder] pada peluncuran
/// pertama atau saat versi konten di aset naik.
@DriftDatabase(tables: [Categories, Vocabularies])
class ContentDatabase extends _$ContentDatabase {
  ContentDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'vocab'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createSearchIndex();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(vocabularies, vocabularies.isActive);
      }
      await _createSearchIndex();
    },
  );

  /// FTS5 untuk pencarian Inggris + Indonesia.
  Future<void> _createSearchIndex() async {
    await customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS vocabulary_fts USING fts5("
      "word, translation, content='vocabularies', content_rowid='id', prefix='2 3 4')",
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS vocabulary_ai AFTER INSERT ON vocabularies BEGIN '
      'INSERT INTO vocabulary_fts(rowid, word, translation) '
      'VALUES (new.id, new.word, new.translation); END',
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS vocabulary_ad AFTER DELETE ON vocabularies BEGIN '
      "INSERT INTO vocabulary_fts(vocabulary_fts, rowid, word, translation) "
      "VALUES('delete', old.id, old.word, old.translation); END",
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS vocabulary_au AFTER UPDATE ON vocabularies BEGIN '
      "INSERT INTO vocabulary_fts(vocabulary_fts, rowid, word, translation) "
      "VALUES('delete', old.id, old.word, old.translation); "
      'INSERT INTO vocabulary_fts(rowid, word, translation) '
      'VALUES (new.id, new.word, new.translation); END',
    );
  }

  // ---------------------------------------------------------------- kategori

  Future<List<Category>> allCategories() =>
      (select(categories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  /// Kategori beserta jumlah kata dan progres (kata yang pernah disentuh).
  Future<List<CategoryCount>> categoryCounts() async {
    final rows = await customSelect(
      'SELECT c.id, c.slug, c.name, c.description, c.icon, c.sort_order, '
      'COUNT(v.id) AS total '
      'FROM categories c LEFT JOIN vocabularies v '
      'ON v.category_id = c.id AND v.is_active = 1 '
      'GROUP BY c.id ORDER BY c.sort_order',
      readsFrom: {categories, vocabularies},
    ).get();
    return rows
        .map(
          (row) => CategoryCount(
            id: row.read<int>('id'),
            slug: row.read<String>('slug'),
            name: row.read<String>('name'),
            description: row.read<String>('description'),
            icon: row.readNullable<String>('icon'),
            total: row.read<int>('total'),
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------- kosakata

  Future<int> vocabularyCount() async {
    final count = countAll();
    final row = await (selectOnly(vocabularies)
          ..addColumns([count])
          ..where(vocabularies.isActive.equals(true)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<Vocabulary?> vocabularyById(int id) =>
      (select(vocabularies)
            ..where((t) => t.id.equals(id))
            ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();

  Future<Category?> categoryOf(int id) =>
      (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Vocabulary>> vocabulariesByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    return (select(vocabularies)
          ..where((t) => t.id.isIn(ids))
          ..where((t) => t.isActive.equals(true)))
        .get();
  }

  Future<List<Vocabulary>> byCategory(int categoryId, {String? level}) {
    final query = select(vocabularies)
      ..where((t) => t.categoryId.equals(categoryId))
      ..where((t) => t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.word)]);
    if (level != null) {
      query.where((t) => t.difficultyLevel.equals(level));
    }
    return query.get();
  }

  /// Pencarian Inggris/Indonesia memakai FTS5, dengan fallback LIKE untuk
  /// kata yang sangat pendek (FTS butuh minimal 1 karakter + prefix).
  Future<List<Vocabulary>> search(String raw, {String? level, int limit = 60}) async {
    final query = raw.trim();
    if (query.isEmpty) return const [];

    final match = '${query.replaceAll('"', '')}*';
    final results = await customSelect(
      'SELECT v.* FROM vocabulary_fts f JOIN vocabularies v ON v.id = f.rowid '
      'WHERE vocabulary_fts MATCH ? AND v.is_active = 1 '
      '${level == null ? '' : 'AND v.difficulty_level = ? '}'
      'ORDER BY v.word LIMIT ?',
      variables: [
        Variable.withString(match),
        if (level != null) Variable.withString(level),
        Variable.withInt(limit),
      ],
      readsFrom: {vocabularies},
    ).map((row) => vocabularies.map(row.data)).get();

    if (results.isNotEmpty) return results;

    // Fallback: pencarian terjemahan Indonesia yang tidak terindeks FTS.
    final like = '%${query.toLowerCase()}%';
    final fallback = select(vocabularies)
      ..where((t) => t.translation.lower().like(like))
      ..where((t) => t.isActive.equals(true));
    if (level != null) {
      fallback.where((t) => t.difficultyLevel.equals(level));
    }
    fallback.limit(limit);
    return fallback.get();
  }

  Future<List<Vocabulary>> wordsForLevel(String level, {int limit = 50}) {
    return (select(vocabularies)
          ..where((t) => t.difficultyLevel.equals(level))
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.word)])
          ..limit(limit))
        .get();
  }

  Future<List<Vocabulary>> allWords({int limit = 500}) {
    return (select(vocabularies)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.word)])
          ..limit(limit))
        .get();
  }

  /// Kata yang belum pernah disentuh pengguna.
  Future<List<Vocabulary>> untouchedWords({
    required Set<int> excludeIds,
    String? level,
    int limit = 20,
  }) {
    final query = select(vocabularies)
      ..where((t) => t.isActive.equals(true));
    if (level != null) {
      query.where((t) => t.difficultyLevel.equals(level));
    }
    if (excludeIds.isNotEmpty) {
      query.where((t) => t.id.isNotIn(excludeIds.toList()));
    }
    query
      ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ..limit(limit);
    return query.get();
  }

  /// Pilih kata untuk hari tertentu secara deterministik.
  Future<Vocabulary?> pickWordOfDay(DateTime day, {String level = 'intermediate'}) async {
    final total = await (selectOnly(vocabularies)
          ..addColumns([countAll()])
          ..where(vocabularies.difficultyLevel.equals(level))
          ..where(vocabularies.isActive.equals(true)))
        .getSingle()
        .then((row) => row.read(countAll()) ?? 0);
    if (total == 0) return null;

    final seed = DateTime(day.year, day.month, day.day).difference(DateTime(2026)).inDays;
    final offset = seed.abs() % total;
    return (select(vocabularies)
          ..where((t) => t.difficultyLevel.equals(level))
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1, offset: offset))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------- penulisan

  Future<void> clearContent() async {
    await transaction(() async {
      await delete(vocabularies).go();
      await delete(categories).go();
    });
  }

  Future<void> insertContent({
    required List<CategoriesCompanion> categoryRows,
    required List<VocabulariesCompanion> vocabularyRows,
  }) async {
    await transaction(() async {
      await batch((b) {
        b.insertAll(categories, categoryRows);
        b.insertAll(vocabularies, vocabularyRows);
      });
    });
  }
}

/// Ringkasan kategori untuk layar Explore.
class CategoryCount {
  const CategoryCount({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.total,
    this.icon,
    this.learned = 0,
  });

  final int id;
  final String slug;
  final String name;
  final String description;
  final String? icon;
  final int total;
  final int learned;

  CategoryCount withLearned(int value) => CategoryCount(
    id: id,
    slug: slug,
    name: name,
    description: description,
    icon: icon,
    total: total,
    learned: value,
  );

  double get progress => total == 0 ? 0 : learned / total;
}
