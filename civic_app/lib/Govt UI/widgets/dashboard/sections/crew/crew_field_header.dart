import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../models/govt_user_model.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_jurisdiction_badge.dart';
import '../../../common/govt_role_badge.dart';

/// Top header for Department Crew / Field Operations workspace.
/// Displays dynamic context badges: `[<WARD> WARD]`, `[<DEPARTMENT>]`, `[CREW]`.
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Badges Row
              Row(
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
              ),
              CivicFixSpacing.vSpaceMd,

              // Badges Row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GovtJurisdictionBadge.ward(
                    '$wardCode WARD',
                    showIcon: true,
                    withBrackets: true,
                    uppercase: true,
                  ),
                  GovtJurisdictionBadge.department(
                    departmentName.toUpperCase(),
                    showIcon: true,
                    withBrackets: true,
                    uppercase: true,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '[CREW]',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: const Color(0xFF0284C7),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  GovtRoleBadge(role: crewUser.govtRole),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
