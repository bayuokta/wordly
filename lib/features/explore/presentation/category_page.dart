import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/database_providers.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../core/widgets/word_row.dart';

class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key, required this.categoryId, required this.title});

  final int categoryId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoryWordsProvider(categoryId));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: context.palette.iconSoft,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Gagal memuat kategori.\n$error')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.page),
                      child: EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Belum ada kata',
                        message: 'Kategori ini belum memiliki kosakata.',
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      10,
                      AppSpacing.page,
                      AppSpacing.xl,
                    ),
                    children: [
                      Row(
                        children: [
                          Text('${items.length} kata', style: context.tiny),
                          const Spacer(),
                          const AppChip(label: 'A–Z', height: 22, fontSize: 10.5),
                        ],
                      ),
                      const SizedBox(height: 10),
                      WordListCard(
                        items: items,
                        onTapItem: (item) => context.push('/word/${item.word.id}'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
