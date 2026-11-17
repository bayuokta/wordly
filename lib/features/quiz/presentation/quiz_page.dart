import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/tts_service.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_progress.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../domain/quiz_question.dart';

enum _Phase { setup, session, summary }

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  static const List<int> _sizes = [5, 10, 20];

  _Phase _phase = _Phase.setup;
  QuizMode _mode = QuizMode.multipleChoice;
  int _size = 10;

  List<QuizQuestion> _questions = const [];
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  List<QuizQuestion> _wrongQuestions = [];
  bool _checked = false;
  bool _lastCorrect = false;
  int? _selected;
  bool _busy = false;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Tombol "Periksa" aktif begitu ada teks, jadi perlu rebuild saat mengetik.
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  QuizQuestion? get _current => _index < _questions.length ? _questions[_index] : null;
  int get _score => _correct * 10;

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _start({List<QuizQuestion>? questions}) async {
    setState(() => _busy = true);
    try {
      final queue = questions ?? QuizBuilder(pool: await ref.read(quizPoolProvider.future))
          .build(mode: _mode, count: _size);
      if (!mounted) return;
      if (queue.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Belum ada kata untuk kuis ini.')));
        return;
      }
      setState(() {
        _questions = queue;
        _index = 0;
        _correct = 0;
        _wrong = 0;
        _wrongQuestions = [];
        _checked = false;
        _selected = null;
        _controller.clear();
        _phase = _Phase.session;
      });
      _speakIfNeeded();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _speakIfNeeded() {
    final question = _current;
    if (question == null || !question.mode.usesAudio) return;
    ref.read(ttsServiceProvider).speak(question.audioText);
  }

  Future<void> _check() async {
    final question = _current;
    if (question == null || _checked || _busy) return;

    final bool correct;
    if (question.mode.needsTyping) {
      correct = question.accepts(_controller.text);
    } else {
      correct = _selected != null && normalizeAnswer(question.options[_selected!]) == normalizeAnswer(question.answer);
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(vocabRepositoryProvider)
          .answer(vocabId: question.word.id, correct: correct, mode: 'quiz_${question.mode.name}');
      if (!mounted) return;
      if (correct) {
        HapticFeedback.selectionClick();
        if (ref.read(settingsProvider).soundEffects) {
          SystemSound.play(SystemSoundType.click);
        }
      } else {
        HapticFeedback.mediumImpact();
      }
      setState(() {
        _checked = true;
        _lastCorrect = correct;
        if (correct) {
          _correct++;
        } else {
          _wrong++;
          _wrongQuestions.add(question);
        }
      });
      ref.invalidate(homeSnapshotProvider);
      ref.invalidate(learningWordsProvider);
      ref.invalidate(masteredWordsProvider);
      ref.invalidate(historyProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      setState(() => _phase = _Phase.summary);
      return;
    }
    setState(() {
      _index++;
      _checked = false;
      _selected = null;
      _controller.clear();
    });
    _speakIfNeeded();
    if (_current?.mode.needsTyping ?? false) {
      _focus.requestFocus();
    }
  }

  Future<void> _exit() async {
    if (_phase != _Phase.session || _correct + _wrong == 0) {
      context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.palette.surfaceElevated,
        title: const Text('Akhiri kuis?'),
        content: const Text('Jawaban yang sudah diperiksa tetap tersimpan.'),
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

    return Column(
      children: [
        _TopBar(title: 'Quiz', subtitle: '6 mode latihan', onClose: () => context.pop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 6, AppSpacing.page, AppSpacing.xl),
            children: [
              Text('PILIH MODE', style: context.eyebrow),
              const SizedBox(height: 10),
              for (final mode in QuizMode.values) ...[
                AppCard(
                  padding: const EdgeInsets.all(13),
                  radius: 16,
                  onTap: () => setState(() => _mode = mode),
                  child: Row(
                    children: [
                      IconTile(
                        icon: _modeIcon(mode),
                        tone: _mode == mode ? IconTileTone.primary : IconTileTone.neutral,
                        size: 34,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    mode.label,
                                    style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: p.textPrimary,
                                    ),
                                  ),
                                ),
                                if (mode.usesAudio)
                                  const AppChip(label: 'audio', height: 20, fontSize: 10),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(mode.description, style: context.tiny),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _mode == mode ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: _mode == mode ? p.primary : p.chevron,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 10),
              Text('JUMLAH SOAL', style: context.eyebrow),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final size in _sizes)
                    GestureDetector(
                      onTap: () => setState(() => _size = size),
                      child: AppChip(
                        label: '$size soal',
                        height: 34,
                        fontSize: 12.5,
                        tone: size == _size ? AppChipTone.primary : AppChipTone.neutral,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Mulai kuis',
                icon: Icons.play_arrow_rounded,
                loading: _busy,
                onPressed: _busy ? null : _start,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static IconData _modeIcon(QuizMode mode) => switch (mode) {
    QuizMode.multipleChoice => Icons.checklist_rounded,
    QuizMode.englishToIndonesian => Icons.translate_rounded,
    QuizMode.indonesianToEnglish => Icons.abc_rounded,
    QuizMode.fillBlank => Icons.short_text_rounded,
    QuizMode.listening => Icons.headphones_rounded,
    QuizMode.spelling => Icons.keyboard_rounded,
  };

  // ---------------------------------------------------------------- session

  Widget _buildSession(BuildContext context) {
    final p = context.palette;
    final question = _current!;
    final progress = _questions.isEmpty ? 0.0 : (_index + (_checked ? 1 : 0)) / _questions.length;

    return Column(
      children: [
        _TopBar(title: 'Quiz', subtitle: _mode.label, onClose: _exit),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.lg),
            children: [
              Row(
                children: [
                  Text('Skor $_score poin', style: context.tiny),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: context.tiny.copyWith(color: p.primaryText, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              AppProgressBar(value: progress),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            question.mode.usesAudio
                                ? 'Soal ${_index + 1} · dengarkan'
                                : 'Soal ${_index + 1} dari ${_questions.length}',
                            style: context.eyebrow,
                          ),
                        ),
                        AppChip(label: _mode.short, height: 20, fontSize: 10),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(question.prompt, style: context.small),
                    const SizedBox(height: 14),
                    _QuestionBody(
                      question: question,
                      checked: _checked,
                      selected: _selected,
                      controller: _controller,
                      focus: _focus,
                      onSelect: (index) => setState(() => _selected = index),
                      onSpeak: () => ref.read(ttsServiceProvider).speak(question.audioText),
                      onSpeakSlow: () => speakText(context, question.audioText, rateScale: 0.6),
                      onSubmitTyped: _check,
                    ),
                  ],
                ),
              ),
              if (_checked) ...[
                const SizedBox(height: 12),
                _Feedback(question: question, correct: _lastCorrect),
              ],
              const SizedBox(height: 16),
              if (!_checked)
                AppButton(
                  label: question.mode.needsTyping ? 'Periksa' : 'Pilih jawaban',
                  loading: _busy,
                  onPressed: _canCheck(question) && !_busy ? _check : null,
                )
              else
                AppButton(
                  label: _index + 1 >= _questions.length ? 'Lihat hasil' : 'Lanjut',
                  icon: Icons.arrow_forward_rounded,
                  iconAfter: true,
                  onPressed: _next,
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _canCheck(QuizQuestion question) =>
      question.mode.needsTyping ? _controller.text.trim().isNotEmpty : _selected != null;

  // ---------------------------------------------------------------- summary

  Widget _buildSummary(BuildContext context) {
    final p = context.palette;
    final total = _correct + _wrong;
    final accuracy = total == 0 ? 0 : ((_correct / total) * 100).round();

    return Column(
      children: [
        _TopBar(title: 'Kuis selesai', subtitle: _mode.label, onClose: () => context.pop()),
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
                    Text('SKOR', style: context.eyebrow),
                    const SizedBox(height: 8),
                    Text(
                      '$_score',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 46,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: p.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('dari ${total * 10} poin', style: context.tiny),
                    const SizedBox(height: 14),
                    AppProgressBar(
                      value: total == 0 ? 0 : _correct / total,
                      tone: accuracy >= 70 ? AppProgressTone.success : AppProgressTone.warning,
                    ),
                    const SizedBox(height: 10),
                    Text('Akurasi $accuracy%', style: context.small),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SummaryTile(label: 'Benar', value: '$_correct', tone: p.successText)),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryTile(label: 'Salah', value: '$_wrong', tone: p.errorText)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(label: 'Akurasi', value: '$accuracy%', tone: p.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_wrongQuestions.isNotEmpty) ...[
                AppButton(
                  label: 'Ulangi  kata salah',
                  icon: Icons.replay_rounded,
                  variant: AppButtonVariant.warn,
                  onPressed: () => _start(questions: List.of(_wrongQuestions)),
                ),
                const SizedBox(height: 10),
              ],
              AppButton(
                label: 'Ulangi dengan mode ini',
                icon: Icons.replay_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: () => _start(),
              ),
              const SizedBox(height: 10),
              AppButton(label: 'Selesai', onPressed: () => context.pop()),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({
    required this.question,
    required this.checked,
    required this.selected,
    required this.controller,
    required this.focus,
    required this.onSelect,
    required this.onSpeak,
    required this.onSpeakSlow,
    required this.onSubmitTyped,
  });

  final QuizQuestion question;
  final bool checked;
  final int? selected;
  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<int> onSelect;
  final VoidCallback onSpeak;
  final VoidCallback onSpeakSlow;
  final VoidCallback onSubmitTyped;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final word = question.word;

    if (!question.mode.needsTyping && question.options.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.mode == QuizMode.listening)
            _AudioPrompt(onTap: onSpeak, onSlow: onSpeakSlow, label: 'Putar kata')
          else ...[
            Text(word.word, style: context.wordTitle.copyWith(fontSize: 34)),
            if (word.pronunciationIpa case final ipa?) ...[
              const SizedBox(height: 6),
              Text(ipa, style: context.ipaText),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                AppChip(label: word.partOfSpeech),
                if (word.cefr case final cefr?) AppChip(label: cefr, tone: AppChipTone.primary),
              ],
            ),
          ],
          const SizedBox(height: 16),
          for (final (index, option) in question.options.indexed) ...[
            _OptionTile(
              letter: String.fromCharCode(65 + index),
              text: option,
              state: _stateFor(context, index),
              onTap: checked ? null : () => onSelect(index),
            ),
            if (index != question.options.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.mode == QuizMode.spelling)
          _AudioPrompt(onTap: onSpeak, onSlow: onSpeakSlow, label: 'Putar kata')
        else if (question.mode == QuizMode.fillBlank) ...[
          Text(
            question.sentence ?? '',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 17,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text('Petunjuk: ${word.translation}', style: context.tiny),
        ] else if (question.mode == QuizMode.englishToIndonesian) ...[
          Text(word.word, style: context.wordTitle.copyWith(fontSize: 34)),
          if (word.pronunciationIpa case final ipa?) ...[
            const SizedBox(height: 6),
            Text(ipa, style: context.ipaText),
          ],
        ] else ...[
          Text(
            word.translation,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 26,
              height: 1.3,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(word.definition, style: context.tiny),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          focusNode: focus,
          enabled: !checked,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitTyped(),
          autocorrect: false,
          style: TextStyle(fontFamily: AppFonts.body, fontSize: 15, color: p.textPrimary),
          cursorColor: p.primary,
          decoration: InputDecoration(
            hintText: question.mode == QuizMode.spelling ? 'Ketik ejaan kata' : 'Tulis jawabanmu',
            hintStyle: TextStyle(fontFamily: AppFonts.body, fontSize: 14, color: p.textDim),
            filled: true,
            fillColor: p.fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: p.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: p.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: p.primaryLine),
            ),
          ),
        ),
      ],
    );
  }

  _OptionState _stateFor(BuildContext context, int index) {
    if (!checked) {
      return index == selected ? _OptionState.selected : _OptionState.idle;
    }
    final isAnswer = normalizeAnswer(question.options[index]) == normalizeAnswer(question.answer);
    if (isAnswer) return _OptionState.correct;
    if (index == selected) return _OptionState.wrong;
    return _OptionState.disabled;
  }
}

enum _OptionState { idle, selected, correct, wrong, disabled }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color border, Color background, Color foreground) = switch (state) {
      _OptionState.idle => (p.border, p.surface, p.textPrimary),
      _OptionState.selected => (p.primaryLine, p.primarySoft, p.primaryText),
      _OptionState.correct => (p.successLine, p.successSoft, p.successText),
      _OptionState.wrong => (p.errorLine, p.errorSoft, p.errorText),
      _OptionState.disabled => (p.border, p.surface, p.textSecondary),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: p.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: p.border),
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: foreground,
                ),
              ),
            ),
            if (state == _OptionState.correct)
              Icon(Icons.check_circle_rounded, size: 18, color: p.successText),
            if (state == _OptionState.wrong)
              Icon(Icons.cancel_rounded, size: 18, color: p.errorText),
          ],
        ),
      ),
    );
  }
}

class _AudioPrompt extends StatelessWidget {
  const _AudioPrompt({required this.onTap, required this.onSlow, required this.label});

  final VoidCallback onTap;
  final VoidCallback onSlow;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: p.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: p.primaryLine),
              ),
              child: Icon(Icons.volume_up_rounded, size: 30, color: p.primaryText),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: context.tiny),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onSlow,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                'Lambat (0,6x)',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.primaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.question, required this.correct});

  final QuizQuestion question;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tone = correct ? p.successText : p.errorText;
    final border = correct ? p.successLine : p.errorLine;
    final background = correct ? p.successSoft : p.errorSoft;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 17,
                color: tone,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Benar! +10 poin' : 'Belum tepat',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Jawaban: ${question.answer}',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${question.word.word} — ${question.word.translation}',
            style: context.tiny,
          ),
        ],
      ),
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
                Text(subtitle.toUpperCase(), style: context.eyebrow.copyWith(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
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
