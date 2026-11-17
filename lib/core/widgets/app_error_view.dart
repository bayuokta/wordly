import 'package:material_ui/material_ui.dart';

import '../design/app_palette.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';
import 'app_button.dart';

/// Tampilan error yang ramah + tombol coba lagi.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.compact = false,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: p.errorSoft, shape: BoxShape.circle),
              child: Icon(Icons.error_outline_rounded, size: 22, color: p.errorText),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
            if (message != null && !compact) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.tiny,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              AppButton(
                label: 'Coba lagi',
                icon: Icons.refresh_rounded,
                size: AppButtonSize.small,
                expand: false,
                variant: AppButtonVariant.ghost,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Versi ringkas untuk diletakkan di dalam card.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 16, color: p.errorText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: context.tiny.copyWith(color: p.errorText)),
        ),
        if (onRetry != null)
          GestureDetector(
            onTap: onRetry,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Coba lagi',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: p.primaryText,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
