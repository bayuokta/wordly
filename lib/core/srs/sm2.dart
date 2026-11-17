/// Scheduler SM-2 yang disesuaikan untuk kosakata (bagian 8 dokumen rancangan).
library;

/// Status belajar sebuah kata.
enum WordStatus {
  newWord('new'),
  learning('learning'),
  review('review'),
  mastered('mastered');

  const WordStatus(this.value);

  final String value;

  static WordStatus fromValue(String value) => WordStatus.values.firstWhere(
    (status) => status.value == value,
    orElse: () => WordStatus.newWord,
  );
}

/// Kondisi jadwal sebuah kata.
class Sm2State {
  const Sm2State({
    required this.status,
    required this.repetitions,
    required this.easeFactor,
    required this.intervalDays,
    this.dueAt,
    this.lapses = 0,
  });

  const Sm2State.initial()
    : status = WordStatus.newWord,
      repetitions = 0,
      easeFactor = 2.5,
      intervalDays = 0,
      dueAt = null,
      lapses = 0;

  final WordStatus status;
  final int repetitions;
  final double easeFactor;
  final int intervalDays;
  final DateTime? dueAt;
  final int lapses;
}

/// Hasil perhitungan setelah satu jawaban.
class Sm2Result {
  const Sm2Result({
    required this.status,
    required this.repetitions,
    required this.easeFactor,
    required this.intervalDays,
    required this.dueAt,
    required this.lapses,
  });

  final WordStatus status;
  final int repetitions;
  final double easeFactor;
  final int intervalDays;
  final DateTime dueAt;
  final int lapses;
}

abstract final class Sm2 {
  static const double minEaseFactor = 1.3;
  static const int masteredMinInterval = 21;
  static const int masteredMinRepetitions = 4;

  /// Interval untuk kata yang baru salah (muncul lagi di sesi yang sama).
  static const Duration relearnDelay = Duration(minutes: 10);

  /// Kualitas jawaban 0..5.
  ///
  /// - salah → 1
  /// - benar tapi ragu / pakai petunjuk → 3
  /// - benar → 4
  /// - benar dan mudah (swipe kanan/cepat) → 5
  static int quality({required bool correct, bool hint = false, bool easy = false}) {
    if (!correct) return 1;
    if (hint) return 3;
    if (easy) return 5;
    return 4;
  }

  static Sm2Result next({
    required Sm2State current,
    required int quality,
    required DateTime now,
  }) {
    assert(quality >= 0 && quality <= 5);

    if (quality < 3) {
      return Sm2Result(
        status: WordStatus.learning,
        repetitions: 0,
        easeFactor: current.easeFactor,
        intervalDays: 0,
        dueAt: now.add(relearnDelay),
        lapses: current.lapses + 1,
      );
    }

    final repetitions = current.repetitions + 1;
    final int intervalDays;
    if (repetitions == 1) {
      intervalDays = 1;
    } else if (repetitions == 2) {
      intervalDays = 3;
    } else {
      intervalDays = (current.intervalDays * current.easeFactor).round().clamp(1, 3650);
    }

    final delta = 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
    final easeFactor = (current.easeFactor + delta).clamp(minEaseFactor, 3.5);

    final status = (intervalDays >= masteredMinInterval && repetitions >= masteredMinRepetitions)
        ? WordStatus.mastered
        : WordStatus.review;

    return Sm2Result(
      status: status,
      repetitions: repetitions,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      dueAt: now.add(Duration(days: intervalDays)),
      lapses: current.lapses,
    );
  }
}
