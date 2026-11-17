import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/utils/date_id.dart';
import '../../../core/widgets/activity_chart.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_surfaces.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final settings = ref.watch(settingsProvider);
    final snapshot = ref.watch(homeSnapshotProvider).value;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, AppSpacing.xl),
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: p.avatarGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  'W',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.isDark ? const Color(0xFF101728) : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengguna', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 5),
                    Text('Level ${settings.levelLabel} · ${settings.levelDetail}', style: context.tiny),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _AccountCard(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'DIPELAJARI',
                  value: '${snapshot?.learned ?? 0}',
                  caption: 'kata sejauh ini',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'DIKUASAI',
                  value: '${snapshot?.mastered ?? 0}',
                  caption: 'siap dipakai aktif',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'JATUH TEMPO',
                  value: '${snapshot?.due ?? 0}',
                  caption: 'perlu diulang',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'STREAK',
                  value: '${snapshot?.streakDays ?? 0}',
                  caption: 'hari berurutan',
                  tone: StatTone.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _WeeklyActivityCard(),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Pengaturan'),
          const SizedBox(height: 9),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Tema',
                  value: settings.themeMode == ThemeMode.dark ? 'Gelap' : 'Terang',
                  onTap: () => ref.read(settingsProvider.notifier).toggleTheme(),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.school_outlined,
                  label: 'Level belajar',
                  value: settings.levelLabel,
                  onTap: () => _pickLevel(context, ref, settings),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.track_changes_rounded,
                  label: 'Target harian',
                  value: '${settings.dailyGoal} kata',
                  tone: IconTileTone.success,
                  onTap: () => _pickGoal(context, ref, settings),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.format_size_rounded,
                  label: 'Ukuran teks',
                  value: settings.textScaleLabel,
                  tone: IconTileTone.accent,
                  onTap: () => _pickTextScale(context, ref, settings),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.notifications_active_outlined,
                  label: 'Notifikasi harian',
                  value: settings.notificationsEnabled ? 'Aktif' : 'Mati',
                  tone: IconTileTone.warning,
                  onTap: () => _toggleNotifications(context, ref, settings),
                ),
                if (settings.notificationsEnabled) ...[
                  const _RowDivider(),
                  _SettingsRow(
                    icon: Icons.schedule_rounded,
                    label: 'Waktu pengingat',
                    value: settings.notificationTimeLabel,
                    tone: IconTileTone.neutral,
                    onTap: () => _pickNotificationTime(context, ref, settings),
                  ),
                ],
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Tentang Wordly',
                  tone: IconTileTone.primary,
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLevel(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final picked = await _showOptions<String>(
      context,
      title: 'Level belajar',
      options: [
        for (final level in AppSettings.levelOptions)
          (
            value: level,
            label: AppSettings.defaults.copyWith(level: level).levelLabel,
            detail: AppSettings.defaults.copyWith(level: level).levelDetail,
          ),
      ],
      selected: settings.level,
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setLevel(picked);
      ref.invalidate(homeSnapshotProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(browseProvider);
      ref.invalidate(quizPoolProvider);
    }
  }

  Future<void> _pickGoal(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final picked = await _showOptions<int>(
      context,
      title: 'Target harian',
      options: [
        for (final goal in AppSettings.goalOptions)
          (value: goal, label: '$goal kata', detail: 'per hari'),
      ],
      selected: settings.dailyGoal,
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setDailyGoal(picked);
      ref.invalidate(homeSnapshotProvider);
    }
  }

  Future<void> _pickTextScale(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final picked = await _showOptions<double>(
      context,
      title: 'Ukuran teks',
      options: [
        for (final scale in AppSettings.textScaleOptions)
          (
            value: scale,
            label: AppSettings.defaults.copyWith(textScale: scale).textScaleLabel,
            detail: '${(scale * 100).round()}%',
          ),
      ],
      selected: settings.textScale,
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setTextScale(picked);
    }
  }

  Future<void> _toggleNotifications(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final ok = await ref
        .read(settingsProvider.notifier)
        .setNotificationsEnabled(enabled: !settings.notificationsEnabled);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Izin notifikasi ditolak. Aktifkan lewat pengaturan Android.')),
        );
    }
  }

  Future<void> _pickNotificationTime(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.notificationMinutes ~/ 60,
        minute: settings.notificationMinutes % 60,
      ),
      helpText: 'Waktu pengingat harian',
    );
    if (picked != null) {
      await ref
          .read(settingsProvider.notifier)
          .setNotificationTime(picked.hour * 60 + picked.minute);
    }
  }

  /// Bottom sheet pilihan tunggal.
  Future<T?> _showOptions<T>(
    BuildContext context, {
    required String title,
    required List<({T value, String label, String detail})> options,
    required T selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: context.palette.surfaceElevated,
      showDragHandle: true,
      builder: (context) {
        final p = context.palette;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                for (final option in options)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context, option.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.label,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.textPrimary,
                              ),
                            ),
                          ),
                          Text(option.detail, style: context.tiny),
                          const SizedBox(width: 10),
                          Icon(
                            option.value == selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 20,
                            color: option.value == selected ? p.primary : p.chevron,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.palette.surfaceElevated,
        title: const Text('Wordly'),
        content: Text(
          'Aplikasi belajar kosakata Inggris–Indonesia dengan pengulangan berjarak. '
          'Offline-first, tanpa registrasi.\n\nVersi 0.1.0 · Flutter 3.50.0',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

enum StatTone { normal, accent }

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
    this.tone = StatTone.normal,
  });

  final String label;
  final String value;
  final String caption;
  final StatTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.eyebrow.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: tone == StatTone.accent ? p.accentText : p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(caption, style: TextStyle(fontSize: 11, color: p.textSecondary)),
        ],
      ),
    );
  }
}

class _WeeklyActivityCard extends ConsumerWidget {
  const _WeeklyActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final stats = ref.watch(statsProvider(7)).value;
    final reviews = stats?.rangeReviews ?? 0;
    final activeDays = stats?.activeDays ?? 0;
    final today = DateTime.now();

    final bars = stats == null
        ? const <({String label, int value, bool highlight})>[]
        : [
            for (final item in stats.series)
              (
                label: DateId.shortDay(item.date),
                value: item.activity?.reviewsDone ?? 0,
                highlight:
                    item.date.year == today.year &&
                    item.date.month == today.month &&
                    item.date.day == today.day,
              ),
          ];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
      onTap: () => context.push('/statistics'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktivitas 7 hari terakhir',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reviews == 0
                          ? 'Belum ada aktivitas'
                          : '$reviews ulasan · $activeDays hari aktif',
                      style: context.tiny,
                    ),
                  ],
                ),
              ),
              AppChip(label: 'Lihat', height: 22, fontSize: 10.5),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 15, color: p.chevron),
            ],
          ),
          const SizedBox(height: 14),
          if (stats == null)
            const SizedBox(height: 96, child: Center(child: CircularProgressIndicator()))
          else
            ActivityChart(
              bars: bars,
              height: 96,
              maxValue: stats.maxReviews,
            ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.tone = IconTileTone.primary,
  });

  final IconData icon;
  final String label;
  final String? value;
  final IconTileTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            IconTile(icon: icon, tone: tone, size: 30, iconSize: 15),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: p.textPrimary,
                ),
              ),
            ),
            if (value != null) ...[
              Text(value!, style: context.tiny),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, size: 16, color: p.chevron),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(height: 1, color: context.palette.divider),
    );
  }
}

/// Kartu akun: status tamu, tombol masuk/daftar, atau aksi akun.
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final session = ref.watch(sessionProvider);

    if (!session.hasAccount) {
      return AppCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconTile(icon: Icons.person_outline_rounded, tone: IconTileTone.accent),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode tamu',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('Progres tersimpan di perangkat ini saja.', style: context.tiny),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Masuk',
                    size: AppButtonSize.small,
                    variant: AppButtonVariant.ghost,
                    onPressed: () => context.push('/auth'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Daftar',
                    size: AppButtonSize.small,
                    onPressed: () => context.push('/auth'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: p.avatarGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  session.displayName.isEmpty ? '?' : session.displayName.characters.first.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.isDark ? const Color(0xFF101728) : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.displayName,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(session.email ?? '', style: context.tiny),
                  ],
                ),
              ),
              AppChip(label: 'Akun lokal', height: 20, fontSize: 9.5),
            ],
          ),
          const SizedBox(height: 6),
          _AccountAction(
            icon: Icons.password_rounded,
            label: 'Ubah kata sandi',
            onTap: () => _changePassword(context, ref),
          ),
          _AccountAction(
            icon: Icons.logout_rounded,
            label: 'Keluar',
            onTap: () => _signOut(context, ref),
          ),
          _AccountAction(
            icon: Icons.delete_outline_rounded,
            label: 'Hapus akun',
            danger: true,
            onTap: () => _deleteAccount(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.palette.surfaceElevated,
        title: const Text('Keluar dari akun?'),
        content: const Text('Progres akun tetap tersimpan dan bisa dilanjutkan saat masuk lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionProvider.notifier).signOut();
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.palette.surfaceElevated,
        title: const Text('Hapus akun?'),
        content: const Text(
          'Semua progres akun ini (favorit, riwayat, jadwal ulangan) akan dihapus permanen. '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: context.palette.errorText)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionProvider.notifier).deleteAccount();
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          backgroundColor: dialogContext.palette.surfaceElevated,
          title: const Text('Ubah kata sandi'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: current,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Kata sandi saat ini'),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Kata sandi saat ini wajib diisi.' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: next,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Kata sandi baru'),
                  validator: (value) {
                    if ((value ?? '').length < 8) return 'Minimal 8 karakter.';
                    if (!RegExp(r'[A-Za-z]').hasMatch(value!) ||
                        !RegExp(r'\d').hasMatch(value)) {
                      return 'Harus memuat huruf dan angka.';
                    }
                    return null;
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: TextStyle(fontSize: 12, color: dialogContext.palette.errorText)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            TextButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                try {
                  await ref.read(sessionProvider.notifier).changePassword(
                    currentPassword: current.text,
                    newPassword: next.text,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('Kata sandi diperbarui.')));
                  }
                } on AuthException catch (e) {
                  setState(() => error = e.message);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    current.dispose();
    next.dispose();
  }
}

class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = danger ? p.errorText : p.textPrimary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 16, color: danger ? p.errorText : p.iconSoft),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 15, color: danger ? p.errorText : p.chevron),
          ],
        ),
      ),
    );
  }
}
