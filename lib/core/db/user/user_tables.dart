import 'package:drift/drift.dart';

/// Akun lokal. Baris `id = 1` adalah **Tamu** (tanpa kata sandi) sehingga
/// pengguna yang tidak mendaftar tetap bisa belajar.
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get passwordHash => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
}

/// Sesi login (auto-login). Token acak; kata sandi tidak pernah disimpan.
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get token => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime()();
}

/// Tabel progres pengguna. Berisi ID kata saja (tanpa foreign key ke `vocab.db`
/// karena berbeda file database). Setiap baris milik satu akun (`user_id`).
class UserWords extends Table {
  IntColumn get userId => integer().withDefault(const Constant(1))();
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
  Set<Column> get primaryKey => {userId, vocabId};
}

class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().withDefault(const Constant(1))();
  IntColumn get vocabId => integer()();
  TextColumn get mode => text()();
  IntColumn get quality => integer()();
  BoolColumn get isCorrect => boolean()();
  DateTimeColumn get reviewedAt => dateTime()();
}

class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().withDefault(const Constant(1))();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class CollectionWords extends Table {
  IntColumn get userId => integer().withDefault(const Constant(1))();
  IntColumn get collectionId => integer().references(Collections, #id)();
  IntColumn get vocabId => integer()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, collectionId, vocabId};
}

class DailyActivities extends Table {
  IntColumn get userId => integer().withDefault(const Constant(1))();
  /// Format `YYYY-MM-DD` waktu lokal.
  TextColumn get day => text()();
  IntColumn get wordsLearned => integer().withDefault(const Constant(0))();
  IntColumn get reviewsDone => integer().withDefault(const Constant(0))();
  IntColumn get correct => integer().withDefault(const Constant(0))();
  IntColumn get wrong => integer().withDefault(const Constant(0))();
  BoolColumn get goalMet => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {userId, day};
}

class WordOfDays extends Table {
  IntColumn get userId => integer().withDefault(const Constant(1))();
  TextColumn get day => text()();
  IntColumn get vocabId => integer()();

  @override
  Set<Column> get primaryKey => {userId, day};
}
