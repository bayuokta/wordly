/// Validasi form akun. Fungsi murni agar mudah diuji.
library;

abstract final class AuthValidators {
  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]{2,}$');

  /// Pesan error atau `null` bila valid.
  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email wajib diisi.';
    if (v.length > 120) return 'Email terlalu panjang.';
    if (!_emailPattern.hasMatch(v)) return 'Format email tidak valid.';
    return null;
  }

  static String? displayName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Nama wajib diisi.';
    if (v.length < 2) return 'Nama minimal 2 karakter.';
    if (v.length > 40) return 'Nama maksimal 40 karakter.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Kata sandi wajib diisi.';
    if (v.length < 8) return 'Kata sandi minimal 8 karakter.';
    if (v.length > 72) return 'Kata sandi maksimal 72 karakter.';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'Kata sandi harus memuat huruf.';
    if (!RegExp(r'\d').hasMatch(v)) return 'Kata sandi harus memuat angka.';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Ulangi kata sandi.';
    if (value != password) return 'Kata sandi tidak sama.';
    return null;
  }

  /// Normalisasi email: trim + huruf kecil.
  static String normalizeEmail(String value) => value.trim().toLowerCase();
}
