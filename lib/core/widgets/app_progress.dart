import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../design/app_palette.dart';
import '../design/app_spacing.dart';

enum AppProgressTone { primary, accent, success, warning }

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.tone = AppProgressTone.primary,
    this.height = 6,
  });

  /// Nilai 0..1.
  final double value;
  final AppProgressTone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (tone) {
      AppProgressTone.primary => p.primary,
      AppProgressTone.accent => p.accent,
      AppProgressTone.success => p.success,
      AppProgressTone.warning => p.warning,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: height,
        color: p.track,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: AppMotion.slow,
            curve: AppMotion.curve,
            builder: (context, animated, _) => FractionallySizedBox(
              widthFactor: animated,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cincin progres dengan angka di tengah (target harian).
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.strokeWidth = 6,
    this.tone = AppProgressTone.primary,
    this.child,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final AppProgressTone tone;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (tone) {
      AppProgressTone.primary => p.primary,
      AppProgressTone.accent => p.accent,
      AppProgressTone.success => p.success,
      AppProgressTone.warning => p.warning,
    };

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: AppMotion.slow,
        curve: AppMotion.curve,
        builder: (context, animated, _) => CustomPaint(
          painter: _RingPainter(
            value: animated,
            track: p.track,
            color: color,
            strokeWidth: strokeWidth,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.track,
    required this.color,
    required this.strokeWidth,
  });

  final double value;
  final Color track;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = track;
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
    if (value > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, valuePaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.track != track ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
