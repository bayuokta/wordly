import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_providers.dart';
import '../db/user/user_database.dart';
import '../settings/settings_controller.dart';
import 'auth_repository.dart';

/// Status sesi saat ini.
class SessionState {
  const SessionState({
    required this.userId,
    required this.displayName,
    required this.isGuest,
    required this.signedIn,
    this.email,
    this.isInitializing = false,
  });

  /// Sedang memulihkan sesi dari token (auto-login).
  const SessionState.initializing()
    : userId = guestUserId,
      displayName = '',
      isGuest = false,
      signedIn = false,
      email = null,
      isInitializing = true;

  const SessionState.signedOut()
    : userId = guestUserId,
      displayName = '',
      isGuest = false,
      signedIn = false,
      email = null,
      isInitializing = false;

  final int userId;
  final String displayName;
  final String? email;

  /// Tamu: memakai app tanpa akun (data `user_id = 1`).
  final bool isGuest;

  /// Punya akun dan sudah login.
  final bool signedIn;

  /// 	rue saat sesi tersimpan sedang dibaca.
  final bool isInitializing;

  bool get hasAccount => signedIn && !isGuest;

  SessionState copyWith({String? displayName, String? email}) => SessionState(
    userId: userId,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    isGuest: isGuest,
    signedIn: signedIn,
    isInitializing: isInitializing,
  );
}

/// Mengelola login, pendaftaran, tamu, dan auto-login.
///
/// Sesi disimpan di `shared_preferences` (id + token). Token juga dicatat di
/// tabel `sessions` agar bisa dicabut saat keluar.
class SessionController extends Notifier<SessionState> {
  static const _kUserId = 'session_user_id';
  static const _kToken = 'session_token';
  static const _kGuest = 'session_guest';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  @override
  SessionState build() {
    final prefs = _prefs;
    final guest = prefs.getBool(_kGuest) ?? false;
    if (guest) {
      return const SessionState(
        userId: guestUserId,
        displayName: 'Tamu',
        isGuest: true,
        signedIn: false,
      );
    }

    // Auto-login: pulihkan sesi bila token masih ada.
    final userId = prefs.getInt(_kUserId);
    final token = prefs.getString(_kToken);
    if (userId != null && token != null) {
      _restore(userId, token);
      return const SessionState.initializing();
    }
    return const SessionState.signedOut();
  }

  /// Menyegarkan state setelah data akun terbaca (async, tidak memblokir UI).
  Future<void> _restore(int userId, String token) async {
    try {
      final session = await ref.read(userDbProvider).sessionByToken(token);
      if (session == null || session.userId != userId) {
        await _clear();
        return;
      }
      final user = await ref.read(userDbProvider).userById(userId);
      if (user == null) {
        await _clear();
        return;
      }
      await ref.read(userDbProvider).touchSession(session.id);
      if (!ref.mounted) return;
      state = SessionState(
        userId: user.id,
        displayName: user.displayName,
        email: user.email,
        isGuest: false,
        signedIn: true,
      );
    } on Object {
      // Abaikan: pengguna akan diminta masuk kembali.
    }
  }

  Future<void> continueAsGuest() async {
    await _prefs.setBool(_kGuest, true);
    await _prefs.remove(_kUserId);
    await _prefs.remove(_kToken);
    state = const SessionState(
      userId: guestUserId,
      displayName: 'Tamu',
      isGuest: true,
      signedIn: false,
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    final user = await _auth.signIn(email: email, password: password);
    await _openSession(user);
  }

  Future<void> signUp({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final user = await _auth.signUp(email: email, displayName: displayName, password: password);
    await _openSession(user);
  }

  Future<void> _openSession(User user) async {
    final session = await ref.read(userDbProvider).createSession(user.id);
    final prefs = _prefs;
    await prefs.setInt(_kUserId, user.id);
    await prefs.setString(_kToken, session.token);
    await prefs.setBool(_kGuest, false);

    state = SessionState(
      userId: user.id,
      displayName: user.displayName,
      email: user.email,
      isGuest: false,
      signedIn: true,
    );
  }

  Future<void> signOut() async {
    final token = _prefs.getString(_kToken);
    if (token != null) {
      final session = await ref.read(userDbProvider).sessionByToken(token);
      if (session != null) await ref.read(userDbProvider).deleteSession(session.id);
    }
    await _clear();
    state = const SessionState.signedOut();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _auth.changePassword(
      userId: state.userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> deleteAccount() async {
    if (!state.hasAccount) return;
    await _auth.deleteAccount(state.userId);
    await _clear();
    state = const SessionState.signedOut();
  }

  Future<void> _clear() async {
    final prefs = _prefs;
    await prefs.remove(_kUserId);
    await prefs.remove(_kToken);
    await prefs.remove(_kGuest);
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(userDbProvider)),
);
