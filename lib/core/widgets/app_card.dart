import 'package:material_ui/material_ui.dart';

import '../design/app_palette.dart';
import '../design/app_spacing.dart';

enum AppCardVariant {
  /// Card biasa: latar surface + garis halus.
  flat,

  /// Card terangkat (sheet, dialog).
  elevated,

  /// Panel "Kata hari ini" dengan gradien lembut.
  hero,

  /// Card sorotan biru (ajakan aksi).
  primary,

  /// Card sorotan kuning (streak/word of the day).
  accent,
}

/// Container dasar seluruh permukaan UI.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.variant = AppCardVariant.flat,
    this.onTap,
    this.radius = AppRadius.lg,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final double radius;
  final bool clip;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(widget.radius);

    final decoration = switch (widget.variant) {
      AppCardVariant.flat => BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: radius,
        boxShadow: p.cardShadow,
      ),
      AppCardVariant.elevated => BoxDecoration(
        color: p.surfaceElevated,
        border: Border.all(color: p.border),
        borderRadius: radius,
        boxShadow: p.cardShadow,
      ),
      AppCardVariant.hero => BoxDecoration(
        gradient: p.heroGradient,
        border: Border.all(color: p.heroBorder),
        borderRadius: radius,
        boxShadow: p.cardShadow,
      ),
      AppCardVariant.primary => BoxDecoration(
        color: p.primarySoft,
        border: Border.all(color: p.primaryLine),
        borderRadius: radius,
        boxShadow: p.cardShadow,
      ),
      AppCardVariant.accent => BoxDecoration(
        color: p.accentSoft,
        border: Border.all(color: p.accentLine),
        borderRadius: radius,
        boxShadow: p.cardShadow,
      ),
    };

    Widget content = Padding(padding: widget.padding, child: widget.child);

    if (widget.variant == AppCardVariant.hero) {
      content = Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [p.heroGlow, p.heroGlow.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          content,
        ],
      );
    }

    final card = AnimatedScale(
      scale: _pressed ? 0.99 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      child: DecoratedBox(
        decoration: decoration,
        child: widget.clip ? ClipRRect(borderRadius: radius, child: content) : content,
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
