/// Konfigurasi koneksi ke backend Wordly Admin.
///
/// Nilai awal bisa diubah saat build:
///   flutter run --dart-define=WORDLY_API_BASE=http://192.168.1.5:8000
/// Pengguna juga bisa mengubah alamat saat runtime lewat halaman masuk/Profil.
class SyncConfig {
  const SyncConfig._();

  static const String defaultBaseUrl = String.fromEnvironment(
    'WORDLY_API_BASE',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String baseUrlKey = 'sync_base_url';
  static const String tokenKey = 'sync_server_token';
  static const String lastSeqKey = 'sync_last_seq';
  static const String contentVersionKey = 'sync_content_version';
}
