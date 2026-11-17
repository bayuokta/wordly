import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../auth/password_hasher.dart';
import 'user_tables.dart';

part 'user_database.g.dart';

/// Id akun bawaan untuk mode tamu (tanpa kata sandi).
const int guestUserId = 1;

/// Database progres pengguna (`user.db`).
@DriftDatabase(
  tables: [
    Users,
    Sessions,
    UserWords,
    ReviewLogs,
    Collections,
    CollectionWords,
    DailyActivities,
    WordOfDays,
  ],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'user'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _ensureGuestAccount();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // 1) Akun & sesi.
        await m.createTable(users);
        await m.createTable(sessions);
        await _ensureGuestAccount();

        // 2) Semua progres lama menjadi milik Tamu (user_id = 1). Tabel dibuat
        //    ulang karena primary key berubah menjadi komposit.
        await m.alterTable(
          TableMigration(userWords, columnTransformer: {userWords.userId: const Constant(1)}),
        );
        await m.alterTable(
          TableMigration(reviewLogs, columnTransformer: {reviewLogs.userId: const Constant(1)}),
        );
        await m.alterTable(
          TableMigration(collections, columnTransformer: {collections.userId: const Constant(1)}),
        );
        await m.alterTable(
          TableMigration(
            collectionWords,
            columnTransformer: {collectionWords.userId: const Constant(1)},
          ),
        );
        await m.alterTable(
          TableMigration(dailyActivities, columnTransformer: {dailyActivities.userId: const Constant(1)}),
        );
        await m.alterTable(
          TableMigration(wordOfDays, columnTransformer: {wordOfDays.userId: const Constant(1)}),
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _ensureGuestAccount();
    },
  );

  Future<void> _ensureGuestAccount() async {
    final existing = await (select(users)..where((t) => t.id.equals(guestUserId))).getSingleOrNull();
    if (existing != null) return;
    await into(users).insert(
      UsersCompanion.insert(
        id: const Value(guestUserId),
        email: 'tamu@lokal',
        displayName: 'Tamu',
        createdAt: DateTime.now(),
      ),
    );
  }

  // ------------------------------------------------------------------- akun

  Future<User?> userById(int id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<User?> userByEmail(String email) =>
      (select(users)..where((t) => t.email.equals(email.trim().toLowerCase()))).getSingleOrNull();

  Future<bool> emailExists(String email) async => await userByEmail(email) != null;

  /// Jumlah akun nyata (selain Tamu).
  Future<int> realUserCount() async {
    final count = countAll();
    final row = await (selectOnly(users)
          ..addColumns([count])
          ..where(users.id.isNotValue(guestUserId)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<User> createUser({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final user = await into(users).insertReturning(
      UsersCompanion.insert(
        email: normalized,
        displayName: displayName.trim(),
        passwordHash: Value(PasswordHasher.hash(password)),
        createdAt: DateTime.now(),
        lastLoginAt: Value(DateTime.now()),
      ),
    );

    // Akun pertama mewarisi progres Tamu agar pengguna tidak kehilangan riwayat.
    final isFirstAccount = await realUserCount() == 1;
    if (isFirstAccount) {
      await claimGuestProgress(user.id);
    }
    return user;
  }

  Future<void> claimGuestProgress(int userId) async {
    if (userId == guestUserId) return;
    await transaction(() async {
      await (update(userWords)..where((t) => t.userId.equals(guestUserId)))
          .write(UserWordsCompanion(userId: Value(userId)));
      await (update(reviewLogs)..where((t) => t.userId.equals(guestUserId)))
          .write(ReviewLogsCompanion(userId: Value(userId)));
      await (update(collections)..where((t) => t.userId.equals(guestUserId)))
          .write(CollectionsCompanion(userId: Value(userId)));
      await (update(collectionWords)..where((t) => t.userId.equals(guestUserId)))
          .write(CollectionWordsCompanion(userId: Value(userId)));
      await (update(dailyActivities)..where((t) => t.userId.equals(guestUserId)))
          .write(DailyActivitiesCompanion(userId: Value(userId)));
      await (update(wordOfDays)..where((t) => t.userId.equals(guestUserId)))
          .write(WordOfDaysCompanion(userId: Value(userId)));
    });
  }

  Future<void> updateLastLogin(int userId) async {
    await (update(users)..where((t) => t.id.equals(userId)))
        .write(UsersCompanion(lastLoginAt: Value(DateTime.now())));
  }

  Future<void> updatePassword(int userId, String newPassword) async {
    await (update(users)..where((t) => t.id.equals(userId)))
        .write(UsersCompanion(passwordHash: Value(PasswordHasher.hash(newPassword))));
  }

  /// Menghapus akun beserta seluruh progresnya (Tamu tidak boleh dihapus).
  Future<void> deleteAccount(int userId) async {
    if (userId == guestUserId) return;
    await transaction(() async {
      await (delete(userWords)..where((t) => t.userId.equals(userId))).go();
      await (delete(reviewLogs)..where((t) => t.userId.equals(userId))).go();
      await (delete(collectionWords)..where((t) => t.userId.equals(userId))).go();
      await (delete(collections)..where((t) => t.userId.equals(userId))).go();
      await (delete(dailyActivities)..where((t) => t.userId.equals(userId))).go();
      await (delete(wordOfDays)..where((t) => t.userId.equals(userId))).go();
      await (delete(sessions)..where((t) => t.userId.equals(userId))).go();
      await (delete(users)..where((t) => t.id.equals(userId))).go();
    });
  }

  // ------------------------------------------------------------------ sesi

  Future<Session> createSession(int userId) async {
    final token = PasswordHasher.randomToken();
    await (delete(sessions)..where((t) => t.userId.equals(userId))).go();
    return into(sessions).insertReturning(
      SessionsCompanion.insert(
        userId: userId,
        token: token,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      ),
    );
  }

  Future<Session?> sessionByToken(String token) =>
      (select(sessions)..where((t) => t.token.equals(token))).getSingleOrNull();

  Future<void> touchSession(int sessionId) async {
    await (update(sessions)..where((t) => t.id.equals(sessionId)))
        .write(SessionsCompanion(lastUsedAt: Value(DateTime.now())));
  }

  Future<void> deleteSession(int sessionId) async {
    await (delete(sessions)..where((t) => t.id.equals(sessionId))).go();
  }

  // ----------------------------------------------------------------- progres

  Future<UserWord?> progressFor(int userId, int vocabId) => (select(userWords)
        ..where((t) => t.userId.equals(userId) & t.vocabId.equals(vocabId)))
      .getSingleOrNull();

  Stream<UserWord?> watchProgress(int userId, int vocabId) => (select(userWords)
        ..where((t) => t.userId.equals(userId) & t.vocabId.equals(vocabId)))
      .watchSingleOrNull();

  Stream<List<UserWord>> watchFavorites(int userId) => (select(userWords)
        ..where((t) => t.userId.equals(userId) & t.isFavorite.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Stream<List<UserWord>> watchByStatus(int userId, String status) => (select(userWords)
        ..where((t) => t.userId.equals(userId) & t.status.equals(status))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Stream<List<UserWord>> watchHistory(int userId, {int limit = 50}) => (select(userWords)
        ..where((t) => t.userId.equals(userId) & t.lastReviewedAt.isNotNull())
        ..orderBy([(t) => OrderingTerm.desc(t.lastReviewedAt)])
        ..limit(limit))
      .watch();

  Future<List<UserWord>> recentlyTouched(int userId, {int limit = 6}) => (select(userWords)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
        ..limit(limit))
      .get();

  /// Kata yang sudah jatuh tempo, paling terlambat lebih dulu.
  Future<List<UserWord>> dueWords(int userId, DateTime now, {int limit = 100}) =>
      (select(userWords)
            ..where(
              (t) => t.userId.equals(userId) & t.dueAt.isNotNull() & t.dueAt.isSmallerOrEqualValue(now),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.dueAt)])
            ..limit(limit))
          .get();

  Future<int> countLearned(int userId) async {
    final row = await (selectOnly(userWords)
          ..addColumns([countAll()])
          ..where(userWords.userId.equals(userId)))
        .getSingle();
    return row.read(countAll()) ?? 0;
  }

  Future<int> countDue(int userId, DateTime now) async {
    final count = countAll();
    final row = await (selectOnly(userWords)
          ..addColumns([count])
          ..where(
            userWords.userId.equals(userId) &
                userWords.dueAt.isNotNull() &
                userWords.dueAt.isSmallerOrEqualValue(now),
          ))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Stream<int> watchDueCount(int userId, DateTime now) {
    final count = countAll();
    return (selectOnly(userWords)
          ..addColumns([count])
          ..where(
            userWords.userId.equals(userId) &
                userWords.dueAt.isNotNull() &
                userWords.dueAt.isSmallerOrEqualValue(now),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  Future<int> countByStatus(int userId, String status) async {
    final count = countAll();
    final row = await (selectOnly(userWords)
          ..addColumns([count])
          ..where(userWords.userId.equals(userId) & userWords.status.equals(status)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<Set<int>> touchedVocabIds(int userId) async {
    final rows = await (selectOnly(userWords)
          ..addColumns([userWords.vocabId])
          ..where(userWords.userId.equals(userId)))
        .get();
    return rows.map((row) => row.read(userWords.vocabId)!).toSet();
  }

  Future<void> saveProgress(UserWordsCompanion entry) => into(userWords).insertOnConflictUpdate(entry);

  Future<void> setFavorite(int userId, int vocabId, {required bool favorite}) async {
    final existing = await progressFor(userId, vocabId);
    final now = DateTime.now();
    if (existing == null) {
      await into(userWords).insert(
        UserWordsCompanion.insert(
          userId: Value(userId),
          vocabId: vocabId,
          isFavorite: Value(favorite),
          updatedAt: now,
          firstSeenAt: Value(now),
        ),
      );
      return;
    }
    await (update(userWords)
          ..where((t) => t.userId.equals(userId) & t.vocabId.equals(vocabId)))
        .write(UserWordsCompanion(isFavorite: Value(favorite), updatedAt: Value(now)));
  }

  Future<void> logReview({
    required int userId,
    required int vocabId,
    required String mode,
    required int quality,
    required bool isCorrect,
    DateTime? at,
  }) async {
    await into(reviewLogs).insert(
      ReviewLogsCompanion.insert(
        userId: Value(userId),
        vocabId: vocabId,
        mode: mode,
        quality: quality,
        isCorrect: isCorrect,
        reviewedAt: at ?? DateTime.now(),
      ),
    );
  }

  // --------------------------------------------------------------- aktivitas

  Stream<DailyActivity?> watchActivity(int userId, String day) => (select(dailyActivities)
        ..where((t) => t.userId.equals(userId) & t.day.equals(day)))
      .watchSingleOrNull();

  Future<DailyActivity?> activityFor(int userId, String day) => (select(dailyActivities)
        ..where((t) => t.userId.equals(userId) & t.day.equals(day)))
      .getSingleOrNull();

  /// Tambah hitungan aktivitas harian secara atomik.
  Future<void> bumpActivity({
    required int userId,
    required String day,
    int reviews = 0,
    int correct = 0,
    int wrong = 0,
    int newWords = 0,
    required int goal,
  }) async {
    await transaction(() async {
      final current = await activityFor(userId, day);
      final reviewsDone = (current?.reviewsDone ?? 0) + reviews;
      final companion = DailyActivitiesCompanion.insert(
        userId: Value(userId),
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

  Future<List<DailyActivity>> recentActivity(int userId, {int days = 7}) {
    return (select(dailyActivities)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.day)])
          ..limit(days))
        .get();
  }

  // ------------------------------------------------------------ word of day

  Future<int?> wordOfDayId(int userId, String day) async {
    final row = await (select(wordOfDays)
          ..where((t) => t.userId.equals(userId) & t.day.equals(day)))
        .getSingleOrNull();
    return row?.vocabId;
  }

  Future<void> pinWordOfDay(int userId, String day, int vocabId) =>
      into(wordOfDays).insertOnConflictUpdate(
        WordOfDaysCompanion.insert(
          userId: Value(userId),
          day: day,
          vocabId: vocabId,
        ),
      );
}
