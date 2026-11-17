import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_surfaces.dart';

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, AppSpacing.xl),
        children: [
          const PageHeader(
            eyebrow: 'Latihan',
            title: 'Practice',
            trailing: Text('0 kata jatuh tempo'),
          ),
          const SizedBox(height: 16),
          AppCard(
            variant: AppCardVariant.primary,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                IconTile(icon: Icons.schedule_rounded, tone: IconTileTone.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tidak ada ulangan hari ini',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('Semua beres. Tambah kata baru untuk mulai.', style: context.tiny),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Pilih latihan'),
          const SizedBox(height: 10),
          const _PracticeTile(
            icon: Icons.layers_outlined,
            tone: IconTileTone.primary,
            title: 'Flashcard',
            description: 'Balik kartu, geser kiri untuk ulangi, kanan untuk paham.',
            phase: 'Fase 7',
          ),
          const SizedBox(height: 10),
          const _PracticeTile(
            icon: Icons.ads_click_outlined,
            tone: IconTileTone.success,
            title: 'Quiz',
            description: '6 mode: pilihan ganda, EN→ID, ID→EN, isian, listening, ejaan.',
            phase: 'Fase 8',
          ),
          const SizedBox(height: 10),
          const _PracticeTile(
            icon: Icons.repeat_rounded,
            tone: IconTileTone.accent,
            title: 'Review terjadwal',
            description: 'Pengulangan berjarak (SM-2) memprioritaskan kata yang sering salah.',
            phase: 'Fase 9',
          ),
        ],
      ),
    );
  }
}

class _PracticeTile extends StatelessWidget {
  const _PracticeTile({
    required this.icon,
    required this.tone,
    required this.title,
    required this.description,
    required this.phase,
  });

  final IconData icon;
  final IconTileTone tone;
  final String title;
  final String description;
  final String phase;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    AppChip(label: phase, height: 20, fontSize: 10),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: context.tiny),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
