// Validator konten kosakata.
//
// Jalankan: dart run tool/validate_vocab.dart
//
// Memeriksa: field wajib, format IPA, level/CEFR/POS yang sah, kata duplikat,
// sinonim/antonim yang tidak boleh sama dengan kata itu sendiri, serta
// konsistensi jumlah kata per kategori.
import 'dart:convert';
import 'dart:io';

const Set<String> _levels = {'beginner', 'intermediate', 'advanced'};
const Set<String> _cefr = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
const Set<String> _pos = {
  'noun',
  'verb',
  'adjective',
  'adverb',
  'pronoun',
  'preposition',
  'conjunction',
  'interjection',
  'phrasal_verb',
  'idiom',
};

const List<String> _required = [
  'id',
  'word',
  'translation',
  'definition',
  'pos',
  'level',
  'cefr',
  'example',
  'example_id',
];

final RegExp _ipa = RegExp(r'^/[^/]+/$');
const int _minWordsPerCategory = 10;

void main(List<String> args) {
  final dir = Directory(args.isNotEmpty ? args.first : 'assets/vocab');
  if (!dir.existsSync()) {
    stderr.writeln('Folder tidak ditemukan: ${dir.path}');
    exit(1);
  }

  final files = dir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stderr.writeln('Tidak ada berkas JSON di ${dir.path}');
    exit(1);
  }

  final errors = <String>[];
  final warnings = <String>[];
  final seenIds = <int, String>{};
  final seenWords = <String, String>{};
  final categoryIds = <int, String>{};
  var totalWords = 0;

  for (final file in files) {
    final name = file.uri.pathSegments.last;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    } on FormatException catch (error) {
      errors.add('$name: JSON tidak valid (${error.message})');
      continue;
    }

    final category = data['category'];
    if (category is! Map<String, dynamic>) {
      errors.add('$name: bagian "category" tidak ada');
      continue;
    }

    final categoryId = category['id'];
    final slug = category['slug'];
    if (categoryId is! int || slug is! String) {
      errors.add('$name: "category.id"/"category.slug" wajib');
      continue;
    }
    if (categoryIds.containsKey(categoryId)) {
      errors.add('$name: id kategori $categoryId sudah dipakai ${categoryIds[categoryId]}');
    }
    categoryIds[categoryId] = name;
    for (final field in ['name', 'description']) {
      final value = category[field];
      if (value is! String || value.trim().isEmpty) {
        errors.add('$name: "category.$field" wajib diisi');
      }
    }

    final words = data['words'];
    if (words is! List) {
      errors.add('$name: "words" harus berupa array');
      continue;
    }
    if (words.length < _minWordsPerCategory) {
      warnings.add(
        '$name: baru ${words.length} kata (target minimal $_minWordsPerCategory)',
      );
    }
    totalWords += words.length;

    for (final (index, raw) in words.indexed) {
      final where = '$name#${index + 1}';
      if (raw is! Map<String, dynamic>) {
        errors.add('$where: entri bukan objek');
        continue;
      }

      for (final field in _required) {
        final value = raw[field];
        if (value == null || (value is String && value.trim().isEmpty)) {
          errors.add('$where: field "$field" wajib diisi');
        }
      }

      final id = raw['id'];
      final word = raw['word'];
      if (id is! int) {
        errors.add('$where: "id" harus angka');
        continue;
      }
      if (seenIds.containsKey(id)) {
        errors.add('$where: id $id duplikat dengan ${seenIds[id]}');
      }
      seenIds[id] = where;

      if (word is! String) continue;
      final normalized = word.trim().toLowerCase();
      final key = '$normalized|${raw['pos']}|$categoryId';
      if (seenWords.containsKey(key)) {
        errors.add('$where: "$word" duplikat dengan ${seenWords[key]}');
      }
      seenWords[key] = where;

      final ipa = raw['ipa'];
      if (ipa != null && (ipa is! String || !_ipa.hasMatch(ipa))) {
        errors.add('$where: format IPA tidak sah ($ipa)');
      }

      final level = raw['level'];
      if (level is String && !_levels.contains(level)) {
        errors.add('$where: level "$level" tidak dikenal');
      }

      final cefr = raw['cefr'];
      if (cefr is String && !_cefr.contains(cefr)) {
        errors.add('$where: CEFR "$cefr" tidak dikenal');
      }

      final pos = raw['pos'];
      if (pos is String && !_pos.contains(pos)) {
        errors.add('$where: part of speech "$pos" tidak dikenal');
      }

      for (final listField in ['synonyms', 'antonyms']) {
        final list = raw[listField];
        if (list == null) continue;
        if (list is! List) {
          errors.add('$where: "$listField" harus array');
          continue;
        }
        for (final item in list) {
          if (item is! String) {
            errors.add('$where: "$listField" berisi non-string');
          } else if (item.trim().toLowerCase() == normalized) {
            errors.add('$where: "$listField" tidak boleh memuat kata itu sendiri');
          }
        }
      }
    }
  }

  for (final warning in warnings) {
    stdout.writeln('! $warning');
  }
  for (final error in errors) {
    stderr.writeln('x $error');
  }

  stdout.writeln(
    '\n${files.length} kategori · $totalWords kata · ${errors.length} error · '
    '${warnings.length} peringatan',
  );

  if (errors.isNotEmpty) exit(1);
}
