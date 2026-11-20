import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'sync_config.dart';

/// Alamat server yang bisa diubah pengguna saat runtime.
class ServerSettings {
  const ServerSettings._();

  static String current(SharedPreferences prefs) =>
      prefs.getString(SyncConfig.baseUrlKey) ?? SyncConfig.defaultBaseUrl;

  /// Rapikan input pengguna; lempar [FormatException] bila tidak valid.
  static String normalize(String raw) {
    var value = raw.trim();
    if (value.isEmpty) throw const FormatException('Alamat server wajib diisi.');
    if (!value.contains('://')) value = 'http://$value';

    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Alamat tidak valid. Contoh: http://10.0.2.2:8000');
    }

    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    final buffer = StringBuffer('${uri.scheme}://${uri.authority}');
    if (path.isNotEmpty) buffer.write(path);
    return buffer.toString();
  }

  /// Cek endpoint health; mengembalikan versi server.
  static Future<String> testConnection(ApiClient api) async {
    final data = await api.get('/api/health') as Map<String, dynamic>;
    return data['version']?.toString() ?? 'ok';
  }

  /// Simpan alamat baru. Token server lama dicabut karena terikat server.
  static Future<void> save(SharedPreferences prefs, String url) async {
    await prefs.setString(SyncConfig.baseUrlKey, ServerSettings.normalize(url));
    await prefs.remove(SyncConfig.tokenKey);
    await prefs.setInt(SyncConfig.lastSeqKey, 0);
    await prefs.setInt(SyncConfig.contentVersionKey, 0);
  }
}
