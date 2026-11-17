/// Skor kemiripan pelafalan (0..1) antara kata target dan hasil pengenalan suara.
///
/// Dipakai latihan pelafalan: cukup untuk memberi umpan balik "mantap/bagus/coba
/// lagi" tanpa memerlukan layanan daring.
library;

String normalizeSpoken(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[.,!?;:"“”()\[\]/-]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

int levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List<int>.generate(b.length + 1, (i) => i);
  var current = List<int>.filled(b.length + 1, 0);

  for (var i = 0; i < a.length; i++) {
    current[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
      final deletion = previous[j + 1] + 1;
      final insertion = current[j] + 1;
      final substitution = previous[j] + cost;
      current[j + 1] = deletion < insertion
          ? (deletion < substitution ? deletion : substitution)
          : (insertion < substitution ? insertion : substitution);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[b.length];
}

/// 1.0 = persis sama, 0.0 = tidak mirip sama sekali.
double scorePronunciation(String target, String spoken) {
  final expected = normalizeSpoken(target);
  final heard = normalizeSpoken(spoken);
  if (expected.isEmpty || heard.isEmpty) return 0;

  final distance = levenshteinDistance(expected, heard);
  final longest = expected.length > heard.length ? expected.length : heard.length;
  final score = 1 - (distance / longest);
  return score.clamp(0.0, 1.0);
}

/// Label umpan balik untuk sebuah skor.
String pronunciationFeedback(double score) {
  if (score >= 0.9) return 'Mantap!';
  if (score >= 0.7) return 'Bagus, hampir tepat.';
  if (score >= 0.45) return 'Hampir mirip, coba lagi.';
  return 'Belum terdengar sama. Coba perlahan.';
}
