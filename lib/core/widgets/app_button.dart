import 'package:material_ui/material_ui.dart';

import '../design/app_palette.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';

enum AppButtonVariant { primary, ghost, warn, success, text }

enum AppButtonSize { medium, small }

/// Tombol utama aplikasi.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconAfter = false,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool iconAfter;
  final bool loading;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isSmall = widget.size == AppButtonSize.small;

    final (Color background, Color foreground, Color border) = switch (widget.variant) {
      AppButtonVariant.primary => (p.primary, p.onPrimary, Colors.transparent),
      AppButtonVariant.ghost => (p.ghostBg, p.textPrimary, p.border),
      AppButtonVariant.warn => (p.warningSoft, p.warningText, p.warningLine),
      AppButtonVariant.success => (p.successSoft, p.successText, p.successLine),
      AppButtonVariant.text => (Colors.transparent, p.primaryText, Colors.transparent),
    };

    final height = isSmall ? 40.0 : 50.0;
    final radius = BorderRadius.circular(isSmall ? 12 : AppRadius.md);
    final fontSize = isSmall ? 13.5 : 15.0;

    final iconWidget = widget.loading
        ? SizedBox(
            width: isSmall ? 15 : 17,
            height: isSmall ? 15 : 17,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : (widget.icon == null
              ? null
              : Icon(widget.icon, size: isSmall ? 16 : 17, color: foreground));

    final label = Flexible(
      child: Text(
        widget.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );

    final children = <Widget>[
      if (iconWidget != null && !widget.iconAfter) ...[iconWidget, const SizedBox(width: 8)],
      if (widget.loading && widget.label.isEmpty) iconWidget ?? const SizedBox.shrink() else label,
      if (iconWidget != null && widget.iconAfter) ...[const SizedBox(width: 8), iconWidget],
    ];

    final button = AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      child: AnimatedOpacity(
        opacity: _enabled ? 1 : 0.45,
        duration: AppMotion.fast,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 14 : 18),
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );

    if (!_enabled) return button;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: button,
    );
  }
}
