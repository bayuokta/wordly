import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/database_providers.dart';
import '../../../core/db/vocab_repository.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_surfaces.dart';

/// Daftar koleksi kata buatan pengguna.
class CollectionsPage extends ConsumerWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collectionsProvider);

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
                      'Koleksi saya',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _create(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    color: context.palette.primaryText,
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
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.page),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          EmptyState(
                            icon: Icons.folder_outlined,
                            title: 'Belum ada koleksi',
                            message:
                                'Kelompokkan kata sesuai kebutuhanmu — misalnya "Interview", "TOEFL", atau "Kata tersulit".',
                            action: AppButton(
                              label: 'Buat koleksi',
                              size: AppButtonSize.small,
                              expand: false,
                              onPressed: () => _create(context, ref),
                            ),
                          ),
                        ],
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
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _CollectionTile(
                      summary: items[index],
                      onTap: () => context.push('/collections/${items[index].id}'),
                      onDelete: () => _delete(context, ref, items[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.palette.surfaceElevated,
        title: const Text('Koleksi baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Nama koleksi'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return;

    await ref.read(vocabRepositoryProvider).createCollection(trimmed);
    ref.invalidate(collectionsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, CollectionSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.palette.surfaceElevated,
        title: Text('Hapus "${summary.name}"?'),
        content: const Text('Koleksi dan daftar kata di dalamnya akan dihapus. Progres belajar tetap aman.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Hapus', style: TextStyle(color: dialogContext.palette.errorText)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(vocabRepositoryProvider).deleteCollection(summary.id);
    ref.invalidate(collectionsProvider);
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.summary, required this.onTap, required this.onDelete});

  final CollectionSummary summary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(13, 12, 6, 12),
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
                  summary.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text('${summary.wordCount} kata', style: context.tiny),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: p.textDim),
          ),
          Icon(Icons.chevron_right_rounded, size: 16, color: p.chevron),
        ],
      ),
    );
  }
}
