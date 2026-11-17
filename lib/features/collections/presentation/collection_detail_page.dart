import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/tts_service.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_surfaces.dart';

/// Isi satu koleksi: daftar kata + hapus dari koleksi.
class CollectionDetailPage extends ConsumerWidget {
  const CollectionDetailPage({super.key, required this.collectionId, required this.title});

  final int collectionId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collectionItemsProvider(collectionId));
    final p = context.palette;

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
                    color: p.iconSoft,
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
                  async.maybeWhen(
                    data: (items) => Text('${items.length} kata', style: context.tiny),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Gagal memuat koleksi.\n$error')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.page),
                      child: EmptyState(
                        icon: Icons.playlist_add_rounded,
                        title: 'Koleksi masih kosong',
                        message:
                            'Buka sebuah kata, lalu pilih "Simpan ke koleksi" untuk menambahkannya ke sini.',
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      10,
                      AppSpacing.page,
                      AppSpacing.xl,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AppCard(
                        radius: 16,
                        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                        onTap: () => context.push('/word/${item.word.id}'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.word.word,
                                    style: TextStyle(
                                      fontFamily: AppFonts.display,
                                      fontSize: 15,
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
                                    style: context.tiny,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => speakWord(context, item.word.word),
                              icon: Icon(
                                Icons.volume_up_outlined,
                                size: 18,
                                color: p.primaryText,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await ref
                                    .read(vocabRepositoryProvider)
                                    .removeFromCollection(collectionId, item.word.id);
                                ref.invalidate(collectionItemsProvider(collectionId));
                                ref.invalidate(collectionsProvider);
                              },
                              icon: Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 18,
                                color: p.textDim,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
