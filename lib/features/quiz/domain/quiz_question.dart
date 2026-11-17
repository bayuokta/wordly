import 'dart:math';

import 'package:material_ui/material_ui.dart' show immutable;

import '../../../core/db/content/content_database.dart';

/// Enam mode latihan sesuai dokumen rancangan (bagian 2, fitur H).
enum QuizMode {
  multipleChoice(
    label: 'Pilihan ganda',
    description: 'Pilih arti Indonesia yang benar dari 4 opsi.',
    short: 'EN → ID',
  ),
  englishToIndonesian(
    label: 'English → Indonesia',
    description: 'Tuliskan arti kata dalam bahasa Indonesia.',
    short: 'Menulis',
  ),
  indonesianToEnglish(
    label: 'Indonesia → English',
    description: 'Tuliskan kata Inggris dari arti yang diberikan.',
    short: 'Menulis',
  ),
  fillBlank(
    label: 'Isi rumpang',
    description: 'Lengkapi kalimat yang kehilangan satu kata.',
    short: 'Konteks',
  ),
  listening(
    label: 'Listening',
    description: 'Dengarkan kata, lalu pilih artinya.',
    short: 'Audio',
  ),
  spelling(
    label: 'Ejaan',
    description: 'Dengarkan kata, lalu ketik ejaannya.',
    short: 'Audio',
  );

  const QuizMode({required this.label, required this.description, required this.short});

  final String label;
  final String description;
  final String short;

  bool get usesAudio => this == listening || this == spelling;
  bool get needsTyping => this == englishToIndonesian || this == indonesianToEnglish || this == fillBlank || this == spelling;
}

@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.mode,
    required this.word,
    required this.prompt,
    required this.answer,
    this.sentence,
    this.options = const [],
    this.accepted = const [],
  });

  final QuizMode mode;
  final Vocabulary word;

  /// Instruksi / pertanyaan.
  final String prompt;
  final String answer;
  final String? sentence;
  final List<String> options;
  final List<String> accepted;

  /// Kata yang diucapkan TTS (mode audio).
  String get audioText => word.word;

  bool accepts(String input) {
    final normalized = normalizeAnswer(input);
    if (normalized.isEmpty) return false;
    final candidates = <String>{normalizeAnswer(answer), ...accepted.map(normalizeAnswer)};
    return candidates.any((candidate) => candidate == normalized);
  }
}

/// Menyamakan bentuk jawaban: huruf kecil, tanpa tanda baca, spasi tunggal.
String normalizeAnswer(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[.,!?;:"“”()\[\]/]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Pecah terjemahan "tangguh; cepat pulih" menjadi beberapa jawaban sah.
List<String> answerVariants(String translation) {
  final parts = translation
      .split(';')
      .map(normalizeAnswer)
      .where((part) => part.isNotEmpty)
      .toSet()
      .toList();
  return parts.isEmpty ? [normalizeAnswer(translation)] : parts;
}

/// Membangun daftar soal dari kumpulan kata.
class QuizBuilder {
  QuizBuilder({required this.pool, Random? random}) : _random = random ?? Random();

  /// Seluruh kata yang boleh dipakai sebagai sumber soal & pengecoh.
  final List<Vocabulary> pool;
  final Random _random;

  List<QuizQuestion> build({required QuizMode mode, required int count}) {
    if (pool.isEmpty) return const [];

    final shuffled = [...pool]..shuffle(_random);
    final questions = <QuizQuestion>[];
    final answers = pool.map((word) => word.translation).toSet();

    for (final word in shuffled) {
      if (questions.length >= count) break;
      final question = _buildOne(mode, word, answers);
      if (question != null) questions.add(question);
    }
    return questions;
  }

  QuizQuestion? _buildOne(QuizMode mode, Vocabulary word, Set<String> allAnswers) {
    switch (mode) {
      case QuizMode.multipleChoice:
      case QuizMode.listening:
        final distractors = _pickDistractors(
          word,
          allAnswers,
          take: 3,
          selector: (candidate) => candidate.translation,
        );
        if (distractors.length < 3) return null;
        final options = [word.translation, ...distractors]..shuffle(_random);
        return QuizQuestion(
          mode: mode,
          word: word,
          prompt: mode == QuizMode.listening
              ? 'Dengarkan kata, lalu pilih artinya.'
              : 'Apa arti kata berikut?',
          answer: word.translation,
          options: options,
          accepted: answerVariants(word.translation),
        );

      case QuizMode.englishToIndonesian:
        return QuizQuestion(
          mode: mode,
          word: word,
          prompt: 'Tuliskan arti kata berikut dalam bahasa Indonesia.',
          answer: word.translation,
          accepted: answerVariants(word.translation),
        );

      case QuizMode.indonesianToEnglish:
        return QuizQuestion(
          mode: mode,
          word: word,
          prompt: 'Tuliskan kata bahasa Inggris untuk arti berikut.',
          answer: word.word,
        );

      case QuizMode.fillBlank:
        final pattern = RegExp(RegExp.escape(word.word), caseSensitive: false);
        if (!pattern.hasMatch(word.exampleSentence)) return null;
        final blanked = word.exampleSentence.replaceFirst(pattern, '____');
        return QuizQuestion(
          mode: mode,
          word: word,
          prompt: 'Lengkapi kalimat berikut.',
          sentence: blanked,
          answer: word.word,
        );

      case QuizMode.spelling:
        return QuizQuestion(
          mode: mode,
          word: word,
          prompt: 'Dengarkan kata, lalu ketik ejaannya dengan benar.',
          answer: word.word,
        );
    }
  }

  List<String> _pickDistractors(
    Vocabulary word,
    Set<String> allAnswers, {
    required int take,
    required String Function(Vocabulary) selector,
  }) {
    final candidates = pool
        .where((candidate) => candidate.id != word.id && selector(candidate) != selector(word))
        .toList()
      ..shuffle(_random);
    final picked = <String>[];
    for (final candidate in candidates) {
      final value = selector(candidate);
      if (picked.contains(value)) continue;
      picked.add(value);
      if (picked.length == take) break;
    }
    return picked;
  }
}
