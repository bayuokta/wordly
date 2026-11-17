import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/tts_service.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/db/vocab_repository.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/srs/sm2.dart';

class WordDetailPage extends ConsumerStatefulWidget {
  const WordDetailPage({super.key, required this.vocabId});

  final int vocabId;

  @override
  ConsumerState<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends ConsumerState<WordDetailPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Putar otomatis bila pengguna mengaktifkannya di Pengaturan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(settingsProvider).audioAutoplay) return;
      final word = ref.read(wordDetailProvider(widget.vocabId)).value?.word.word;
      if (word != null) speakWord(context, word);
    });
  }

  Future<void> _answer({required bool correct}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(vocabRepositoryProvider)
          .answer(vocabId: widget.vocabId, correct: correct);
      ref.invalidate(wordDetailProvider(widget.vocabId));
      ref.invalidate(homeSnapshotProvider);
      ref.invalidate(favoritesProvider);
      ref.invalidate(learningWordsProvider);
      ref.invalidate(masteredWordsProvider);
      ref.invalidate(historyProvider);

      if (!mounted) return;
      final message = switch (result.status) {
        WordStatus.mastered => 'Kata ini sudah dikuasai 🎉',
        WordStatus.learning => 'Akan muncul lagi sebentar lagi',
        _ => 'Muncul lagi dalam ${result.intervalDays} hari',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Bottom sheet untuk menambah/menghapus kata dari koleksi.
  Future<void> _openCollectionSheet() async {
    final repo = ref.read(vocabRepositoryProvider);
    final initialCollections = await repo.collections();
    final containing = await repo.collectionsContaining(widget.vocabId);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.surfaceElevated,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> toggle(int collectionId, bool selected) async {
            if (selected) {
              await repo.removeFromCollection(collectionId, widget.vocabId);
            } else {
              await repo.addToCollection(collectionId, widget.vocabId);
            }
            setSheetState(() {
              if (selected) {
                containing.remove(collectionId);
              } else {
                containing.add(collectionId);
              }
            });
            ref.invalidate(collectionsProvider);
            ref.invalidate(collectionItemsProvider(collectionId));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simpan ke koleksi',
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (initialCollections.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('Belum ada koleksi.', style: context.tiny),
                    ),
                  for (final collection in initialCollections)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(collection.name),
                      subtitle: Text('${collection.wordCount} kata'),
                      trailing: Icon(
                        containing.contains(collection.id)
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: containing.contains(collection.id)
                            ? sheetContext.palette.primary
                            : sheetContext.palette.chevron,
                      ),
                      onTap: () => toggle(collection.id, containing.contains(collection.id)),
                    ),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add_rounded),
                    title: const Text('Koleksi baru…'),
                    onTap: () async {
                      final name = await _askCollectionName(sheetContext);
                      if (name == null || name.isEmpty) return;
                      final id = await repo.createCollection(name);
                      await repo.addToCollection(id, widget.vocabId);
                      ref.invalidate(collectionsProvider);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _askCollectionName(BuildContext context) async {
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
    return name?.trim();
  }

  Future<void> _toggleFavorite() async {
    await ref.read(vocabRepositoryProvider).toggleFavorite(widget.vocabId);
    ref.invalidate(wordDetailProvider(widget.vocabId));
    ref.invalidate(favoritesProvider);
    ref.invalidate(homeSnapshotProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wordDetailProvider(widget.vocabId));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Text('Gagal memuat kata.\n$error', textAlign: TextAlign.center),
            ),
          ),
          data: (detail) => _DetailBody(
            detail: detail,
            busy: _busy,
            onFavorite: _toggleFavorite,
            onSaveToCollection: _openCollectionSheet,
            onAnswer: (correct) => _answer(correct: correct),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.busy,
    required this.onFavorite,
    required this.onSaveToCollection,
    required this.onAnswer,
  });

  final WordDetailData detail;
  final bool busy;
  final VoidCallback onFavorite;
  final VoidCallback onSaveToCollection;
  final void Function(bool correct) onAnswer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final word = detail.word;
    final progress = detail.progress;
    final favorites = progress?.isFavorite ?? false;
    final totalAnswers = (progress?.correctCount ?? 0) + (progress?.wrongCount ?? 0);
    final accuracy = totalAnswers == 0
        ? null
        : ((progress!.correctCount / totalAnswers) * 100).round();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.xl),
            children: [
              Row(
                children: [
                  _IconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  _IconButton(
                    icon: Icons.playlist_add_rounded,
                    onTap: onSaveToCollection,
                  ),
                  const SizedBox(width: 4),
                  _IconButton(
                    icon: favorites ? Icons.bookmark : Icons.bookmark_border,
                    color: favorites ? p.primary : p.iconSoft,
                    onTap: onFavorite,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  AppChip(label: word.partOfSpeech, tone: AppChipTone.primary),
                  AppChip(label: _levelLabel(word.difficultyLevel)),
                  if (word.cefr case final cefr?) AppChip(label: cefr),
                ],
              ),
              const SizedBox(height: 10),
              Text(word.word, style: context.wordTitle),
              if (word.pronunciationIpa case final ipa?) ...[
                const SizedBox(height: 7),
                Text(ipa, style: context.ipaText.copyWith(fontSize: 14)),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  AppButton(
                    label: 'Dengarkan kata',
                    icon: Icons.volume_up_outlined,
                    expand: false,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    onPressed: () => speakWord(context, detail.word.word),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Kalimat',
                    icon: Icons.record_voice_over_outlined,
                    expand: false,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    onPressed: () => speakSentence(context, detail.word.exampleSentence),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('ARTI', style: context.eyebrow),
              const SizedBox(height: 8),
              Text(
                word.translation,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(word.definition, style: context.small),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
                decoration: BoxDecoration(
                  color: p.quoteBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONTOH KALIMAT', style: context.eyebrow),
                    const SizedBox(height: 8),
                    Text(
                      '“${word.exampleSentence}”',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(word.exampleTranslation, style: context.tiny),
                  ],
                ),
              ),
              if (detail.synonyms.isNotEmpty) ...[
                const SizedBox(height: 14),
                _ChipLine(label: 'Sinonim', values: detail.synonyms, tone: AppChipTone.neutral),
              ],
              if (detail.antonyms.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ChipLine(label: 'Antonim', values: detail.antonyms, tone: AppChipTone.error),
              ],
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('JADWAL ULANGAN', style: context.eyebrow)),
                        StatusPill(status: WordStatus.fromValue(progress?.status ?? 'new')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Metric(
                          value: detail.dueLabel ?? '—',
                          label: 'Berikutnya',
                        ),
                        _Metric(
                          value: '${progress?.repetitions ?? 0}×',
                          label: 'Diulang',
                          divider: true,
                        ),
                        _Metric(
                          value: accuracy == null ? '—' : '$accuracy%',
                          label: 'Akurasi',
                          divider: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 12, AppSpacing.page, 10),
          decoration: BoxDecoration(
            color: p.navBg,
            border: Border(top: BorderSide(color: p.navBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  flex: 100,
                  child: AppButton(
                    label: 'Pelajari lagi',
                    icon: Icons.replay_rounded,
                    variant: AppButtonVariant.ghost,
                    loading: busy,
                    onPressed: busy ? null : () => onAnswer(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 115,
                  child: AppButton(
                    label: 'Sudah paham',
                    icon: Icons.check_rounded,
                    loading: busy,
                    onPressed: busy ? null : () => onAnswer(true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _levelLabel(String level) => switch (level) {
    'beginner' => 'Pemula',
    'intermediate' => 'Menengah',
    _ => 'Mahir',
  };
}

class _ChipLine extends StatelessWidget {
  const _ChipLine({required this.label, required this.values, required this.tone});

  final String label;
  final List<String> values;
  final AppChipTone tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 58, child: Text(label, style: context.tiny)),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [for (final value in values) AppChip(label: value, tone: tone)],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.divider = false});

  final String value;
  final String label;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 16,
            height: 1,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: context.tiny),
      ],
    );

    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: divider ? 14 : 0, right: 6),
        decoration: divider
            ? BoxDecoration(border: Border(left: BorderSide(color: p.divider)))
            : null,
        child: content,
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Icon(icon, size: 20, color: color ?? context.palette.iconSoft),
      ),
    );
  }
}
