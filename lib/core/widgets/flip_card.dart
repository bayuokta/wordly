import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../design/app_spacing.dart';

/// Kartu dengan animasi putar 3D (350 ms, sesuai design system).
///
/// Dipakai sesi Flashcard dan Review.
class FlipCard extends StatefulWidget {
  const FlipCard({super.key, required this.flipped, required this.front, required this.back});

  final bool flipped;
  final Widget front;
  final Widget back;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.cardFlip,
    value: widget.flipped ? 1 : 0,
  );

  @override
  void didUpdateWidget(FlipCard oldWidget) {
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
