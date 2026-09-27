import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../theme/govt_theme_tokens.dart';

/// Reusable Location, GIS, and Jurisdiction Card for Grievances.
class GovernmentComplaintLocationCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback? onOpenMap;

  const GovernmentComplaintLocationCard({
    super.key,
    required this.complaint,
    this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = complaint.location;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.location_on_outlined, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOCATION & MUNICIPAL JURISDICTION',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'GIS coordinates, landmark reference, and ward administrative boundaries',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onOpenMap != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.map_outlined, size: 14),
                  label: const Text('GIS Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: onOpenMap,
                ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          // Address
          Text(
            loc.address,
            style: CivicFixTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textPrimary,
            ),
          ),
          if (loc.landmark != null && loc.landmark!.isNotEmpty) ...[
            CivicFixSpacing.vSpaceXs,
            Text(
              'Landmark / Reference: ${loc.landmark}',
              style: CivicFixTypography.bodySmall.copyWith(
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ],
          CivicFixSpacing.vSpaceMd,

          // Coordinates & Jurisdiction Pill Grid
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _pill('Latitude', loc.latitude.toStringAsFixed(5)),
              _pill('Longitude', loc.longitude.toStringAsFixed(5)),
              _pill('Administrative Ward', 'Ward ${complaint.wardId ?? loc.ward ?? "N/A"}'),
              _pill('Operational Department', complaint.departmentName ?? complaint.assignedDepartmentId ?? "General"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: CivicFixTypography.caption.copyWith(
            color: GovtThemeTokens.textMuted,
            fontSize: 11,
          ),
          children: [
            TextSpan(
              text: value,
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textPrimary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
