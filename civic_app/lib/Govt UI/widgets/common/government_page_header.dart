import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? CivicFixSpacing.md : CivicFixSpacing.xl,
            vertical: isNarrow ? CivicFixSpacing.md : CivicFixSpacing.lg,
          ),
          decoration: const BoxDecoration(
            color: GovtThemeTokens.surface,
            border: GovtThemeTokens.bottomBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Breadcrumbs
              if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
                GovtBreadcrumbs(items: breadcrumbs!),
                CivicFixSpacing.vSpaceSm,
              ],

              // Title & Action Row
              if (isNarrow)
                _buildMobileLayout(context)
              else
                _buildDesktopLayout(context),
            ],
          ),
        );
      },
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: CivicFixSpacing.sm,
                runSpacing: CivicFixSpacing.xs,
                children: [
                  Text(
                    title,
                    style: GovtTypography.pageTitle,
                  ),
                  ?jurisdictionBadge,
                  ?statusWidget,
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
          Flexible(
            fit: FlexFit.loose,
            child: Wrap(
              spacing: CivicFixSpacing.sm,
              runSpacing: CivicFixSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...?secondaryActions,
                ?primaryAction,
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GovtTypography.pageTitle.copyWith(fontSize: 20),
        ),
        if (jurisdictionBadge != null) ...[
          CivicFixSpacing.vSpaceXs,
          jurisdictionBadge!,
        ],
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
