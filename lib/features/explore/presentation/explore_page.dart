import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/content/content_database.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_progress.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../core/widgets/word_row.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  static const List<(String label, String? value)> _levels = [
    ('Semua', null),
    ('Pemula', 'beginner'),
    ('Menengah', 'intermediate'),
    ('Mahir', 'advanced'),
  ];

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).update(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final level = ref.watch(levelFilterProvider);
    final categories = ref.watch(categoriesProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, AppSpacing.xl),
        children: [
          PageHeader(
            eyebrow: 'Kamus',
            title: 'Jelajahi',
            trailing: categories.maybeWhen(
              data: (list) {
                final total = list.fold<int>(0, (sum, item) => sum + item.total);
                return Text('${list.length} kategori · $total kata');
              },
              orElse: () => const Text('memuat…'),
            ),
          ),
          const SizedBox(height: 14),
          _SearchField(controller: _controller, onChanged: _onQueryChanged),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, value) in _levels)
                _LevelChip(
                  label: label,
                  selected: level == value,
                  onTap: () => ref.read(levelFilterProvider.notifier).select(value),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (query.isNotEmpty)
            _SearchResults(query: query, level: level)
          else ...[
            const SectionHeader(title: 'Kategori'),
            const SizedBox(height: 10),
            categories.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text('Gagal memuat kategori: $error', style: context.tiny),
              data: (list) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 112,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) =>
                    _CategoryCard(category: list[index]),
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: level == null ? 'Semua kata' : 'Kata ${_levels.firstWhere((e) => e.$2 == level).$1}',
            ),
            const SizedBox(height: 10),
            _BrowseList(level: level),
          ],
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppChip(
        label: label,
        height: 30,
        fontSize: 12,
        tone: selected ? AppChipTone.primary : AppChipTone.neutral,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
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
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontFamily: AppFonts.body, fontSize: 13, color: p.textPrimary),
              cursorColor: p.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari kata Inggris atau Indonesia',
                hintStyle: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: p.textSecondary,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Icon(Icons.close_rounded, size: 16, color: p.chevron),
            ),
        ],
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category});

  final CategoryCount category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;

    return AppCard(
      radius: 17,
      padding: const EdgeInsets.all(13),
      onTap: () => context.push('/category/${category.id}?title=${Uri.encodeComponent(category.name)}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: _icon(category.slug), size: 32, iconSize: 17),
          const SizedBox(height: 8),
          Text(
            category.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: p.textPrimary,
            ),
          ),
          const Spacer(),
          AppProgressBar(value: category.progress, height: 4),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${category.learned} / ${category.total} kata',
                  style: TextStyle(fontSize: 10.5, color: p.textDim),
                ),
              ),
              Text(
                '${(category.progress * 100).round()}%',
                style: TextStyle(fontSize: 10.5, color: p.textDim),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _icon(String slug) => switch (slug) {
    'daily-conversation' => Icons.forum_outlined,
    'business-english' => Icons.work_outline_rounded,
    'academic-english' => Icons.menu_book_outlined,
    'travel' => Icons.flight_takeoff_rounded,
    'technology' => Icons.memory_rounded,
    'food-drinks' => Icons.local_cafe_outlined,
    'education' => Icons.school_outlined,
    'health' => Icons.monitor_heart_outlined,
    'nature' => Icons.eco_outlined,
    'feelings-emotions' => Icons.favorite_border_rounded,
    'phrasal-verbs' => Icons.swap_horiz_rounded,
    'idioms' => Icons.format_quote_rounded,
    _ => Icons.auto_awesome_outlined,
  };
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.level});

  final String query;
  final String? level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(searchResultsProvider((query: query, level: level)));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Pencarian gagal: $error', style: context.tiny),
      data: (items) {
        if (items.isEmpty) {
          return const AppCard(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Kata tidak ditemukan',
              message: 'Periksa ejaan atau ubah filter level.',
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${items.length} hasil untuk "$query"', style: context.tiny),
            const SizedBox(height: 10),
            WordListCard(
              items: items,
              onTapItem: (item) => context.push('/word/${item.word.id}'),
            ),
          ],
        );
      },
    );
  }
}

class _BrowseList extends ConsumerWidget {
  const _BrowseList({required this.level});

  final String? level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(browseProvider(level));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Gagal memuat kata: $error', style: context.tiny),
      data: (items) {
        if (items.isEmpty) {
          return const AppCard(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Belum ada kata',
              message: 'Kosakata untuk level ini belum tersedia.',
            ),
          );
        }
        final visible = items.take(30).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WordListCard(
              items: visible,
              onTapItem: (item) => context.push('/word/${item.word.id}'),
            ),
            if (items.length > visible.length) ...[
              const SizedBox(height: 8),
              Text(
                'Menampilkan ${visible.length} dari ${items.length} kata.',
                style: context.tiny,
              ),
            ],
          ],
        );
      },
    );
  }
}
