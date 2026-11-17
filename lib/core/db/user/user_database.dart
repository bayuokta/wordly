import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'user_tables.dart';

part 'user_database.g.dart';

/// Database progres pengguna (`user.db`).
@DriftDatabase(
  tables: [UserWords, ReviewLogs, Collections, CollectionWords, DailyActivities, WordOfDays],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'user'));

  @override
  int get schemaVersion => 1;

  // ----------------------------------------------------------------- progres

  Future<UserWord?> progressFor(int vocabId) =>
      (select(userWords)..where((t) => t.vocabId.equals(vocabId))).getSingleOrNull();

  Stream<UserWord?> watchProgress(int vocabId) =>
      (select(userWords)..where((t) => t.vocabId.equals(vocabId))).watchSingleOrNull();

  Stream<List<UserWord>> watchFavorites() => (select(userWords)
        ..where((t) => t.isFavorite.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Stream<List<UserWord>> watchByStatus(String status) => (select(userWords)
        ..where((t) => t.status.equals(status))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Stream<List<UserWord>> watchHistory({int limit = 50}) => (select(userWords)
        ..where((t) => t.lastReviewedAt.isNotNull())
        ..orderBy([(t) => OrderingTerm.desc(t.lastReviewedAt)])
        ..limit(limit))
      .watch();

  Future<List<UserWord>> recentlyTouched({int limit = 6}) => (select(userWords)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
        ..limit(limit))
      .get();

  Future<int> countLearned() async {
    final row = await (selectOnly(userWords)..addColumns([countAll()])).getSingle();
    return row.read(countAll()) ?? 0;
  }

  Future<int> countDue(DateTime now) async {
    final count = countAll();
    final row = await (selectOnly(userWords)
          ..addColumns([count])
          ..where(userWords.dueAt.isNotNull() & userWords.dueAt.isSmallerOrEqualValue(now)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Stream<int> watchDueCount(DateTime now) {
    final count = countAll();
    return (selectOnly(userWords)
          ..addColumns([count])
          ..where(userWords.dueAt.isNotNull() & userWords.dueAt.isSmallerOrEqualValue(now)))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  Future<int> countByStatus(String status) async {
    final count = countAll();
    final row = await (selectOnly(userWords)
          ..addColumns([count])
          ..where(userWords.status.equals(status)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<Set<int>> touchedVocabIds() async {
    final rows = await (selectOnly(userWords)..addColumns([userWords.vocabId])).get();
    return rows.map((row) => row.read(userWords.vocabId)!).toSet();
  }

  Future<void> saveProgress(UserWordsCompanion entry) =>
      into(userWords).insertOnConflictUpdate(entry);

  Future<void> setFavorite(int vocabId, {required bool favorite}) async {
    final existing = await progressFor(vocabId);
    final now = DateTime.now();
    if (existing == null) {
      await into(userWords).insert(
        UserWordsCompanion.insert(
          vocabId: Value(vocabId),
          isFavorite: Value(favorite),
          updatedAt: now,
          firstSeenAt: Value(now),
        ),
      );
      return;
    }
    await (update(userWords)..where((t) => t.vocabId.equals(vocabId))).write(
      UserWordsCompanion(isFavorite: Value(favorite), updatedAt: Value(now)),
    );
  }

  Future<void> logReview({
    required int vocabId,
    required String mode,
    required int quality,
    required bool isCorrect,
    DateTime? at,
  }) async {
    await into(reviewLogs).insert(
      ReviewLogsCompanion.insert(
        vocabId: vocabId,
        mode: mode,
        quality: quality,
        isCorrect: isCorrect,
        reviewedAt: at ?? DateTime.now(),
      ),
    );
  }

  // --------------------------------------------------------------- aktivitas

  Stream<DailyActivity?> watchActivity(String day) =>
      (select(dailyActivities)..where((t) => t.day.equals(day))).watchSingleOrNull();

  Future<DailyActivity?> activityFor(String day) =>
      (select(dailyActivities)..where((t) => t.day.equals(day))).getSingleOrNull();

  /// Tambah hitungan aktivitas harian secara atomik.
  Future<void> bumpActivity({
    required String day,
    int reviews = 0,
    int correct = 0,
    int wrong = 0,
    int newWords = 0,
    required int goal,
  }) async {
    await transaction(() async {
      final current = await activityFor(day);
      final reviewsDone = (current?.reviewsDone ?? 0) + reviews;
      final companion = DailyActivitiesCompanion.insert(
        day: day,
        reviewsDone: Value(reviewsDone),
        correct: Value((current?.correct ?? 0) + correct),
        wrong: Value((current?.wrong ?? 0) + wrong),
        wordsLearned: Value((current?.wordsLearned ?? 0) + newWords),
        goalMet: Value(reviewsDone >= goal),
      );
      await into(dailyActivities).insertOnConflictUpdate(companion);
    });
  }

  Future<List<DailyActivity>> recentActivity({int days = 7}) {
    return (select(dailyActivities)
          ..orderBy([(t) => OrderingTerm.desc(t.day)])
          ..limit(days))
        .get();
  }

  // ------------------------------------------------------------ word of day

  Future<int?> wordOfDayId(String day) async {
    final row = await (select(wordOfDays)..where((t) => t.day.equals(day))).getSingleOrNull();
    return row?.vocabId;
  }

  Future<void> pinWordOfDay(String day, int vocabId) =>
      into(wordOfDays).insertOnConflictUpdate(
        WordOfDaysCompanion.insert(day: day, vocabId: vocabId),
      );
}
