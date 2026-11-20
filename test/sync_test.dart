import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wordly/core/sync/api_client.dart';
import 'package:wordly/core/sync/server_settings.dart';
import 'package:wordly/core/sync/sync_config.dart';

void main() {
  test('ApiClient mengirim bearer token dan mem-parsing response', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer token-uji');
      expect(request.url.path, '/api/v1/user/me');
      return http.Response(jsonEncode({'id': 7, 'email': 'a@b.co'}), 200);
    });

    final api = ApiClient(client: client, baseUrl: 'http://uji')..token = 'token-uji';
    final data = await api.get('/api/v1/user/me') as Map<String, dynamic>;
    expect(data['id'], 7);
  });

  test('ApiClient memetakan detail error dari backend', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({'detail': 'Email atau kata sandi salah'}),
        401,
      );
    });

    final api = ApiClient(client: client, baseUrl: 'http://uji');
    expect(
      () => api.post('/api/v1/user/auth/login', {'email': 'a@b.co'}),
      throwsA(isA<ApiException>()
          .having((error) => error.statusCode, 'statusCode', 401)
          .having((error) => error.message, 'message', 'Email atau kata sandi salah')),
    );
  });

  test('base URL default memakai alamat emulator', () {
    expect(SyncConfig.defaultBaseUrl, contains('10.0.2.2'));
    expect(SyncConfig.defaultBaseUrl, contains('8000'));
  });

  test('normalisasi alamat server', () {
    expect(ServerSettings.normalize(' 10.0.2.2:8000/ '), 'http://10.0.2.2:8000');
    expect(
      ServerSettings.normalize('https://wordly.example.com/api/'),
      'https://wordly.example.com/api',
    );
    expect(() => ServerSettings.normalize(''), throwsFormatException);
    expect(() => ServerSettings.normalize('ftp://10.0.2.2'), throwsFormatException);
  });
}
