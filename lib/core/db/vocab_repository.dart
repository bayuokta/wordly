import 'package:drift/drift.dart' show Value;

import '../srs/sm2.dart';
import 'content/content_database.dart';
import 'user/user_database.dart';

/// Data yang dibutuhkan layar Home.
class HomeSnapshot {
  const HomeSnapshot({
    required this.wordOfDay,
    required this.wordOfDayCategory,
    required this.goal,
    required this.reviewsToday,
    required this.learned,
    required this.mastered,
    required this.due,
    required this.recent,
    required this.streakDays,
  });

  final Vocabulary? wordOfDay;
  final Category? wordOfDayCategory;
  final int goal;
  final int reviewsToday;
  final int learned;
  final int mastered;
  final int due;
  final List<WordListItem> recent;
  final int streakDays;

  double get goalProgress => goal == 0 ? 0 : (reviewsToday / goal).clamp(0, 1);
}

/// Satu kata + progres pengguna (bila ada).
class WordListItem {
  const WordListItem({required this.word, this.progress, this.category});

  final Vocabulary word;
  final UserWord? progress;
  final Category? category;

  bool get isFavorite => progress?.isFavorite ?? false;
  WordStatus get status => WordStatus.fromValue(progress?.status ?? 'new');
}

/// Detail kata siap tampil.
class WordDetailData {
  const WordDetailData({required this.item, required this.category, required this.dueLabel});

  final WordListItem item;
  final Category? category;
  final String? dueLabel;

  Vocabulary get word => item.word;
  UserWord? get progress => item.progress;
  List<String> get synonyms => _jsonList(word.synonyms);
  List<String> get antonyms => _jsonList(word.antonyms);

  static List<String> _jsonList(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length <= 2) return const [];
    return trimmed
        .substring(1, trimmed.length - 1)
        .split(',')
        .map((value) => value.trim().replaceAll('"', ''))
        .where((value) => value.isNotEmpty)
        .toList();
  }
}

/// Menyatukan konten (`vocab.db`) dan progres (`user.db`).
class VocabRepository {
  VocabRepository({required this.content, required this.user});

  final ContentDatabase content;
  final UserDatabase user;

  static const String defaultLevel = 'intermediate';
  static const int dailyGoal = 10;

  Future<HomeSnapshot> home(DateTime now) async {
    final day = _dayKey(now);
    final wordOfDay = await _wordOfDay(now);
    final category = wordOfDay == null
        ? null
        : await content.categoryOf(wordOfDay.categoryId);
    final activity = await user.activityFor(day);
    final learned = await user.countLearned();
    final mastered = await user.countByStatus(WordStatus.mastered.value);
    final due = await user.countDue(now);
    final recent = await recentItems(limit: 4);

    return HomeSnapshot(
      wordOfDay: wordOfDay,
      wordOfDayCategory: category,
      goal: dailyGoal,
      reviewsToday: activity?.reviewsDone ?? 0,
      learned: learned,
      mastered: mastered,
      due: due,
      recent: recent,
      streakDays: await _streak(now),
    );
  }

  /// Jumlah hari berurutan yang punya minimal satu ulangan.
  Future<int> _streak(DateTime now) async {
    final rows = await user.recentActivity(days: 400);
    final activeDays = {
      for (final row in rows)
        if (row.reviewsDone > 0) row.day,
    };
    var streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    while (true) {
      final key = _dayKey(cursor);
      if (!activeDays.contains(key)) {
        // Hari ini belum belajar tidak memutus streak kemarin.
        if (streak == 0 && key == _dayKey(now)) {
          cursor = cursor.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<Vocabulary?> _wordOfDay(DateTime now) async {
    final day = _dayKey(now);
    final pinned = await user.wordOfDayId(day);
    if (pinned != null) {
      final word = await content.vocabularyById(pinned);
      if (word != null) return word;
    }
    final picked = await content.pickWordOfDay(now, level: defaultLevel);
    if (picked != null) {
      await user.pinWordOfDay(day, picked.id);
    }
    return picked;
  }

  Future<List<CategoryCount>> categoriesWithProgress() async {
    final counts = await content.categoryCounts();
    final touched = await user.touchedVocabIds();
    if (touched.isEmpty) return counts;

    final words = await content.vocabulariesByIds(touched.toList());
    final perCategory = <int, int>{};
    for (final word in words) {
      perCategory[word.categoryId] = (perCategory[word.categoryId] ?? 0) + 1;
    }
    return counts
        .map((category) => category.withLearned(perCategory[category.id] ?? 0))
        .toList();
  }

  Future<List<WordListItem>> wordsInCategory(int categoryId, {String? level}) async {
    final words = await content.byCategory(categoryId, level: level);
    return _attachProgress(words);
  }

  Future<List<WordListItem>> search(String query, {String? level}) async {
    final words = await content.search(query, level: level);
    return _attachProgress(words);
  }

  Future<List<WordListItem>> browse({String? level, int limit = 60}) async {
    final words = level == null
        ? await content.allWords(limit: limit)
        : await content.wordsForLevel(level, limit: limit);
    return _attachProgress(words);
  }

  Future<List<WordListItem>> _attachProgress(List<Vocabulary> words) async {
    if (words.isEmpty) return const [];
    final ids = words.map((word) => word.id).toList();
    final progressRows = await (user.select(user.userWords)
          ..where((t) => t.vocabId.isIn(ids)))
        .get();
    final byId = {for (final row in progressRows) row.vocabId: row};
    return [
      for (final word in words) WordListItem(word: word, progress: byId[word.id]),
    ];
  }

  Future<List<WordListItem>> recentItems({int limit = 6}) async {
    final rows = await user.recentlyTouched(limit: limit);
    if (rows.isEmpty) return const [];
    final words = await content.vocabulariesByIds(rows.map((row) => row.vocabId).toList());
    final byId = {for (final word in words) word.id: word};
    return [
      for (final row in rows)
        if (byId[row.vocabId] case final word?) WordListItem(word: word, progress: row),
    ];
  }

  Future<List<WordListItem>> favorites() => _listFromProgress(user.watchFavorites().first);

  Future<List<WordListItem>> byStatus(WordStatus status) =>
      _listFromProgress(user.watchByStatus(status.value).first);

  Future<List<WordListItem>> _listFromProgress(Future<List<UserWord>> source) async {
    final rows = await source;
    if (rows.isEmpty) return const [];
    final words = await content.vocabulariesByIds(rows.map((row) => row.vocabId).toList());
    final byId = {for (final word in words) word.id: word};
    return [
      for (final row in rows)
        if (byId[row.vocabId] case final word?) WordListItem(word: word, progress: row),
    ];
  }

  Future<WordDetailData> detail(int vocabId) async {
    final word = await content.vocabularyById(vocabId);
    if (word == null) {
      throw StateError('Kata $vocabId tidak ditemukan');
    }
    final category = await content.categoryOf(word.categoryId);
    final progress = await user.progressFor(vocabId);
    final item = WordListItem(word: word, progress: progress, category: category);
    return WordDetailData(
      item: item,
      category: category,
      dueLabel: _dueLabel(progress?.dueAt),
    );
  }

  Future<void> toggleFavorite(int vocabId) async {
    final current = await user.progressFor(vocabId);
    await user.setFavorite(vocabId, favorite: !(current?.isFavorite ?? false));
  }

  /// Menjawab sebuah kata; memperbarui jadwal SM-2, log, dan aktivitas harian.
  Future<Sm2Result> answer({
    required int vocabId,
    required bool correct,
    String mode = 'word_detail',
    bool easy = false,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    final currentRow = await user.progressFor(vocabId);
    final current = currentRow == null
        ? const Sm2State.initial()
        : Sm2State(
            status: WordStatus.fromValue(currentRow.status),
            repetitions: currentRow.repetitions,
            easeFactor: currentRow.easeFactor,
            intervalDays: currentRow.intervalDays,
            dueAt: currentRow.dueAt,
            lapses: currentRow.lapses,
          );

    final quality = Sm2.quality(correct: correct, easy: easy);
    final result = Sm2.next(current: current, quality: quality, now: now);
    final isNew = currentRow == null || current.status == WordStatus.newWord;

    await user.saveProgress(
      UserWordsCompanion.insert(
        vocabId: Value(vocabId),
        status: Value(result.status.value),
        repetitions: Value(result.repetitions),
        easeFactor: Value(result.easeFactor),
        intervalDays: Value(result.intervalDays),
        dueAt: Value(result.dueAt),
        lapses: Value(result.lapses),
        correctCount: Value((currentRow?.correctCount ?? 0) + (correct ? 1 : 0)),
        wrongCount: Value((currentRow?.wrongCount ?? 0) + (correct ? 0 : 1)),
        firstSeenAt: Value(currentRow?.firstSeenAt ?? now),
        lastReviewedAt: Value(now),
        updatedAt: now,
      ),
    );

    await user.logReview(
      vocabId: vocabId,
      mode: mode,
      quality: quality,
      isCorrect: correct,
      at: now,
    );

    await user.bumpActivity(
      day: _dayKey(now),
      reviews: 1,
      correct: correct ? 1 : 0,
      wrong: correct ? 0 : 1,
      newWords: isNew ? 1 : 0,
      goal: dailyGoal,
    );

    return result;
  }

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String? _dueLabel(DateTime? dueAt) {
    if (dueAt == null) return null;
    final now = DateTime.now();
    final days = dueAt.difference(now).inDays;
    if (dueAt.isBefore(now)) return 'Jatuh tempo';
    if (days <= 0) return 'Hari ini';
    if (days == 1) return 'Besok';
    return '$days hari lagi';
  }
}
