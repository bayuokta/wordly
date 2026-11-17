import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/date_id.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../settings/presentation/theme_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final themeMode = ref.watch(themeModeProvider);

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
                    Text('Tanpa akun · data di perangkat', style: context.tiny),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _StatTile(label: 'DIPELAJARI', value: '0', caption: 'kata sejauh ini')),
              SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'DIKUASAI', value: '0', caption: 'siap dipakai aktif')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: _StatTile(label: 'AKURASI', value: '—', caption: 'belum ada jawaban')),
              SizedBox(width: 10),
              Expanded(
                child: _StatTile(label: 'STREAK', value: '0', caption: 'rekor pribadi 0', tone: StatTone.accent),
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
                  value: themeMode == ThemeMode.dark ? 'Gelap' : 'Terang',
                  onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.track_changes_rounded,
                  label: 'Target harian',
                  value: '10 kata',
                  tone: IconTileTone.success,
                  onTap: () => _notReady(context, 'Target harian'),
                ),
                const _RowDivider(),
                _SettingsRow(
                  icon: Icons.format_size_rounded,
                  label: 'Ukuran teks',
                  value: 'Normal',
                  tone: IconTileTone.accent,
                  onTap: () => _notReady(context, 'Ukuran teks'),
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

  void _notReady(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature tersedia pada fase pengaturan.')));
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
