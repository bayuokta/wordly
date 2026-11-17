import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/core/auth/auth_validators.dart';
import 'package:wordly/core/auth/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('hash tidak menyimpan kata sandi asli dan bisa diverifikasi', () {
      const password = 'rahasia123';
      final hash = PasswordHasher.hash(password);

      expect(hash.contains(password), isFalse);
      expect(hash.startsWith('pbkdf2_sha256\$'), isTrue);
      expect(PasswordHasher.verify(password, hash), isTrue);
    });

    test('kata sandi salah ditolak', () {
      final hash = PasswordHasher.hash('rahasia123');
      expect(PasswordHasher.verify('rahasia124', hash), isFalse);
      expect(PasswordHasher.verify('', hash), isFalse);
    });

    test('salt berbeda menghasilkan hash berbeda', () {
      final a = PasswordHasher.hash('rahasia123');
      final b = PasswordHasher.hash('rahasia123');
      expect(a, isNot(b));
      expect(PasswordHasher.verify('rahasia123', a), isTrue);
      expect(PasswordHasher.verify('rahasia123', b), isTrue);
    });

    test('format rusak tidak membuat crash', () {
      expect(PasswordHasher.verify('x', 'bukan-format'), isFalse);
      expect(PasswordHasher.verify('x', 'pbkdf2_sha256\$abc\$zz\$zz'), isFalse);
      expect(PasswordHasher.verify('x', 'pbkdf2_sha256\$1000\$!!!\$!!!'), isFalse);
    });

    test('token sesi acak dan panjang', () {
      final a = PasswordHasher.randomToken();
      final b = PasswordHasher.randomToken();
      expect(a, isNot(b));
      expect(a.length, greaterThan(20));
    });
  });

  group('AuthValidators', () {
    test('email valid & normalisasi', () {
      expect(AuthValidators.email('  Budi@Contoh.COM '), isNull);
      expect(AuthValidators.normalizeEmail('  Budi@Contoh.COM '), 'budi@contoh.com');
    });

    test('email tidak valid ditolak', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('bukan-email'), isNotNull);
      expect(AuthValidators.email('a@b'), isNotNull);
    });

    test('nama punya batas minimal dan maksimal', () {
      expect(AuthValidators.displayName('A'), isNotNull);
      expect(AuthValidators.displayName('Budi'), isNull);
      expect(AuthValidators.displayName('x' * 41), isNotNull);
    });

    test('kata sandi wajib punya huruf dan angka', () {
      expect(AuthValidators.password('pendek1'), isNotNull); // < 8
      expect(AuthValidators.password('abcdefgh'), isNotNull); // tanpa angka
      expect(AuthValidators.password('12345678'), isNotNull); // tanpa huruf
      expect(AuthValidators.password('rahasia123'), isNull);
    });

    test('konfirmasi kata sandi harus sama', () {
      expect(AuthValidators.confirmPassword('rahasia123', 'rahasia123'), isNull);
      expect(AuthValidators.confirmPassword('rahasia124', 'rahasia123'), isNotNull);
      expect(AuthValidators.confirmPassword('', 'rahasia123'), isNotNull);
    });
  });
}
