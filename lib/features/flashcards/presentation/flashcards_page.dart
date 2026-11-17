import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/sound_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/db/content/content_database.dart';
import '../../../core/settings/settings_controller.dart';
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

enum _Phase { setup, session, summary }

class FlashcardsPage extends ConsumerStatefulWidget {
  const FlashcardsPage({super.key});

  @override
  ConsumerState<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends ConsumerState<FlashcardsPage> {
  static const List<int> _sizes = [5, 10, 12, 20];

  _Phase _phase = _Phase.setup;
  int _size = 12;

  List<WordListItem> _queue = const [];
  final Map<int, int> _repeats = {};
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  int _answered = 0;
  bool _flipped = false;
  bool _busy = false;
  int? _lastSpokenId;

  WordListItem? get _current => _index < _queue.length ? _queue[_index] : null;

  /// Ucapkan kata pada kartu baru bila pengguna mengaktifkan putar otomatis.
  void _speakIfAutoplay() {
    // Sekali per kartu: membalik kartu tidak memicu pengucapan ulang.
    final card = _current;
    if (card == null) return;
    if (!ref.read(settingsProvider).audioAutoplay) return;
    if (_lastSpokenId == card.word.id) return;
    _lastSpokenId = card.word.id;
    speakWord(context, card.word.word);
  }
  int get _total => _queue.length;

  Future<void> _start({List<WordListItem>? cards}) async {
    setState(() => _busy = true);
    try {
      final queue = cards ?? await ref.read(vocabRepositoryProvider).flashcardQueue(limit: _size);
      if (!mounted) return;
      if (queue.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Belum ada kartu untuk dipelajari.')));
        return;
      }
      setState(() {
        _queue = List.of(queue);
        _index = 0;
        _correct = 0;
        _wrong = 0;
        _answered = 0;
        _flipped = false;
        _repeats.clear();
        _lastSpokenId = null;
        _phase = _Phase.session;
      });
      _speakIfAutoplay();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _answer({required bool correct, bool easy = false}) async {
    final card = _current;
    if (card == null || _busy) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(vocabRepositoryProvider)
          .answer(vocabId: card.word.id, correct: correct, mode: 'flashcard', easy: easy);

      if (!mounted) return;
      if (correct) {
        HapticFeedback.selectionClick();
        if (ref.read(settingsProvider).soundEffects) {
          ref.read(soundServiceProvider).play(SoundService.correct);
        }
      } else {
        HapticFeedback.mediumImpact();
      }
      setState(() {
        _answered++;
        if (correct) {
          _correct++;
        } else {
          _wrong++;
          final repeats = _repeats[card.word.id] ?? 0;
          if (repeats < 2) {
            _repeats[card.word.id] = repeats + 1;
            _queue = [..._queue, card];
          }
        }
        _flipped = false;
        if (_index + 1 >= _queue.length) {
          _phase = _Phase.summary;
        } else {
          _index++;
        }
      });

      _speakIfAutoplay();

      ref.invalidate(homeSnapshotProvider);
      ref.invalidate(favoritesProvider);
      ref.invalidate(learningWordsProvider);
      ref.invalidate(masteredWordsProvider);
      ref.invalidate(historyProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exit() async {
    if (_phase != _Phase.session || _answered == 0) {
      context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.palette.surfaceElevated,
        title: const Text('Akhiri sesi?'),
        content: const Text('Progres kartu yang sudah dijawab tetap tersimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Lanjut')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Akhiri')),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.session,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: switch (_phase) {
            _Phase.setup => _buildSetup(context),
            _Phase.session => _buildSession(context),
            _Phase.summary => _buildSummary(context),
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ setup

  Widget _buildSetup(BuildContext context) {
    final p = context.palette;
    final due = ref.watch(homeSnapshotProvider).value?.due ?? 0;

    return Column(
      children: [
        _TopBar(title: 'Flashcard', subtitle: 'Latihan mengingat', onClose: () => context.pop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 6, AppSpacing.page, AppSpacing.xl),
            children: [
              AppCard(
                variant: AppCardVariant.hero,
                radius: AppRadius.hero,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SIAP MULAI', style: context.eyebrow),
                    const SizedBox(height: 10),
                    Text(
                      'Balik kartu, lalu geser kanan bila paham atau kiri untuk mengulang.',
                      style: context.small.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 15, color: p.accentText),
                        const SizedBox(width: 6),
                        Text('$due kata jatuh tempo hari ini', style: context.tiny),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('JUMLAH KARTU', style: context.eyebrow),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final size in _sizes)
                    GestureDetector(
                      onTap: () => setState(() => _size = size),
                      child: AppChip(
                        label: '$size kartu',
                        height: 34,
                        fontSize: 12.5,
                        tone: size == _size ? AppChipTone.primary : AppChipTone.neutral,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const IconTile(icon: Icons.layers_outlined),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Kartu diambil dari kata jatuh tempo, lalu kata baru sesuai levelmu.',
                        style: context.tiny,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Mulai sesi',
                icon: Icons.play_arrow_rounded,
                loading: _busy,
                onPressed: _busy ? null : () => _start(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- session

  Widget _buildSession(BuildContext context) {
    final p = context.palette;
    final card = _current!;
    final word = card.word;
    final progress = _total == 0 ? 0.0 : _answered / _total;

    return Column(
      children: [
        _TopBar(
          title: 'Flashcard',
          subtitle: 'Kartu ${(_index + 1).clamp(1, _total)} dari $_total',
          onClose: _exit,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Progres sesi', style: context.tiny),
                    const Spacer(),
                    Text(
                      '${(progress * 100).round()}%',
                      style: context.tiny.copyWith(
                        color: p.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                AppProgressBar(value: progress),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _flipped = !_flipped),
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity > 250) {
                        _answer(correct: true, easy: true);
                      } else if (velocity < -250) {
                        _answer(correct: false);
                      }
                    },
                    child: _FlipCard(
                      flipped: _flipped,
                      front: _CardFront(
                        word: word,
                        position: _index + 1,
                        total: _total,
                      ),
                      back: _CardBack(word: word),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Counter(color: p.success, value: _correct, label: 'benar'),
                    _Counter(color: p.warning, value: _wrong, label: 'diulang'),
                    Text('${_remaining()} kartu tersisa', style: context.tiny),
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
                        label: 'Sudah paham',
                        icon: Icons.check_rounded,
                        variant: AppButtonVariant.success,
                        loading: _busy,
                        onPressed: _busy ? null : () => _answer(correct: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Geser kiri untuk ulangi · kanan untuk paham',
                  style: context.tiny,
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _remaining() => (_total - _answered).clamp(0, _total);

  /// Kartu yang pernah dijawab "ulangi", tanpa duplikat.
  List<WordListItem> _wrongCards() {
    final seen = <int>{};
    return [
      for (final card in _queue)
        if (_repeats.containsKey(card.word.id) && seen.add(card.word.id)) card,
    ];
  }

  // ---------------------------------------------------------------- summary

  Widget _buildSummary(BuildContext context) {
    final p = context.palette;
    final accuracy = _answered == 0 ? 0 : ((_correct / _answered) * 100).round();

    return Column(
      children: [
        _TopBar(title: 'Sesi selesai', subtitle: 'Ringkasan', onClose: () => context.pop()),
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
                    Text('AKURASI', style: context.eyebrow),
                    const SizedBox(height: 10),
                    Text(
                      '$accuracy%',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 44,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: accuracy >= 70 ? p.successText : p.warningText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppProgressBar(
                      value: _answered == 0 ? 0 : _correct / _answered,
                      tone: accuracy >= 70 ? AppProgressTone.success : AppProgressTone.warning,
                    ),
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
                  Expanded(child: _SummaryTile(label: 'Total', value: '$_answered', tone: p.textPrimary)),
                ],
              ),
              const SizedBox(height: 18),
              if (_wrong > 0)
                AppButton(
                  label: 'Ulangi kata yang salah',
                  icon: Icons.replay_rounded,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => _start(cards: _wrongCards()),
                ),
              if (_wrong > 0) const SizedBox(height: 10),
              AppButton(label: 'Selesai', onPressed: () => context.pop()),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.subtitle, required this.onClose});

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, AppSpacing.page, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 22),
            color: p.iconSoft,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.toUpperCase(),
                  style: context.eyebrow.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
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

/// Kartu dengan animasi putar 3D (350 ms, sesuai design system).
class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.flipped, required this.front, required this.back});

  final bool flipped;
  final Widget front;
  final Widget back;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.cardFlip,
    value: widget.flipped ? 1 : 0,
  );

  @override
  void didUpdateWidget(_FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flipped != oldWidget.flipped) {
      if (widget.flipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = _controller.value * math.pi;
        final showBack = angle >= math.pi / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: widget.back,
                )
              : widget.front,
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: p.flashGradient,
        border: Border.all(color: p.flashBorder),
        borderRadius: BorderRadius.circular(AppRadius.flashcard),
        boxShadow: p.cardShadow,
      ),
      child: child,
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({required this.word, required this.position, required this.total});

  final Vocabulary word;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return _CardShell(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('KARTU $position DARI $total', style: context.eyebrow)),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => speakWord(context, word.word),
                child: Semantics(
                  button: true,
                  label: 'Dengarkan kata',
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.volume_up_outlined, size: 18, color: p.primaryText),
                  ),
                ),
              ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined, size: 15, color: p.textSecondary),
              const SizedBox(width: 7),
              Text('Ketuk kartu untuk melihat arti', style: context.tiny),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.word});

  final Vocabulary word;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return _CardShell(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('ARTI', style: context.eyebrow)),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => speakWord(context, word.word),
                  child: Semantics(
                    button: true,
                    label: 'Dengarkan kata',
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.volume_up_outlined, size: 18, color: p.primaryText),
                    ),
                  ),
                ),
              ],
            ),
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
