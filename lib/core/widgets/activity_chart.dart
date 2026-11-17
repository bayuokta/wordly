import 'package:material_ui/material_ui.dart';

import '../design/app_palette.dart';

/// Grafik batang sederhana untuk aktivitas harian.
class ActivityChart extends StatelessWidget {
  const ActivityChart({
    super.key,
    required this.bars,
    this.height = 108,
    this.maxValue,
    this.labelEvery = 1,
  });

  /// Label + nilai per batang, urut kiri → kanan (terlama → terbaru).
  final List<({String label, int value, bool highlight})> bars;
  final double height;
  final int? maxValue;

  /// Tampilkan label setiap N batang (untuk 30 hari agar tidak berdesakan).
  final int labelEvery;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final max = maxValue ?? bars.fold<int>(1, (m, b) => b.value > m ? b.value : m);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (index, bar) in bars.indexed)
            Expanded(
              child: Tooltip(
                message: '${bar.label}: ${bar.value} ulasan',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: bar.value == 0 ? 0.02 : (bar.value / max).clamp(0.06, 1.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: bar.highlight ? p.primary : p.track,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5),
                                bottom: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      index % labelEvery == 0 || index == bars.length - 1 ? bar.label : '',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        height: 1,
                        color: bar.highlight ? p.primaryText : p.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
