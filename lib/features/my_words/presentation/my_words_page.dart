import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/database_providers.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../core/widgets/word_row.dart';

class MyWordsPage extends ConsumerStatefulWidget {
  const MyWordsPage({super.key});

  @override
  ConsumerState<MyWordsPage> createState() => _MyWordsPageState();
}

class _MyWordsPageState extends ConsumerState<MyWordsPage> {
  static const List<String> _tabs = ['Favorit', 'Riwayat', 'Belum', 'Dikuasai'];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = switch (_index) {
      0 => ref.watch(favoritesProvider),
      1 => ref.watch(historyProvider),
      2 => ref.watch(learningWordsProvider),
      _ => ref.watch(masteredWordsProvider),
    };

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: p.primary,
        backgroundColor: p.surface,
        onRefresh: () async {
          ref.invalidate(favoritesProvider);
          ref.invalidate(historyProvider);
          ref.invalidate(learningWordsProvider);
          ref.invalidate(masteredWordsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, AppSpacing.xl),
          children: [
            const PageHeader(eyebrow: 'Koleksi pribadi', title: 'Kata Saya'),
            const SizedBox(height: 14),
            _SegmentedTabs(
              tabs: _tabs,
              index: _index,
              onChanged: (value) => setState(() => _index = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Urutkan: terbaru',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                ),
                const Spacer(),
                items.maybeWhen(
                  data: (list) => Text('${list.length} kata', style: context.tiny),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            items.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text('Gagal memuat kata: $error', style: context.tiny),
              data: (list) {
                if (list.isEmpty) {
                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                    child: EmptyState(
                      icon: switch (_index) {
                        0 => Icons.bookmark_border_rounded,
                        1 => Icons.history_rounded,
                        2 => Icons.auto_stories_outlined,
                        _ => Icons.verified_outlined,
                      },
                      title: 'Belum ada kata di ${_tabs[_index].toLowerCase()}',
                      message: _messageFor(_index),
                    ),
                  );
                }
                return WordListCard(
                  items: list,
                  onTapItem: (item) => context.push('/word/${item.word.id}'),
                );
              },
            ),
            const SizedBox(height: 12),
            _CollectionsCard(
              onTap: () {
                ref.invalidate(collectionsProvider);
                context.push('/collections');
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _messageFor(int index) => switch (index) {
    0 => 'Tekan ikon bookmark di halaman kata untuk menyimpannya di sini.',
    1 => 'Kata yang sudah kamu ulang akan muncul di riwayat ini.',
    2 => 'Kata yang sedang dipelajari dan belum dikuasai muncul di sini.',
    _ => 'Kata dengan interval ulangan panjang dan sudah stabil.',
  };
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.tabs, required this.index, required this.onChanged});

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.fieldBg,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 32,
                  decoration: BoxDecoration(
                    color: i == index ? p.tabOnBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: i == index ? p.tabOnLine : Colors.transparent),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11.5,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: i == index ? p.textPrimary : p.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu ringkas menuju daftar koleksi.
class _CollectionsCard extends ConsumerWidget {
  const _CollectionsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final collections = ref.watch(collectionsProvider).value;
    final totalWords = collections?.fold<int>(0, (sum, item) => sum + item.wordCount) ?? 0;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          const IconTile(icon: Icons.folder_outlined),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Koleksi saya',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  collections == null
                      ? 'Memuat…'
                      : collections.isEmpty
                      ? 'Belum ada koleksi'
                      : '${collections.length} koleksi · $totalWords kata',
                  style: context.tiny,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 15, color: p.chevron),
        ],
      ),
    );
  }
}
