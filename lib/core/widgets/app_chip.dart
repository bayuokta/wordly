import 'package:material_ui/material_ui.dart';

import '../design/app_palette.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';
import '../srs/sm2.dart';

enum AppChipTone { neutral, primary, accent, success, warning, error }

/// Chip/pill untuk level, kategori, part of speech, filter.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.tone = AppChipTone.neutral,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 26,
    this.fontSize = 11.5,
  });

  final String label;
  final AppChipTone tone;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fg, Color bg, Color border) = switch (tone) {
      AppChipTone.neutral => (p.textSecondary, p.chipBg, p.chipBorder),
      AppChipTone.primary => (p.primaryText, p.primarySoft, p.primaryLine),
      AppChipTone.accent => (p.accentText, p.accentSoft, p.accentLine),
      AppChipTone.success => (p.successText, p.successSoft, p.successLine),
      AppChipTone.warning => (p.warningText, p.warningSoft, p.warningLine),
      AppChipTone.error => (p.errorText, p.errorSoft, p.errorLine),
    };

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: fontSize + 1, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: fontSize,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: fg,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 5),
            Icon(trailingIcon, size: fontSize, color: fg),
          ],
        ],
      ),
    );
  }
}

/// Status belajar sebuah kata (label untuk UI).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final WordStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, AppChipTone tone) = switch (status) {
      WordStatus.newWord => ('Baru', AppChipTone.primary),
      WordStatus.learning => ('Perlu diulang', AppChipTone.warning),
      WordStatus.review => ('Diulang', AppChipTone.neutral),
      WordStatus.mastered => ('Dikuasai', AppChipTone.success),
    };

    return AppChip(label: label, tone: tone, height: 22, fontSize: 10);
  }
}
