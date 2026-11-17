import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/database_providers.dart';
import '../../../core/db/vocab_repository.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_progress.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../core/widgets/flip_card.dart';

/// Review terjadwal (SM-2): hanya kata yang sudah jatuh tempo.
class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  List<WordListItem>? _queue;
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  bool _flipped = false;
  bool _busy = false;
  bool _finished = false;

  WordListItem? get _current {
    final queue = _queue;
    if (queue == null || _index >= queue.length) return null;
    return queue[_index];
  }

  void _start(List<WordListItem> queue) {
    setState(() {
      _queue = queue;
      _index = 0;
      _correct = 0;
      _wrong = 0;
      _flipped = false;
      _finished = false;
    });
  }

  Future<void> _answer({required bool correct}) async {
    final card = _current;
    if (card == null || _busy) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(vocabRepositoryProvider)
          .answer(vocabId: card.word.id, correct: correct, mode: 'srs');

      if (!mounted) return;
      if (correct) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.mediumImpact();
      }
      setState(() {
        if (correct) {
          _correct++;
        } else {
          _wrong++;
        }
        _flipped = false;
        if (_index + 1 >= (_queue?.length ?? 0)) {
          _finished = true;
        } else {
          _index++;
        }
      });

      ref.invalidate(homeSnapshotProvider);
      ref.invalidate(reviewQueueProvider);
      ref.invalidate(learningWordsProvider);
      ref.invalidate(masteredWordsProvider);
      ref.invalidate(historyProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reviewQueueProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Text('Gagal memuat antrean review.\n$error', textAlign: TextAlign.center),
            ),
          ),
          data: (queue) {
            if (_queue == null) {
              return queue.isEmpty ? _buildEmpty(context) : _buildReady(context, queue);
            }
            return _finished ? _buildFinished(context) : _buildSession(context);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String subtitle) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, AppSpacing.page, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, size: 22),
            color: p.iconSoft,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Review terjadwal',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle.toUpperCase(), style: context.eyebrow.copyWith(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context, 'tidak ada jatuh tempo'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Semua beres hari ini 🎉',
                  message:
                      'Tidak ada kata yang jatuh tempo. Tambah kata baru atau ulangi sesi flashcard.',
                  action: AppButton(
                    label: 'Belajar kata baru',
                    expand: false,
                    size: AppButtonSize.small,
                    onPressed: () => context.push('/flashcards'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReady(BuildContext context, List<WordListItem> queue) {
    final p = context.palette;

    return Column(
      children: [
        _buildHeader(context, '${queue.length} kata menunggu'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, AppSpacing.xl),
            children: [
              AppCard(
                variant: AppCardVariant.hero,
                radius: AppRadius.hero,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ANTREAN REVIEW', style: context.eyebrow),
                    const SizedBox(height: 10),
                    Text(
                      '${queue.length} kata siap diulang',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Diurutkan dari yang paling terlambat dan paling sering salah.',
                      style: context.small,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 15, color: p.accentText),
                        const SizedBox(width: 6),
                        Text('Sekitar ${(queue.length * 10 / 60).ceil()} menit', style: context.tiny),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppButton(label: 'Mulai review', onPressed: () => _start(queue)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSession(BuildContext context) {
    final p = context.palette;
    final card = _current!;

    final total = _queue!.length;
    final progress = total == 0 ? 0.0 : _index / total;

    return Column(
      children: [
        _buildHeader(context, 'kartu ${_index + 1} dari $total'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Column(
              children: [
                AppProgressBar(value: progress),
                const SizedBox(height: 14),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _flipped = !_flipped),
                    child: FlipCard(
                      flipped: _flipped,
                      front: _ReviewFront(item: card, position: _index + 1, total: total),
                      back: _ReviewBack(item: card),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Counter(color: p.success, value: _correct, label: 'benar'),
                    const Spacer(),
                    _Counter(color: p.warning, value: _wrong, label: 'diulang'),
                    const Spacer(),
                    Text('${total - _index} tersisa', style: context.tiny),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Ulangi',
                        icon: Icons.replay_rounded,
                        variant: AppButtonVariant.warn,
                        loading: _busy,
                        onPressed: _busy ? null : () => _answer(correct: false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Sudah ingat',
                        icon: Icons.check_rounded,
                        variant: AppButtonVariant.success,
                        loading: _busy,
                        onPressed: _busy ? null : () => _answer(correct: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Ketuk kartu untuk melihat arti', style: context.tiny),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinished(BuildContext context) {
    final p = context.palette;
    final total = _correct + _wrong;
    final accuracy = total == 0 ? 0 : ((_correct / total) * 100).round();

    return Column(
      children: [
        _buildHeader(context, 'selesai'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, AppSpacing.xl),
            children: [
              AppCard(
                variant: AppCardVariant.hero,
                radius: AppRadius.hero,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.task_alt_rounded, size: 34, color: p.successText),
                    const SizedBox(height: 10),
                    Text(
                      'Antrean hari ini selesai',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text('$total kata diulang · akurasi $accuracy%', style: context.small),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SummaryTile(label: 'Benar', value: '$_correct', tone: p.successText)),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryTile(label: 'Diulang', value: '$_wrong', tone: p.warningText)),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryTile(label: 'Akurasi', value: '$accuracy%', tone: p.textPrimary)),
                ],
              ),
              const SizedBox(height: 18),
              AppButton(label: 'Selesai', onPressed: () => context.pop()),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewFront extends StatelessWidget {
  const _ReviewFront({required this.item, required this.position, required this.total});

  final WordListItem item;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final word = item.word;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: p.flashGradient,
        border: Border.all(color: p.flashBorder),
        borderRadius: BorderRadius.circular(AppRadius.flashcard),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('KARTU $position DARI $total', style: context.eyebrow)),
              AppChip(label: _dueLabel(item), tone: AppChipTone.accent, height: 22, fontSize: 10),
            ],
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  word.word,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 38,
                    height: 1.12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.1,
                    color: p.textPrimary,
                  ),
                ),
                if (word.pronunciationIpa case final ipa?) ...[
                  const SizedBox(height: 8),
                  Text(ipa, style: context.ipaText.copyWith(fontSize: 14)),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    AppChip(label: word.partOfSpeech),
                    if (word.cefr case final cefr?) AppChip(label: cefr, tone: AppChipTone.primary),
                  ],
                ),
              ],
            ),
          ),
          Text('Ketuk untuk melihat arti', style: context.tiny),
        ],
      ),
    );
  }

  static String _dueLabel(WordListItem item) {
    final dueAt = item.progress?.dueAt;
    if (dueAt == null) return 'baru';
    final late = DateTime.now().difference(dueAt);
    if (late.inDays >= 1) return 'telat ${late.inDays}h';
    if (late.inHours >= 1) return 'telat ${late.inHours}j';
    return 'jatuh tempo';
  }
}

class _ReviewBack extends StatelessWidget {
  const _ReviewBack({required this.item});

  final WordListItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final word = item.word;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: p.flashGradient,
        border: Border.all(color: p.flashBorder),
        borderRadius: BorderRadius.circular(AppRadius.flashcard),
        boxShadow: p.cardShadow,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ARTI', style: context.eyebrow),
            const SizedBox(height: 8),
            Text(
              word.translation,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 22,
                height: 1.3,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(word.definition, style: context.small),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: p.quoteBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('“${word.exampleSentence}”', style: context.small.copyWith(color: p.textSoft)),
                  const SizedBox(height: 6),
                  Text(word.exampleTranslation, style: context.tiny),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.color, required this.value, required this.label});

  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: context.tiny),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.tone});

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: context.tiny),
        ],
      ),
    );
  }
}
