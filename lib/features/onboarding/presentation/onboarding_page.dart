import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/app_button.dart';

/// Onboarding satu layar: pilih level + target harian (maksimal 2 layar sesuai
/// dokumen rancangan, di sini digabung agar cepat).
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late String _level = ref.read(settingsProvider).level;
  late int _goal = ref.read(settingsProvider).dailyGoal;
  bool _busy = false;

  Future<void> _finish() async {
    setState(() => _busy = true);
    await ref.read(settingsProvider.notifier).completeOnboarding(level: _level, goal: _goal);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 14, AppSpacing.page, AppSpacing.xl),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: p.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'W',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: p.isDark ? const Color(0xFF0B1020) : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wordly',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 17,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('English · Indonesia', style: context.tiny),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(width: 34, height: 4, decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Container(width: 22, height: 4, decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(2))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text('SELAMAT DATANG', style: context.eyebrow),
            const SizedBox(height: 10),
            Text(
              'Satu kata sehari,\nlancar sedikit demi sedikit.',
              style: text.displaySmall?.copyWith(fontSize: 29, height: 1.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Wordly mengatur ulangan otomatis supaya kata baru benar-benar menempel, bukan cuma lewat.',
              style: context.small,
            ),
            const SizedBox(height: 26),
            Text('PILIH LEVELMU', style: context.eyebrow),
            const SizedBox(height: 11),
            for (final level in AppSettings.levelOptions) ...[
              _LevelCard(
                level: level,
                selected: _level == level,
                onTap: () => setState(() => _level = level),
              ),
              const SizedBox(height: 9),
            ],
            const SizedBox(height: 12),
            Text('TARGET HARIAN', style: context.eyebrow),
            const SizedBox(height: 11),
            _GoalSegment(
              selected: _goal,
              onChanged: (goal) => setState(() => _goal = goal),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Mulai belajar',
              loading: _busy,
              onPressed: _busy ? null : _finish,
            ),
            const SizedBox(height: 11),
            Text(
              'Tanpa akun · progres tersimpan di perangkat',
              textAlign: TextAlign.center,
              style: context.tiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.selected, required this.onTap});

  final String level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final (String letter, String title, String detail) = switch (level) {
      'beginner' => ('A', 'Pemula', 'A1–A2 · kata harian & percakapan dasar'),
      'advanced' => ('C', 'Mahir', 'C1–C2 · nuansa, idiom, akademik'),
      _ => ('B', 'Menengah', 'B1–B2 · kerja, perjalanan, teknologi'),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? p.primarySoft : p.surface,
          border: Border.all(color: selected ? p.primaryLine : p.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? p.primary : p.surfaceElevated,
                border: Border.all(color: selected ? p.primary : p.border),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? p.onPrimary : p.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: context.tiny.copyWith(
                      color: selected ? p.primaryText : p.textDim,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? p.primary : p.chevron, width: 1.5),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(width: 10, height: 10, decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSegment extends StatelessWidget {
  const _GoalSegment({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.fieldBg,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final goal in AppSettings.goalOptions)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(goal),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  height: 52,
                  decoration: BoxDecoration(
                    color: goal == selected ? p.primarySoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: goal == selected ? p.primaryLine : Colors.transparent),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$goal',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 16,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: goal == selected ? p.primaryText : p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        goal == 10 ? 'kata · ±4 mnt' : 'kata',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: goal == selected ? p.primaryText : p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
