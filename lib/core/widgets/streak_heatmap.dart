import 'package:material_ui/material_ui.dart';

import '../design/app_palette.dart';
import '../utils/date_id.dart';

/// Kalender aktivitas gaya "heatmap" (7 baris = hari, tiap kolom = minggu).
class StreakHeatmap extends StatelessWidget {
  const StreakHeatmap({super.key, required this.days});

  /// Urut dari terlama → terbaru; panjang kelipatan 7.
  final List<({DateTime date, int reviews})> days;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (days.isEmpty) return const SizedBox.shrink();

    final max = days.fold<int>(1, (m, d) => d.reviews > m ? d.reviews : m);
    final weeks = <List<({DateTime date, int reviews})>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, (i + 7).clamp(0, days.length)));
    }

    Color shade(int value) {
      if (value == 0) return p.surfaceElevated;
      final ratio = value / max;
      if (ratio <= 0.25) return p.primary.withValues(alpha: 0.28);
      if (ratio <= 0.5) return p.primary.withValues(alpha: 0.48);
      if (ratio <= 0.75) return p.primary.withValues(alpha: 0.72);
      return p.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6, top: 1),
              child: Column(
                children: [
                  for (var i = 0; i < 7; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SizedBox(
                        width: 10,
                        height: 14,
                        child: Text(
                          i.isEven ? DateId.shortDay(DateTime(2024, 1, 1 + i)) : '',
                          style: TextStyle(fontSize: 8, height: 1.6, color: p.textDim),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            for (final week in weeks)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: [
                    for (final day in week)
                      Tooltip(
                        message: '${day.date.day}/${day.date.month}: ${day.reviews} ulasan',
                        child: Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: shade(day.reviews),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Makin pekat = makin banyak ulasan',
          style: TextStyle(fontSize: 10.5, height: 1.3, color: p.textDim),
        ),
      ],
    );
  }
}
