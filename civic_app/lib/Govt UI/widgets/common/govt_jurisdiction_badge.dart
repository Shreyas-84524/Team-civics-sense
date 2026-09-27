import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Supported administrative jurisdiction contexts for badges.
enum GovtJurisdictionType {
  zone,
  ward,
  department,
  role;

  IconData get icon {
    switch (this) {
      case GovtJurisdictionType.zone:
        return Icons.map_rounded;
      case GovtJurisdictionType.ward:
        return Icons.location_city_rounded;
      case GovtJurisdictionType.department:
        return Icons.apartment_rounded;
      case GovtJurisdictionType.role:
        return Icons.badge_outlined;
    }
  }

  Color get color {
    switch (this) {
      case GovtJurisdictionType.zone:
        return const Color(0xFF4338CA); // Indigo
      case GovtJurisdictionType.ward:
        return const Color(0xFF047857); // Emerald
      case GovtJurisdictionType.department:
        return const Color(0xFF1D4ED8); // Royal Blue
      case GovtJurisdictionType.role:
        return GovtThemeTokens.primary; // Authoritative Navy
    }
  }

  Color get backgroundColor {
    switch (this) {
      case GovtJurisdictionType.zone:
        return const Color(0xFFEEF2FF);
      case GovtJurisdictionType.ward:
        return const Color(0xFFECFDF5);
      case GovtJurisdictionType.department:
        return const Color(0xFFEFF6FF);
      case GovtJurisdictionType.role:
        return const Color(0xFFEFF3F0);
    }
  }
}

/// Compact reusable identifier for Zone, Ward, Department, and Role contexts.
class GovtJurisdictionBadge extends StatelessWidget {
  final String label;
  final GovtJurisdictionType type;
  final bool isCompact;
  final bool showIcon;
  final bool uppercase;
  final bool withBrackets;

  const GovtJurisdictionBadge({
    super.key,
    required this.label,
    required this.type,
    this.isCompact = false,
    this.showIcon = true,
    this.uppercase = true,
    this.withBrackets = true,
  });

  /// Factory for Zone identifier (e.g. `[ZONE 4]`).
  factory GovtJurisdictionBadge.zone(
    String zoneName, {
    bool isCompact = false,
    bool showIcon = true,
    bool uppercase = true,
    bool withBrackets = true,
  }) {
    final text = uppercase
        ? (zoneName.toUpperCase().contains('ZONE') ? zoneName : 'ZONE $zoneName')
        : zoneName;
    return GovtJurisdictionBadge(
      label: text,
      type: GovtJurisdictionType.zone,
      isCompact: isCompact,
      showIcon: showIcon,
      uppercase: uppercase,
      withBrackets: withBrackets,
    );
  }

  /// Factory for Ward identifier (e.g. `[N WARD]`).
  factory GovtJurisdictionBadge.ward(
    String wardName, {
    bool isCompact = false,
    bool showIcon = true,
    bool uppercase = true,
    bool withBrackets = true,
  }) {
    final text = uppercase
        ? (wardName.toUpperCase().contains('WARD') ? wardName : '$wardName WARD')
        : wardName;
    return GovtJurisdictionBadge(
      label: text,
      type: GovtJurisdictionType.ward,
      isCompact: isCompact,
      showIcon: showIcon,
      uppercase: uppercase,
      withBrackets: withBrackets,
    );
  }

  /// Factory for Department identifier (e.g. `[MAINTENANCE]`).
  factory GovtJurisdictionBadge.department(
    String departmentName, {
    bool isCompact = false,
    bool showIcon = true,
    bool uppercase = true,
    bool withBrackets = true,
  }) {
    return GovtJurisdictionBadge(
      label: departmentName,
      type: GovtJurisdictionType.department,
      isCompact: isCompact,
      showIcon: showIcon,
      uppercase: uppercase,
      withBrackets: withBrackets,
    );
  }

  /// Factory for Role identifier (e.g. `[WARD OFFICER]`).
  factory GovtJurisdictionBadge.role(
    String roleName, {
    bool isCompact = false,
    bool showIcon = true,
    bool uppercase = true,
    bool withBrackets = true,
  }) {
    return GovtJurisdictionBadge(
      label: roleName,
      type: GovtJurisdictionType.role,
      isCompact: isCompact,
      showIcon: showIcon,
      uppercase: uppercase,
      withBrackets: withBrackets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = uppercase ? label.toUpperCase() : label;
    final text = withBrackets ? '[$display]' : display;
    final color = type.color;
    final bg = type.backgroundColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? CivicFixSpacing.xs + 2 : CivicFixSpacing.sm + 2,
        vertical: isCompact ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: GovtThemeTokens.chipRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(
              type.icon,
              size: isCompact ? 11 : 13,
              color: color,
            ),
            SizedBox(width: isCompact ? 3 : 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GovtTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 10 : 11,
                letterSpacing: 0.4,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
