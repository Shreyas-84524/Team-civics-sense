import 'package:flutter/material.dart';
import '../cache/cache_metadata.dart';
import '../theme/civicfix_design_tokens.dart';
import 'civic_fix_info_banner.dart';

/// Reusable, accessible banner indicating that the view is displaying cached offline data.
///
/// Follows Design.md:
/// - Uses warning/informational semantic tokens
/// - Clean hairline borders
/// - Refresh action slot
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

    Widget? refreshAction;
    if (onRefresh != null) {
      refreshAction = InkWell(
        onTap: onRefresh,
        borderRadius: CivicFixRadius.chipRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.spaceXs + 2,
            vertical: CivicFixSpacing.spaceXs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.refresh_rounded,
                size: 14,
                color: CivicFixColors.warning,
              ),
              const SizedBox(width: 3),
              Text(
                'Refresh',
                style: CivicFixTypographyTokens.labelSm.copyWith(
                  color: CivicFixColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: isCompact ? EdgeInsets.zero : const EdgeInsets.only(bottom: CivicFixSpacing.spaceMd),
      child: CivicFixInfoBanner.warning(
        message: message,
        icon: Icons.cloud_off_rounded,
        action: refreshAction,
        isCompact: isCompact,
      ),
    );
  }
}
