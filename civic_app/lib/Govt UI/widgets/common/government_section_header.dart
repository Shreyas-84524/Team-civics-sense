import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Reusable section title block for dashboard and operations content blocks.
class GovernmentSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? badge;
  final int? count;
  final Widget? action;

  const GovernmentSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.count,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: CivicFixSpacing.sm,
                  runSpacing: 2,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GovtTypography.sectionTitle,
                    ),
                    if (count != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GovtThemeTokens.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: GovtThemeTokens.border),
                        ),
                        child: Text(
                          '$count',
                          style: GovtTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: GovtThemeTokens.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ?badge,
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GovtTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            CivicFixSpacing.hSpaceMd,
            action!,
          ],
        ],
      ),
    );
  }
}
