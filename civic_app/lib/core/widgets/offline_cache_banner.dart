import 'package:flutter/material.dart';
import '../cache/cache_metadata.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Reusable, accessible banner indicating that the view is displaying cached offline data.
class OfflineCacheBanner extends StatelessWidget {
  final DateTime? cachedAt;
  final String? customMessage;
  final VoidCallback? onRefresh;
  final bool isCompact;

  const OfflineCacheBanner({
    super.key,
    this.cachedAt,
    this.customMessage,
    this.onRefresh,
    this.isCompact = false,
  });

  String _formatAgeText() {
    if (customMessage != null) return customMessage!;
    if (cachedAt == null) return 'Offline — Showing saved information';

    final metadata = CacheMetadata(boxName: 'view', cachedAt: cachedAt!);
    if (metadata.age.inMinutes < 2) {
      return 'Offline — Showing recently saved information';
    }
    return 'Offline — Saved ${metadata.formattedAge}';
  }

  @override
  Widget build(BuildContext context) {
    final message = _formatAgeText();

    return Semantics(
      label: 'Offline indicator. $message.',
      container: true,
      child: Container(
        width: double.infinity,
        margin: isCompact ? EdgeInsets.zero : const EdgeInsets.only(bottom: CivicFixSpacing.md),
        padding: EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.md,
          vertical: isCompact ? CivicFixSpacing.xs : CivicFixSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: CivicFixColors.statusInProgressBg,
          borderRadius: CivicFixRadius.cardRadius,
          border: Border.all(
            color: CivicFixColors.alertDark.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 16,
              color: CivicFixColors.alertDark,
            ),
            const SizedBox(width: CivicFixSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: CivicFixTypography.captionMedium.copyWith(
                  color: CivicFixColors.alertDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(width: CivicFixSpacing.xs),
              InkWell(
                onTap: onRefresh,
                borderRadius: CivicFixRadius.chipRadius,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: CivicFixColors.alertDark,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Refresh',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: CivicFixColors.alertDark,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
