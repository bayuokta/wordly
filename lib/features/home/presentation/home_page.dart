import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/tts_service.dart';
import '../../../core/db/database_providers.dart';
import '../../../core/db/vocab_repository.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/date_id.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_progress.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../core/widgets/word_row.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeSnapshotProvider);
    final now = DateTime.now();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: context.palette.primary,
        backgroundColor: context.palette.surface,
        onRefresh: () async => ref.invalidate(homeSnapshotProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 10, AppSpacing.page, AppSpacing.xl),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateId.longDate(now).toUpperCase(), style: context.eyebrow),
                      const SizedBox(height: 8),
                      Text('Halo', style: Theme.of(context).textTheme.displaySmall),
                    ],
                  ),
                ),
                _StreakPill(days: async.value?.streakDays ?? 0),
              ],
            ),
            const SizedBox(height: 16),
            async.when(
              loading: () => const _LoadingCard(height: 190),
              error: (error, _) => _ErrorCard(message: '$error'),
              data: (snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WordOfDayCard(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.cardGap),
                  _GoalCard(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.cardGap),
                  _QuickActions(snapshot: snapshot),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: 'Lanjutkan belajar',
                    actionLabel: 'Semua kata',
                    onAction: () => context.go('/explore'),
                  ),
                  const SizedBox(height: 10),
                  if (snapshot.recent.isEmpty)
                    const _EmptyRecent()
                  else
                    WordListCard(
                      items: snapshot.recent,
                      onTapItem: (item) => context.push('/word/${item.word.id}'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: p.accentSoft,
        border: Border.all(color: p.accentLine),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_outlined, size: 15, color: p.accentText),
          const SizedBox(width: 6),
          Text(
            '$days hari',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w600,
              color: p.accentText,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordOfDayCard extends StatelessWidget {
  const _WordOfDayCard({required this.snapshot});

  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final word = snapshot.wordOfDay;

    if (word == null) {
      return AppCard(
        variant: AppCardVariant.hero,
        radius: AppRadius.hero,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KATA HARI INI', style: context.eyebrow),
            const SizedBox(height: 12),
            Text('Kosakata belum dimuat', style: text.titleMedium?.copyWith(fontSize: 17)),
            const SizedBox(height: 6),
            Text('Jalankan ulang aplikasi untuk memuat konten.', style: context.small),
          ],
        ),
      );
    }

    return AppCard(
      variant: AppCardVariant.hero,
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/word/${word.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('KATA HARI INI', style: context.eyebrow)),
              AppChip(
                label: '${word.cefr ?? ''} · ${word.partOfSpeech}'.trim(),
                tone: AppChipTone.primary,
                height: 22,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: text.displayMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (word.pronunciationIpa case final ipa?) ...[
                      const SizedBox(height: 5),
                      Text(ipa, style: context.ipaText),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => speakWord(context, word.word),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: BoxDecoration(
                    color: p.primarySoft,
                    border: Border.all(color: p.primaryLine),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.volume_up_outlined, size: 18, color: p.primaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            word.translation,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: p.textSoft,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              AppChip(
                label: snapshot.wordOfDayCategory?.name ?? 'Kosakata',
                height: 24,
                fontSize: 11,
              ),
              const Spacer(),
              Text(
                'Lihat detail',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: p.primaryText,
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 13, color: p.primaryText),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.snapshot});

  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final remaining = (snapshot.goal - snapshot.reviewsToday).clamp(0, snapshot.goal);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AppProgressRing(
            value: snapshot.goalProgress,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${snapshot.reviewsToday}',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  '/${snapshot.goal}',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: p.textDim,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TARGET HARI INI', style: context.eyebrow),
                const SizedBox(height: 6),
                Text(
                  remaining == 0
                      ? 'Target hari ini tercapai 🎉'
                      : '$remaining kata lagi untuk streak',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                AppProgressBar(value: snapshot.goalProgress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.snapshot});

  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            icon: Icons.layers_outlined,
            title: 'Flashcard',
            subtitle: '${snapshot.learned} kartu',
            onTap: () => context.go('/practice'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickTile(
            icon: Icons.ads_click_outlined,
            title: 'Quiz',
            subtitle: '6 mode',
            tone: IconTileTone.success,
            onTap: () => context.go('/practice'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickTile(
            icon: Icons.schedule_rounded,
            title: 'Review',
            subtitle: '${snapshot.due} jatuh tempo',
            tone: IconTileTone.accent,
            onTap: () => context.go('/practice'),
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = IconTileTone.primary,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconTileTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: 16,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, tone: tone, size: 30, iconSize: 17),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10.5, height: 1, color: p.textDim)),
        ],
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        children: [
          Icon(Icons.auto_stories_outlined, size: 24, color: p.textDim),
          const SizedBox(height: 10),
          Text(
            'Belum ada kata dipelajari',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mulai dari kata hari ini atau jelajahi kategori.',
            textAlign: TextAlign.center,
            style: context.tiny,
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Jelajahi kosakata',
            size: AppButtonSize.small,
            expand: false,
            onPressed: () => context.go('/explore'),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: SizedBox(
        height: height,
        child: Center(
          child: CircularProgressIndicator(color: context.palette.primary),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: context.palette.error, size: 24),
          const SizedBox(height: 10),
          Text('Gagal memuat data', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: context.tiny),
        ],
      ),
    );
  }
}
