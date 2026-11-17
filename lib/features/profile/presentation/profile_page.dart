import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/database_providers.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/utils/date_id.dart';
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
          const SizedBox(height: 16),
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

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = DateTime.now();

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
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
                    Text('Belum ada aktivitas', style: context.tiny),
                  ],
                ),
              ),
              const AppChip(label: '0 hari', height: 22, fontSize: 10.5),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: Row(
              children: [
                for (var i = 6; i >= 0; i--)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: p.track,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          DateId.shortDay(today.subtract(Duration(days: i))),
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 10,
                            color: i == 0 ? p.primaryText : p.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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
