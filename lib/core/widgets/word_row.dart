import 'package:material_ui/material_ui.dart';

import '../db/vocab_repository.dart';
import '../srs/sm2.dart';
import '../design/app_palette.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';
import 'app_chip.dart';

/// Satu baris kata di daftar (dipakai Home, Explore, Kata Saya).
class WordRow extends StatelessWidget {
  const WordRow({
    super.key,
    required this.item,
    this.onTap,
    this.showBookmark = false,
    this.showStatus = true,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  final WordListItem item;
  final VoidCallback? onTap;
  final bool showBookmark;
  final bool showStatus;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = item.progress;
    final hasProgress = progress != null && item.status != WordStatus.newWord;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (showBookmark) ...[
              Icon(
                progress?.isFavorite ?? false ? Icons.bookmark : Icons.bookmark_border,
                size: 14,
                color: progress?.isFavorite ?? false ? p.primary : p.chevron,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.word.word,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.word.translation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      height: 1.35,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (showStatus && hasProgress) ...[
              const SizedBox(width: 8),
              StatusPill(status: item.status),
            ],
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 15, color: p.chevron),
          ],
        ),
      ),
    );
  }
}

/// Daftar kata di dalam satu card, dengan garis pemisah antar baris.
class WordListCard extends StatelessWidget {
  const WordListCard({super.key, required this.items, required this.onTapItem});

  final List<WordListItem> items;
  final ValueChanged<WordListItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(height: 1, color: context.palette.divider),
              ),
            WordRow(
              item: item,
              onTap: () => onTapItem(item),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ],
        ],
      ),
    );
  }
}
