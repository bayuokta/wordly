import 'package:drift/drift.dart';

/// Tabel progres pengguna. Berisi ID kata saja (tanpa foreign key ke `vocab.db`
/// karena berbeda file database).
class UserWords extends Table {
  IntColumn get vocabId => integer()();
  TextColumn get status => text().withDefault(const Constant('new'))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get firstSeenAt => dateTime().nullable()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncState => text().withDefault(const Constant('local'))();

  @override
  Set<Column> get primaryKey => {vocabId};
}

class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vocabId => integer()();
  TextColumn get mode => text()();
  IntColumn get quality => integer()();
  BoolColumn get isCorrect => boolean()();
  DateTimeColumn get reviewedAt => dateTime()();
}

class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class CollectionWords extends Table {
  IntColumn get collectionId => integer().references(Collections, #id)();
  IntColumn get vocabId => integer()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {collectionId, vocabId};
}

class DailyActivities extends Table {
  /// Format `YYYY-MM-DD` waktu lokal.
  TextColumn get day => text()();
  IntColumn get wordsLearned => integer().withDefault(const Constant(0))();
  IntColumn get reviewsDone => integer().withDefault(const Constant(0))();
  IntColumn get correct => integer().withDefault(const Constant(0))();
  IntColumn get wrong => integer().withDefault(const Constant(0))();
  BoolColumn get goalMet => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {day};
}

class WordOfDays extends Table {
  TextColumn get day => text()();
  IntColumn get vocabId => integer()();

  @override
  Set<Column> get primaryKey => {day};
}
