import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/auth_validators.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/sync/api_client.dart';
import '../../../core/sync/server_settings.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../core/widgets/app_button.dart';

enum _Mode { signIn, signUp }

/// Form masuk & daftar (satu layar, dua mode).
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _server = TextEditingController();

  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  bool _obscure = true;
  bool _testingServer = false;
  String? _error;
  String? _serverStatus;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _server.text = ServerSettings.current(ref.read(sharedPreferencesProvider));
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    _confirm.dispose();
    _server.dispose();
    super.dispose();
  }

  void _switchMode(_Mode mode) {
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  /// Simpan alamat server bila berubah. Token lama dicabut oleh [ServerSettings.save].
  Future<bool> _persistServer() async {
    try {
      final url = ServerSettings.normalize(_server.text);
      final prefs = ref.read(sharedPreferencesProvider);
      if (url != ServerSettings.current(prefs)) {
        await ServerSettings.save(prefs, url);
        ref.invalidate(apiClientProvider);
      }
      if (mounted) setState(() => _serverError = null);
      return true;
    } on FormatException catch (error) {
      if (mounted) setState(() => _serverError = error.message);
      return false;
    }
  }

  Future<void> _testServer() async {
    FocusScope.of(context).unfocus();
    if (_testingServer) return;
    if (!await _persistServer()) return;

    setState(() {
      _testingServer = true;
      _serverStatus = null;
    });
    final api = ApiClient(baseUrl: ServerSettings.normalize(_server.text));
    try {
      final version = await ServerSettings.testConnection(api);
      if (!mounted) return;
      setState(() => _serverStatus = 'Terhubung · v$version');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _serverError = error.toString());
    } finally {
      api.dispose();
      if (mounted) setState(() => _testingServer = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!await _persistServer()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final controller = ref.read(sessionProvider.notifier);
      if (_mode == _Mode.signUp) {
        await controller.signUp(
          email: _email.text,
          displayName: _name.text,
          password: _password.text,
        );
      } else {
        await controller.signIn(email: _email.text, password: _password.text);
      }
      // Gate di `app.dart` yang memindahkan pengguna ke Home.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object {
      if (mounted) setState(() => _error = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueAsGuest() async {
    await ref.read(sessionProvider.notifier).continueAsGuest();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isSignUp = _mode == _Mode.signUp;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 20, AppSpacing.page, AppSpacing.xl),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: p.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'W',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: p.isDark ? const Color(0xFF0B1020) : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wordly',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 17,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('Akun lokal · sinkron opsional', style: context.tiny),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              isSignUp ? 'Buat akun' : 'Masuk',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              isSignUp
                  ? 'Akun ini disimpan di perangkat. Progres belajar dipisahkan per akun.'
                  : 'Masuk untuk melanjutkan progresmu di perangkat ini.',
              style: context.small,
            ),
            const SizedBox(height: 20),
            _ModeSwitch(mode: _mode, onChanged: _switchMode),
            const SizedBox(height: 14),
            _serverCard(context),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (isSignUp) ...[
                    _Field(
                      controller: _name,
                      label: 'Nama',
                      hint: 'Nama panggilan',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: AuthValidators.displayName,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _Field(
                    controller: _email,
                    label: 'Email',
                    hint: 'nama@contoh.com',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: AuthValidators.email,
                    enabled: !_busy,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _password,
                    label: 'Kata sandi',
                    hint: isSignUp ? 'Minimal 8 karakter, ada huruf & angka' : 'Kata sandi',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    textInputAction: isSignUp ? TextInputAction.next : TextInputAction.done,
                    onSubmitted: isSignUp ? null : (_) => _submit(),
                    validator: isSignUp
                        ? AuthValidators.password
                        : (value) => (value ?? '').isEmpty ? 'Kata sandi wajib diisi.' : null,
                    enabled: !_busy,
                    trailing: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: context.palette.chevron,
                      ),
                    ),
                  ),
                  if (isSignUp) ...[
                    const SizedBox(height: 12),
                    _Field(
                      controller: _confirm,
                      label: 'Ulangi kata sandi',
                      hint: 'Ketik ulang kata sandi',
                      icon: Icons.lock_reset_rounded,
                      obscure: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (value) => AuthValidators.confirmPassword(value, _password.text),
                      enabled: !_busy,
                    ),
                  ],
                ],
              ),
            ),
            if (_error case final message?) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.errorSoft,
                  border: Border.all(color: p.errorLine),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 17, color: p.errorText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(fontSize: 12.5, height: 1.4, color: p.errorText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: isSignUp ? 'Daftar' : 'Masuk',
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Lanjut sebagai tamu',
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              onPressed: _busy ? null : _continueAsGuest,
            ),
            const SizedBox(height: 16),
            Text(
              'Kata sandi di-hash di perangkat. Saat sinkron aktif, kredensial '
              'dikirim sekali ke server yang kamu pilih.',
              textAlign: TextAlign.center,
              style: context.tiny,
            ),
          ],
        ),
      ),
    );
  }

  Widget _serverCard(BuildContext context) {
    final p = context.palette;
    final status = _serverStatus ?? _serverError ?? 'Belum diuji';
    final statusColor = _serverStatus != null
        ? p.successText
        : (_serverError != null ? p.errorText : p.textDim);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.fieldBg,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dns_outlined, size: 16, color: p.textSecondary),
              const SizedBox(width: 8),
              Text('Server sinkronisasi', style: context.small),
            ],
          ),
          const SizedBox(height: 10),
          _Field(
            controller: _server,
            label: 'Alamat server',
            hint: 'http://10.0.2.2:8000',
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _testServer(),
            enabled: !_busy && !_testingServer,
            validator: (_) => null,
          ),
          const SizedBox(height: 6),
          Text(
            'Emulator: 10.0.2.2 · HP fisik: IP LAN komputer',
            style: context.tiny,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppButton(
                label: 'Uji koneksi',
                size: AppButtonSize.small,
                variant: AppButtonVariant.ghost,
                loading: _testingServer,
                expand: false,
                onPressed: _busy ? null : _testServer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(fontSize: 11.5, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final _Mode mode;
  final ValueChanged<_Mode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget tab(_Mode value, String label) {
      final active = mode == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            height: 38,
            decoration: BoxDecoration(
              color: active ? p.tabOnBg : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: active ? p.tabOnLine : Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12.5,
                height: 1,
                fontWeight: FontWeight.w600,
                color: active ? p.textPrimary : p.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.fieldBg,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tab(_Mode.signIn, 'Masuk'),
          tab(_Mode.signUp, 'Daftar'),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.enabled = true,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    InputDecoration decoration(String labelText, {String? hintText, Widget? suffix}) {
      return InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 18, color: p.textSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: p.fieldBg,
        labelStyle: TextStyle(fontFamily: AppFonts.body, fontSize: 13, color: p.textSecondary),
        hintStyle: TextStyle(fontFamily: AppFonts.body, fontSize: 13, color: p.textDim),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.primaryLine),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.errorLine),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.errorLine),
        ),
        errorStyle: TextStyle(fontSize: 11, color: p.errorText),
      );
    }

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autocorrect: false,
      style: TextStyle(fontFamily: AppFonts.body, fontSize: 14, color: p.textPrimary),
      cursorColor: p.primary,
      decoration: decoration(label, hintText: hint, suffix: trailing),
    );
  }
}
