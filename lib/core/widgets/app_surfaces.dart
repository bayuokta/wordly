import 'package:material_ui/material_ui.dart';

import '../design/app_palette.dart';
import '../design/app_typography.dart';

enum IconTileTone { primary, accent, success, warning, error, neutral }

/// Kotak ikon kecil (padanan `.ico-box` di mockup).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.tone = IconTileTone.primary,
    this.size = 34,
    this.iconSize = 17,
  });

  final IconData icon;
  final IconTileTone tone;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fg, Color bg) = switch (tone) {
      IconTileTone.primary => (p.primaryText, p.primarySoft),
      IconTileTone.accent => (p.accentText, p.accentSoft),
      IconTileTone.success => (p.successText, p.successSoft),
      IconTileTone.warning => (p.warningText, p.warningSoft),
      IconTileTone.error => (p.errorText, p.errorSoft),
      IconTileTone.neutral => (p.textSecondary, p.surfaceElevated),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size <= 30 ? 9 : 10),
      ),
      child: Icon(icon, size: iconSize, color: fg),
    );
  }
}

/// Judul bagian dengan aksi opsional di kanan ("Semua kata", "Lihat semua").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: onAction == null ? p.textDim : p.primaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Header halaman: eyebrow + judul besar + info di kanan.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.action,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow case final eyebrowLabel?)
                  Text(eyebrowLabel.toUpperCase(), style: context.eyebrow),
                const SizedBox(height: 7),
                Text(title, style: text.displaySmall),
              ],
            ),
          ),
          if (trailing case final trailingWidget?)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: DefaultTextStyle.merge(
                style: context.tiny,
                child: trailingWidget,
              ),
            ),
          ?action,
        ],
      ),
    );
  }
}

/// Kotak ikon besar di tengah, untuk kondisi kosong.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle),
          child: Icon(icon, size: 26, color: p.primaryText),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, height: 1.5, color: p.textSecondary),
        ),
        if (action case final actionWidget?) ...[const SizedBox(height: 16), actionWidget],
      ],
    );
  }
}
