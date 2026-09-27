import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/government_role.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Standard Role Badge for displaying government officer administrative roles.
class GovtRoleBadge extends StatelessWidget {
  final GovernmentRole role;
  final bool isCompact;

  const GovtRoleBadge({
    super.key,
    required this.role,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color backgroundColor;
    String label;
    IconData icon;

    switch (role) {
      case GovernmentRole.governmentSuperAdmin:
        badgeColor = const Color(0xFF6B21A8); // Deep Royal Purple
        backgroundColor = const Color(0xFFF3E8FF);
        label = 'Super Admin';
        icon = Icons.verified_user_rounded;
        break;

      case GovernmentRole.zonalDmc:
        badgeColor = const Color(0xFF1E40AF); // Zonal Blue
        backgroundColor = const Color(0xFFDBEAFE);
        label = 'Zonal DMC';
        icon = Icons.domain_rounded;
        break;

      case GovernmentRole.centralDepartmentHod:
        badgeColor = const Color(0xFF0F766E); // Teal
        backgroundColor = const Color(0xFFCCFBF1);
        label = 'Central HOD';
        icon = Icons.account_balance_rounded;
        break;

      case GovernmentRole.wardOfficer:
        badgeColor = GovtThemeTokens.primary;
        backgroundColor = const Color(0xFFE8F2F8);
        label = 'Ward Officer';
        icon = Icons.home_work_rounded;
        break;

      case GovernmentRole.wardDepartmentLead:
        badgeColor = const Color(0xFFD97706); // Amber
        backgroundColor = const Color(0xFFFEF3C7);
        label = 'Department Lead';
        icon = Icons.engineering_rounded;
        break;

      case GovernmentRole.departmentCrew:
        badgeColor = const Color(0xFF047857); // Emerald Green
        backgroundColor = const Color(0xFFD1FAE5);
        label = 'Department Crew';
        icon = Icons.handyman_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? CivicFixSpacing.sm : CivicFixSpacing.md,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 12 : 14,
            color: badgeColor,
          ),
          CivicFixSpacing.hSpaceXs,
          Text(
            label,
            style: GovtTypography.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 10 : 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
