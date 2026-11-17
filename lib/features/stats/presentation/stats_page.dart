import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/database_providers.dart';
import '../../../core/db/vocab_repository.dart';
import '../../../core/design/app_palette.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/utils/date_id.dart';
import '../../../core/widgets/activity_chart.dart';
import '../../../core/widgets/streak_heatmap.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_progress.dart';
import '../../../core/widgets/word_row.dart';

/// Statistik aktivitas dan penguasaan kosakata.
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(statsProvider(_days));

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
                      'Statistik',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                  ),
                  for (final days in [7, 30])
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _days = days),
                        child: AppChip(
                          label: '$days hari',
                          height: 30,
                          fontSize: 12,
                          tone: _days == days ? AppChipTone.primary : AppChipTone.neutral,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    child: Text('Gagal memuat statistik.\n$error', textAlign: TextAlign.center),
                  ),
                ),
                data: (stats) => _Body(stats: stats),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.stats});

  final StatsSnapshot stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final today = DateTime.now();
    final accuracy = stats.rangeAccuracy == null ? '—' : '${(stats.rangeAccuracy! * 100).round()}%';

    final bars = [
      for (final item in stats.series)
        (
          label: DateId.shortDay(item.date),
          value: item.activity?.reviewsDone ?? 0,
          highlight: _isSameDay(item.date, today),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.xl),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(label: 'DIPELAJARI', value: '${stats.learned}', caption: 'kata total'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'DIKUASAI',
                value: '${stats.mastered}',
                caption: 'siap dipakai',
                tone: p.successText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'AKURASI ${stats.days} HARI',
                value: accuracy,
                caption: '${stats.rangeReviews} jawaban',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'STREAK TERBAIK',
                value: '${stats.bestStreak}',
                caption: 'hari berurutan',
                tone: p.accentText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'TOTAL ULASAN',
                value: '${stats.totalReviews}',
                caption: stats.totalAccuracy == null
                    ? 'belum ada'
                    : 'akurasi ${(stats.totalAccuracy! * 100).round()}%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'JATUH TEMPO',
                value: '${stats.due}',
                caption: 'perlu diulang',
                tone: p.warningText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ulasan ${stats.days} hari terakhir',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats.rangeReviews} ulasan · ${stats.activeDays} hari aktif',
                          style: context.tiny,
                        ),
                      ],
                    ),
                  ),
                  AppChip(label: 'maks ${stats.maxReviews}', height: 22, fontSize: 10),
                ],
              ),
              const SizedBox(height: 14),
              ActivityChart(bars: bars, labelEvery: stats.days > 10 ? 5 : 1),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kalender aktivitas',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  AppChip(label: '35 hari', height: 22, fontSize: 10),
                ],
              ),
              const SizedBox(height: 12),
              ref.watch(statsProvider(35)).when(
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text('Grafik tidak tersedia.', style: context.tiny),
                data: (heat) => StreakHeatmap(
                  days: [
                    for (final item in heat.series)
                      (date: item.date, reviews: item.activity?.reviewsDone ?? 0),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progres per kategori',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ref.watch(categoriesProvider).when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text('Kategori tidak tersedia.', style: context.tiny),
                data: (categories) => Column(
                  children: [
                    for (final category in categories.take(6))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 12,
                                  color: p.textSoft,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 4,
                              child: AppProgressBar(value: category.progress, height: 5),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 54,
                              child: Text(
                                '${category.learned}/${category.total}',
                                textAlign: TextAlign.right,
                                style: context.tiny.copyWith(fontSize: 10.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kata tersulit',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text('Paling sering kamu jawab salah.', style: context.tiny),
              const SizedBox(height: 8),
              ref.watch(hardestWordsProvider).when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text('Daftar tidak tersedia.', style: context.tiny),
                data: (words) => words.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Belum ada kata yang salah. Pertahankan!',
                          style: context.tiny,
                        ),
                      )
                    : Column(
                        children: [
                          for (final (index, item) in words.indexed) ...[
                            if (index > 0)
                              Divider(height: 1, color: p.divider),
                            WordRow(
                              item: item,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              onTap: () => context.push('/word/${item.word.id}'),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TARGET HARIAN', style: context.eyebrow),
              const SizedBox(height: 8),
              Text(
                stats.rangeReviews == 0
                    ? 'Belum ada aktivitas pada rentang ini.'
                    : 'Rata-rata ${(stats.rangeReviews / stats.days).toStringAsFixed(1)} ulasan per hari.',
                style: context.small,
              ),
              const SizedBox(height: 10),
              AppProgressBar(
                value: (stats.rangeAccuracy ?? 0).clamp(0, 1),
                tone: AppProgressTone.success,
              ),
              const SizedBox(height: 6),
              Text('Proporsi jawaban benar pada rentang ini.', style: context.tiny),
            ],
          ),
        ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
    this.tone,
  });

  final String label;
  final String value;
  final String caption;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.eyebrow.copyWith(fontSize: 9.5)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: tone ?? p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(caption, style: TextStyle(fontSize: 11, color: p.textSecondary)),
        ],
      ),
    );
  }
}
