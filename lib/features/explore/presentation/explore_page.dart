import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_surfaces.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  static const List<String> _levels = ['Semua', 'Pemula', 'Menengah', 'Mahir'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, AppSpacing.xl),
        children: [
          const PageHeader(
            eyebrow: 'Kamus',
            title: 'Jelajahi',
            trailing: Text('13 kategori'),
          ),
          const SizedBox(height: 14),
          const _SearchField(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, level) in _levels.indexed)
                AppChip(
                  label: level,
                  height: 30,
                  fontSize: 12,
                  tone: i == 0 ? AppChipTone.primary : AppChipTone.neutral,
                ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Kategori'),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Icon(Icons.category_outlined, size: 24, color: p.textDim),
                const SizedBox(height: 10),
                Text(
                  'Kategori belum dimuat',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '13 kategori (Daily Conversation, Business, Travel, dst.) akan '
                  'terisi dari basis data kosakata.',
                  textAlign: TextAlign.center,
                  style: context.tiny,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Pencarian aktif setelah basis data kosakata siap.')),
          );
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: p.cardShadow,
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 17, color: p.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cari kata Inggris atau Indonesia',
                style: TextStyle(fontFamily: AppFonts.body, fontSize: 13, color: p.textSecondary),
              ),
            ),
            Icon(Icons.tune_rounded, size: 15, color: p.chevron),
          ],
        ),
      ),
    );
  }
}
