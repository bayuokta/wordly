import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/date_id.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_progress.dart';
import '../../../core/widgets/app_surfaces.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();

    return SafeArea(
      bottom: false,
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
                    Text('Halo', style: text.displaySmall),
                  ],
                ),
              ),
              const _StreakPill(days: 0),
            ],
          ),
          const SizedBox(height: 16),
          const _WordOfDayCard(),
          const SizedBox(height: AppSpacing.cardGap),
          const _GoalCard(current: 0, goal: 10),
          const SizedBox(height: AppSpacing.cardGap),
          const _QuickActions(),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Lanjutkan belajar',
            actionLabel: 'Semua kata',
            onAction: () => context.go('/explore'),
          ),
          const SizedBox(height: 10),
          AppCard(
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
                  'Progresmu akan muncul di sini setelah mulai belajar.',
                  textAlign: TextAlign.center,
                  style: context.tiny,
                ),
              ],
            ),
          ),
        ],
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
  const _WordOfDayCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppCard(
      variant: AppCardVariant.hero,
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('KATA HARI INI', style: context.eyebrow)),
              const AppChip(label: 'Belum tersedia', height: 22, fontSize: 10),
            ],
          ),
          const SizedBox(height: 12),
          Text('Kosakata belum dimuat', style: text.titleMedium?.copyWith(fontSize: 17)),
          const SizedBox(height: 6),
          Text(
            'Kata harian muncul otomatis setelah basis data kosakata diisi dan '
            'jadwal ulangan berjalan.',
            style: context.small,
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Jelajahi kosakata',
            icon: Icons.arrow_forward_rounded,
            iconAfter: true,
            size: AppButtonSize.small,
            expand: false,
            variant: AppButtonVariant.primary,
            onPressed: () => context.go('/explore'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.current, required this.goal});

  final int current;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AppProgressRing(
            value: goal == 0 ? 0 : current / goal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$current',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  '/$goal',
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
                  'Belum ada aktivitas',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                AppProgressBar(value: goal == 0 ? 0 : current / goal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            icon: Icons.layers_outlined,
            title: 'Flashcard',
            subtitle: '0 kartu',
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
            subtitle: '0 jatuh tempo',
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
