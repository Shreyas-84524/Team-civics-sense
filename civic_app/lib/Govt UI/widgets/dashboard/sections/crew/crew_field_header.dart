import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../models/govt_user_model.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Top header for Department Crew / Field Operations workspace.
class CrewFieldHeader extends StatelessWidget {
  final GovtUserModel crewUser;
  final String wardCode;
  final String departmentName;
  final VoidCallback? onRefresh;

  const CrewFieldHeader({
    super.key,
    required this.crewUser,
    required this.wardCode,
    required this.departmentName,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.xl,
        vertical: CivicFixSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        border: Border(
          bottom: BorderSide(color: GovtThemeTokens.border),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: GovtThemeTokens.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.handyman_rounded,
                    color: GovtThemeTokens.primary,
                    size: 24,
                  ),
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Work',
                      style: CivicFixTypography.h2.copyWith(
                        color: GovtThemeTokens.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      'Assigned field operations for $departmentName — $wardCode Ward',
                      style: CivicFixTypography.bodySmall.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile && onRefresh != null) ...[
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh Assignments',
                  onPressed: onRefresh,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
