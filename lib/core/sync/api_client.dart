import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sync_config.dart';

/// Kesalahan API dengan pesan siap ditampilkan di UI.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Client HTTP ringan untuk endpoint `/api/v1` Wordly Admin.
///
/// Tidak dipanggil dari alur belajar; hanya oleh lapisan sinkronisasi.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? SyncConfig.baseUrl;

  final http.Client _client;
  final String baseUrl;
  String? token;

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, Object body) => _request('POST', path, body: body);

  Future<dynamic> _request(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final currentToken = token;
    if (currentToken != null && currentToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $currentToken';
    }

    late final http.Response response;
    try {
      final future = method == 'GET'
          ? _client.get(uri, headers: headers)
          : _client.post(uri, headers: headers, body: jsonEncode(body));
      response = await future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } on Object catch (error) {
      throw ApiException('Tidak dapat terhubung ke server: $error');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    var detail = 'Permintaan gagal (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        detail = decoded['detail'].toString();
      }
    } on Object {
      // Biarkan pesan default.
    }
    throw ApiException(detail, statusCode: response.statusCode);
  }

  void dispose() => _client.close();
}
