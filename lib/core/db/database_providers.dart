import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../srs/sm2.dart';
import 'content/content_database.dart';
import 'user/user_database.dart';
import 'vocab_repository.dart';

/// Diisi oleh `bootstrapDatabases()` lewat `ProviderScope(overrides: ...)`.
final contentDbProvider = Provider<ContentDatabase>(
  (ref) => throw StateError('ContentDatabase belum di-bootstrap'),
);

final userDbProvider = Provider<UserDatabase>(
  (ref) => throw StateError('UserDatabase belum di-bootstrap'),
);

final vocabRepositoryProvider = Provider<VocabRepository>(
  (ref) => VocabRepository(
    content: ref.watch(contentDbProvider),
    user: ref.watch(userDbProvider),
  ),
);

/// Ringkasan layar Home.
final homeSnapshotProvider = FutureProvider<HomeSnapshot>(
  (ref) => ref.watch(vocabRepositoryProvider).home(DateTime.now()),
);

/// Kategori + progres untuk layar Explore.
final categoriesProvider = FutureProvider<List<CategoryCount>>(
  (ref) => ref.watch(vocabRepositoryProvider).categoriesWithProgress(),
);

/// Kata yang pernah disentuh (untuk tab Kata Saya).
final favoritesProvider = FutureProvider<List<WordListItem>>(
  (ref) => ref.watch(vocabRepositoryProvider).favorites(),
);

final historyProvider = FutureProvider<List<WordListItem>>(
  (ref) => ref.watch(vocabRepositoryProvider).recentItems(limit: 50),
);

final learningWordsProvider = FutureProvider<List<WordListItem>>(
  (ref) => ref.watch(vocabRepositoryProvider).byStatus(WordStatus.learning),
);

final masteredWordsProvider = FutureProvider<List<WordListItem>>(
  (ref) => ref.watch(vocabRepositoryProvider).byStatus(WordStatus.mastered),
);

/// Detail satu kata.
final wordDetailProvider = FutureProvider.family<WordDetailData, int>(
  (ref, id) => ref.watch(vocabRepositoryProvider).detail(id),
);

/// Kata dalam satu kategori.
final categoryWordsProvider = FutureProvider.family<List<WordListItem>, int>(
  (ref, categoryId) => ref.watch(vocabRepositoryProvider).wordsInCategory(categoryId),
);

/// Kumpulan kata untuk kuis.
final quizPoolProvider = FutureProvider<List<Vocabulary>>(
  (ref) => ref.watch(vocabRepositoryProvider).quizPool(),
);

/// Antrean review terjadwal (SM-2).
final reviewQueueProvider = FutureProvider<List<WordListItem>>(
  (ref) => ref.watch(vocabRepositoryProvider).reviewQueue(),
);

/// Daftar kata untuk filter level di Explore.
final browseProvider = FutureProvider.family<List<WordListItem>, String?>(
  (ref, level) => ref.watch(vocabRepositoryProvider).browse(level: level),
);

// ------------------------------------------------------------ filter Explore

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(SearchQuery.new);

class LevelFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? level) => state = level;

  void clear() => state = null;
}

final levelFilterProvider = NotifierProvider<LevelFilter, String?>(LevelFilter.new);

/// Hasil pencarian; parameter adalah (query, level).
final searchResultsProvider = FutureProvider.family<List<WordListItem>, ({String query, String? level})>(
  (ref, params) => ref.watch(vocabRepositoryProvider).search(params.query, level: params.level),
);
