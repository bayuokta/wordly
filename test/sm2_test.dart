import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/core/srs/sm2.dart';

void main() {
  final now = DateTime(2026, 11, 17, 9);

  group('Sm2.quality', () {
    test('salah selalu 1', () {
      expect(Sm2.quality(correct: false), 1);
      expect(Sm2.quality(correct: false, easy: true), 1);
    });

    test('benar dengan petunjuk = 3, benar = 4, mudah = 5', () {
      expect(Sm2.quality(correct: true, hint: true), 3);
      expect(Sm2.quality(correct: true), 4);
      expect(Sm2.quality(correct: true, easy: true), 5);
    });
  });

  group('Sm2.next', () {
    test('jawaban pertama benar → interval 1 hari, status review', () {
      final result = Sm2.next(
        current: const Sm2State.initial(),
        quality: 4,
        now: now,
      );

      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.status, WordStatus.review);
      expect(result.dueAt, now.add(const Duration(days: 1)));
    });

    test('jawaban kedua benar → interval 3 hari', () {
      final result = Sm2.next(
        current: const Sm2State(
          status: WordStatus.review,
          repetitions: 1,
          easeFactor: 2.5,
          intervalDays: 1,
        ),
        quality: 4,
        now: now,
      );

      expect(result.repetitions, 2);
      expect(result.intervalDays, 3);
    });

    test('jawaban ketiga benar → interval dikali ease factor', () {
      final result = Sm2.next(
        current: const Sm2State(
          status: WordStatus.review,
          repetitions: 2,
          easeFactor: 2.5,
          intervalDays: 3,
        ),
        quality: 4,
        now: now,
      );

      expect(result.repetitions, 3);
      expect(result.intervalDays, 8); // 3 * 2.5 = 7.5 → 8
      expect(result.status, WordStatus.review);
    });

    test('salah mereset repetisi dan menjadwalkan 10 menit', () {
      final result = Sm2.next(
        current: const Sm2State(
          status: WordStatus.review,
          repetitions: 5,
          easeFactor: 2.5,
          intervalDays: 30,
        ),
        quality: 1,
        now: now,
      );

      expect(result.repetitions, 0);
      expect(result.intervalDays, 0);
      expect(result.status, WordStatus.learning);
      expect(result.lapses, 1);
      expect(result.dueAt, now.add(Sm2.relearnDelay));
    });

    test('ease factor tidak pernah di bawah 1.3', () {
      var state = const Sm2State.initial();
      for (var i = 0; i < 12; i++) {
        final result = Sm2.next(current: state, quality: 3, now: now);
        state = Sm2State(
          status: result.status,
          repetitions: result.repetitions,
          easeFactor: result.easeFactor,
          intervalDays: result.intervalDays,
        );
      }
      expect(state.easeFactor, greaterThanOrEqualTo(Sm2.minEaseFactor));
    });

    test('menjadi mastered setelah interval ≥ 21 hari dan 4 repetisi', () {
      final result = Sm2.next(
        current: const Sm2State(
          status: WordStatus.review,
          repetitions: 3,
          easeFactor: 2.5,
          intervalDays: 12,
        ),
        quality: 4,
        now: now,
      );

      expect(result.intervalDays, greaterThanOrEqualTo(Sm2.masteredMinInterval));
      expect(result.repetitions, greaterThanOrEqualTo(Sm2.masteredMinRepetitions));
      expect(result.status, WordStatus.mastered);
    });

    test('kata mastered kembali ke review saat salah', () {
      final result = Sm2.next(
        current: const Sm2State(
          status: WordStatus.mastered,
          repetitions: 6,
          easeFactor: 2.2,
          intervalDays: 40,
          lapses: 2,
        ),
        quality: 1,
        now: now,
      );

      expect(result.status, WordStatus.learning);
      expect(result.lapses, 3);
      expect(result.intervalDays, 0);
    });
  });

  test('WordStatus.fromValue fallback ke new', () {
    expect(WordStatus.fromValue('mastered'), WordStatus.mastered);
    expect(WordStatus.fromValue('tidak-dikenal'), WordStatus.newWord);
  });
}
