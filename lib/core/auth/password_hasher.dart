import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hash kata sandi lokal: PBKDF2-HMAC-SHA256.
///
/// Format tersimpan: `pbkdf2_sha256$<iterasi>$<salt b64>$<hash b64>`.
/// Digunakan hanya untuk profil lokal (bukan autentikasi server).
abstract final class PasswordHasher {
  static const int iterations = 120000;
  static const int saltLength = 16;
  static const int keyLength = 32;
  static const String _scheme = 'pbkdf2_sha256';

  static String hash(String password) {
    final salt = _randomBytes(saltLength);
    final derived = _pbkdf2(utf8.encode(password), salt, iterations, keyLength);
    return '$_scheme\$$iterations\$${base64Encode(salt)}\$${base64Encode(derived)}';
  }

  /// Membandingkan kata sandi dengan hash tersimpan (waktu konstan).
  static bool verify(String password, String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;

    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds < 1000) return false;

    try {
      final salt = base64Decode(parts[2]);
      final expected = base64Decode(parts[3]);
      final actual = _pbkdf2(utf8.encode(password), salt, rounds, expected.length);
      return _constantTimeEquals(actual, expected);
    } on FormatException {
      return false;
    }
  }

  /// Token sesi acak 32 byte (base64url).
  static String randomToken() => base64UrlEncode(_randomBytes(32));

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  static Uint8List _pbkdf2(List<int> password, List<int> salt, int rounds, int length) {
    final hmac = Hmac(sha256, password);
    const hashLength = 32;
    final blockCount = (length / hashLength).ceil();
    final output = BytesBuilder();

    for (var block = 1; block <= blockCount; block++) {
      final blockIndex = Uint8List(4)..buffer.asByteData().setUint32(0, block, Endian.big);
      var u = Uint8List.fromList(hmac.convert([...salt, ...blockIndex]).bytes);
      final t = Uint8List.fromList(u);

      for (var round = 1; round < rounds; round++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var i = 0; i < t.length; i++) {
          t[i] ^= u[i];
        }
      }
      output.add(t);
    }

    return Uint8List.fromList(output.toBytes().sublist(0, length));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
