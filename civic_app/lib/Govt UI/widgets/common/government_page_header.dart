import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_responsive.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import 'govt_breadcrumbs.dart';

/// Standard page header component for all Government views.
class GovernmentPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<GovtBreadcrumbItem>? breadcrumbs;
  final Widget? jurisdictionBadge;
  final Widget? statusWidget;
  final Widget? primaryAction;
  final List<Widget>? secondaryActions;

  const GovernmentPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.jurisdictionBadge,
    this.statusWidget,
    this.primaryAction,
    this.secondaryActions,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? CivicFixSpacing.md : CivicFixSpacing.xl,
        vertical: isMobile ? CivicFixSpacing.md : CivicFixSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: GovtThemeTokens.surface,
        border: GovtThemeTokens.bottomBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            GovtBreadcrumbs(items: breadcrumbs!),
            CivicFixSpacing.vSpaceSm,
          ],

          // Title & Action Row
          if (isMobile)
            _buildMobileLayout(context)
          else
            _buildDesktopLayout(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title, Subtitle, Badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GovtTypography.pageTitle,
                    ),
                  ),
                  if (jurisdictionBadge != null) ...[
                    CivicFixSpacing.hSpaceSm,
                    jurisdictionBadge!,
                  ],
                  if (statusWidget != null) ...[
                    CivicFixSpacing.hSpaceSm,
                    statusWidget!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GovtTypography.bodySmall.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Actions
        if (secondaryActions != null || primaryAction != null) ...[
          CivicFixSpacing.hSpaceLg,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (secondaryActions != null) ...[
                ...secondaryActions!.map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(right: CivicFixSpacing.sm),
                    child: action,
                  ),
                ),
              ],
              ?primaryAction,
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GovtTypography.pageTitle.copyWith(fontSize: 20),
              ),
            ),
            if (jurisdictionBadge != null) ...[
              CivicFixSpacing.hSpaceSm,
              jurisdictionBadge!,
            ],
          ],
        ),
        if (statusWidget != null) ...[
          CivicFixSpacing.vSpaceXs,
          statusWidget!,
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GovtTypography.bodySmall.copyWith(
              color: GovtThemeTokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        if (primaryAction != null || secondaryActions != null) ...[
          CivicFixSpacing.vSpaceMd,
          Wrap(
            spacing: CivicFixSpacing.sm,
            runSpacing: CivicFixSpacing.sm,
            children: [
              ?primaryAction,
              ...?secondaryActions,
            ],
          ),
        ],
      ],
    );
  }
}
