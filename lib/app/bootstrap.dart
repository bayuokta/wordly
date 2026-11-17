import 'dart:developer' as developer;

import '../core/db/content/content_database.dart';
import '../core/db/content/vocab_seeder.dart';
import '../core/db/user/user_database.dart';

/// Hasil inisialisasi database.
class AppDatabases {
  const AppDatabases({required this.content, required this.user});

  final ContentDatabase content;
  final UserDatabase user;
}

/// Membuka kedua database dan memastikan konten kosakata sudah terisi.
///
/// Dipanggil sekali sebelum `runApp`, sehingga seluruh layar bisa mengakses
/// data secara sinkron tanpa status loading di awal.
Future<AppDatabases> bootstrapDatabases({bool seed = true}) async {
  final content = ContentDatabase();
  final user = UserDatabase();

  if (seed) {
    try {
      final imported = await VocabSeeder(db: content).seedIfNeeded();
      developer.log(
        imported ? 'Konten kosakata diimpor dari aset' : 'Konten kosakata sudah mutakhir',
        name: 'wordly.bootstrap',
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'Gagal menyiapkan konten kosakata',
        name: 'wordly.bootstrap',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  return AppDatabases(content: content, user: user);
}
