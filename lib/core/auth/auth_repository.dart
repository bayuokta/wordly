import '../db/user/user_database.dart';
import 'auth_validators.dart';
import 'password_hasher.dart';

/// Kesalahan autentikasi dengan pesan siap tampil di UI.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pendaftaran & login lokal. Tidak ada jaringan.
class AuthRepository {
  AuthRepository(this.db);

  final UserDatabase db;

  Future<User> signUp({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final emailError = AuthValidators.email(email);
    if (emailError != null) throw AuthException(emailError);
    final nameError = AuthValidators.displayName(displayName);
    if (nameError != null) throw AuthException(nameError);
    final passwordError = AuthValidators.password(password);
    if (passwordError != null) throw AuthException(passwordError);

    if (await db.emailExists(email)) {
      throw const AuthException('Email sudah terdaftar. Silakan masuk.');
    }

    try {
      return await db.createUser(email: email, displayName: displayName, password: password);
    } on Object {
      // Bisa terjadi bila dua proses menulis bersamaan (UNIQUE email).
      throw const AuthException('Email sudah terdaftar. Silakan masuk.');
    }
  }

  Future<User> signIn({required String email, required String password}) async {
    if ((email).trim().isEmpty || password.isEmpty) {
      throw const AuthException('Email dan kata sandi wajib diisi.');
    }

    final user = await db.userByEmail(AuthValidators.normalizeEmail(email));
    // Pesan generik: jangan bocorkan apakah email terdaftar atau bukan.
    if (user == null || user.passwordHash == null) {
      throw const AuthException('Email atau kata sandi salah.');
    }
    if (!PasswordHasher.verify(password, user.passwordHash!)) {
      throw const AuthException('Email atau kata sandi salah.');
    }

    await db.updateLastLogin(user.id);
    return user;
  }

  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await db.userById(userId);
    if (user == null || user.passwordHash == null) {
      throw const AuthException('Akun tidak ditemukan.');
    }
    if (!PasswordHasher.verify(currentPassword, user.passwordHash!)) {
      throw const AuthException('Kata sandi saat ini salah.');
    }
    final error = AuthValidators.password(newPassword);
    if (error != null) throw AuthException(error);

    await db.updatePassword(userId, newPassword);
  }

  Future<void> deleteAccount(int userId) => db.deleteAccount(userId);
}
