import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/pronunciation_score.dart';
import '../../../core/audio/speech_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/db/content/content_database.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_progress.dart';
import '../../../core/widgets/app_surfaces.dart';

/// Latihan pelafalan: ucapkan kata, lalu bandingkan dengan pengenalan suara.
class PronunciationPage extends ConsumerStatefulWidget {
  const PronunciationPage({super.key});

  @override
  ConsumerState<PronunciationPage> createState() => _PronunciationPageState();
}

class _PronunciationPageState extends ConsumerState<PronunciationPage> {
  static const int _sessionSize = 5;

  List<Vocabulary> _words = const [];
  int _index = 0;
  bool _loading = true;
  bool _listening = false;
  String _heard = '';
  double? _score;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pool = await ref.read(quizPoolProvider.future);
    if (!mounted) return;
    setState(() {
      _words = pool.where((word) => !word.word.contains(' ')).take(_sessionSize).toList();
      if (_words.isEmpty) _words = pool.take(_sessionSize).toList();
      _loading = false;
    });
  }

  Vocabulary? get _current => _index < _words.length ? _words[_index] : null;

  Future<void> _startListening() async {
    final word = _current;
    if (word == null || _listening) return;

    final speech = ref.read(speechServiceProvider);
    final ok = await speech.listen(
      onWords: (words, isFinal) {
        if (!mounted) return;
        setState(() {
          _heard = words;
          if (isFinal) {
            _score = scorePronunciation(word.word, words);
            _listening = false;
          }
        });
      },
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pengenalan suara tidak tersedia di perangkat ini.'),
          ),
        );
      return;
    }
    if (mounted) setState(() => _listening = true);
  }

  Future<void> _stopListening() async {
    await ref.read(speechServiceProvider).stop();
    if (mounted) setState(() => _listening = false);
  }

  void _next() {
    if (_index + 1 >= _words.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _heard = '';
      _score = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      'Latihan pelafalan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                  ),
                  if (!_loading && !_finished)
                    Text('${_index + 1} / ${_words.length}', style: context.tiny),
                ],
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_words.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.page),
        child: EmptyState(
          icon: Icons.mic_none_rounded,
          title: 'Belum ada kata',
          message: 'Tambahkan kosakata dulu sebelum berlatih pelafalan.',
        ),
      );
    }
    if (_finished) {
      return _summary(context);
    }
    return _session(context);
  }

  Widget _session(BuildContext context) {
    final p = context.palette;
    final word = _current!;
    final score = _score;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.xl),
      children: [
        AppProgressBar(value: (_index + 1) / _words.length),
        const SizedBox(height: 16),
        AppCard(
          variant: AppCardVariant.hero,
          radius: AppRadius.hero,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('UCAPKAN KATA INI', style: context.eyebrow),
              const SizedBox(height: 12),
              Text(
                word.word,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 36,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: p.textPrimary,
                ),
              ),
              if (word.pronunciationIpa case final ipa?) ...[
                const SizedBox(height: 8),
                Text(ipa, style: context.ipaText.copyWith(fontSize: 14)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  AppChip(label: word.partOfSpeech),
                  if (word.cefr case final cefr?) AppChip(label: cefr, tone: AppChipTone.primary),
                ],
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Dengar contoh',
                icon: Icons.volume_up_outlined,
                size: AppButtonSize.small,
                expand: false,
                variant: AppButtonVariant.ghost,
                onPressed: () => speakWord(context, word.word),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: GestureDetector(
            onTap: _listening ? _stopListening : _startListening,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _listening ? p.errorSoft : p.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: _listening ? p.errorLine : p.primaryLine),
              ),
              child: Icon(
                _listening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 34,
                color: _listening ? p.errorText : p.primaryText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _listening ? 'Mendengarkan… ketuk untuk berhenti' : 'Ketuk mikrofon lalu ucapkan katanya',
            style: context.tiny,
            textAlign: TextAlign.center,
          ),
        ),
        if (_heard.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TERDENGAR', style: context.eyebrow),
                const SizedBox(height: 8),
                Text(
                  _heard,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: p.textPrimary,
                  ),
                ),
                if (score != null) ...[
                  const SizedBox(height: 12),
                  AppProgressBar(
                    value: score,
                    tone: score >= 0.7 ? AppProgressTone.success : AppProgressTone.warning,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(score * 100).round()}% · ${pronunciationFeedback(score)}',
                    style: context.small,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        AppButton(
          label: _index + 1 >= _words.length ? 'Lihat hasil' : 'Lanjut',
          icon: Icons.arrow_forward_rounded,
          iconAfter: true,
          onPressed: score == null ? null : _next,
        ),
      ],
    );
  }

  Widget _summary(BuildContext context) {
    final p = context.palette;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        AppCard(
          variant: AppCardVariant.hero,
          radius: AppRadius.hero,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.record_voice_over_rounded, size: 32, color: p.successText),
              const SizedBox(height: 10),
              Text('Latihan selesai', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('${_words.length} kata sudah kamu ucapkan.', style: context.small),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppButton(label: 'Selesai', onPressed: () => context.pop()),
        const SizedBox(height: 10),
        AppButton(
          label: 'Latihan lagi',
          variant: AppButtonVariant.ghost,
          onPressed: () => setState(() {
            _index = 0;
            _heard = '';
            _score = null;
            _finished = false;
          }),
        ),
      ],
    );
  }
}
