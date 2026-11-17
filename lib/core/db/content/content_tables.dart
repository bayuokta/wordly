import 'package:drift/drift.dart';

/// Tabel konten (read-only saat runtime). Sumber: `assets/vocab/*.json`.
class Categories extends Table {
  IntColumn get id => integer()();
  TextColumn get slug => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Vocabularies extends Table {
  IntColumn get id => integer()();
  TextColumn get word => text()();
  TextColumn get wordNormalized => text()();
  TextColumn get translation => text()();
  TextColumn get definition => text()();
  TextColumn get pronunciationIpa => text().nullable()();
  TextColumn get partOfSpeech => text()();
  TextColumn get difficultyLevel => text()();
  TextColumn get cefr => text().nullable()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get exampleSentence => text()();
  TextColumn get exampleTranslation => text()();
  TextColumn get synonyms => text().withDefault(const Constant('[]'))();
  TextColumn get antonyms => text().withDefault(const Constant('[]'))();
  TextColumn get audioUrl => text().nullable()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'UNIQUE (word_normalized, part_of_speech, category_id)',
  ];
}
