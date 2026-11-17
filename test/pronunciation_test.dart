import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/core/audio/pronunciation_score.dart';

void main() {
  group('normalizeSpoken', () {
    test('huruf kecil, tanpa tanda baca, spasi rapi', () {
      expect(normalizeSpoken('  Hello, World!  '), 'hello world');
      expect(normalizeSpoken('well-known'), 'well known');
      expect(normalizeSpoken(''), '');
    });
  });

  group('levenshteinDistance', () {
    test('kata sama = 0', () => expect(levenshteinDistance('accept', 'accept'), 0));
    test('dua huruf beda = 2', () => expect(levenshteinDistance('accept', 'except'), 2));
    test('satu huruf beda = 1', () => expect(levenshteinDistance('accept', 'akcept'), 1));
    test('penambahan/penghapusan', () {
      expect(levenshteinDistance('cat', 'cats'), 1);
      expect(levenshteinDistance('cats', 'cat'), 1);
      expect(levenshteinDistance('', 'abc'), 3);
    });
  });

  group('scorePronunciation', () {
    test('pengucapan sempurna = 1.0', () {
      expect(scorePronunciation('resilient', 'resilient'), 1.0);
      expect(scorePronunciation('give up', 'Give up!'), 1.0);
    });

    test('salah sedikit tetap tinggi', () {
      final score = scorePronunciation('resilient', 'resiliant');
      expect(score, greaterThan(0.85));
      expect(score, lessThan(1.0));
    });

    test('kata berbeda jauh = rendah', () {
      expect(scorePronunciation('resilient', 'banana'), lessThan(0.4));
    });

    test('kosong = 0', () {
      expect(scorePronunciation('', 'hello'), 0);
      expect(scorePronunciation('hello', ''), 0);
    });
  });

  group('pronunciationFeedback', () {
    test('label sesuai rentang skor', () {
      expect(pronunciationFeedback(0.95), 'Mantap!');
      expect(pronunciationFeedback(0.75), 'Bagus, hampir tepat.');
      expect(pronunciationFeedback(0.5), 'Hampir mirip, coba lagi.');
      expect(pronunciationFeedback(0.1), 'Belum terdengar sama. Coba perlahan.');
    });
  });
}
