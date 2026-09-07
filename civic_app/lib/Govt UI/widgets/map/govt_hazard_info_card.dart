import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/hazard_model.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_theme_tokens.dart';

/// Floating / Docked Operational Card displayed when an officer taps a hazard pin on the Government GIS map.
class GovtHazardInfoCard extends StatelessWidget {
  final HazardModel hazard;
  final VoidCallback onClose;
  final GovtComplaintRepository? complaintRepository;

  const GovtHazardInfoCard({
    super.key,
    required this.hazard,
    required this.onClose,
    this.complaintRepository,
  });

  Future<void> _navigateToDetails(BuildContext context) async {
    final repo = complaintRepository ?? MockGovtComplaintRepository();
    final complaintId = hazard.complaintId ?? hazard.id;

    var complaint = await repo.getComplaintById(complaintId);
    if (complaint == null && hazard.ticketNumber != null) {
      final all = await repo.getComplaints();
      try {
        complaint = all.firstWhere((c) => c.ticketNumber == hazard.ticketNumber);
      } catch (_) {}
    }

    if (context.mounted) {
      if (complaint != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.govtComplaintDetails,
          arguments: complaint,
        );
      } else {
        Navigator.pushNamed(
          context,
          AppRoutes.govtComplaintDetails,
          arguments: complaintId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category, Ticket #, Status, Close
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hazard.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hazard.categoryIcon,
                    color: hazard.statusColor,
                    size: 20,
                  ),
                ),
                CivicFixSpacing.hSpaceSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hazard.category.name,
                        style: CivicFixTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hazard.ticketNumber != null)
                        Text(
                          hazard.ticketNumber!,
                          style: CivicFixTypography.caption.copyWith(
                            color: GovtThemeTokens.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                StatusBadge(status: hazard.status),
                CivicFixSpacing.hSpaceSm,
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: GovtThemeTokens.textSecondary,
                  tooltip: 'Close details',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onClose,
                ),
              ],
            ),
            CivicFixSpacing.vSpaceMd,

            // Title
            Text(
              hazard.title,
              style: CivicFixTypography.h3.copyWith(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            CivicFixSpacing.vSpaceSm,

            // Location details
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: GovtThemeTokens.textSecondary),
                CivicFixSpacing.hSpaceXs,
                Expanded(
                  child: Text(
                    '${hazard.ward != null ? "${hazard.ward} • " : ""}${hazard.address}',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            CivicFixSpacing.vSpaceXs,

            // Severity & Date Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hazard.severity.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: hazard.severity.color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Severity: ${hazard.severity.label.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hazard.severity.color,
                    ),
                  ),
                ),
                CivicFixSpacing.hSpaceSm,
                Text(
                  'Reported ${DateFormatter.formatRelative(hazard.createdAt)}',
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            CivicFixSpacing.vSpaceMd,

            // Image Thumbnail (if available)
            if (hazard.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Image.network(
                    hazard.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF0F0F0),
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              CivicFixSpacing.vSpaceMd,
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('View Grievance Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GovtThemeTokens.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 38),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: GovtThemeTokens.buttonRadius,
                      ),
                    ),
                    onPressed: () => _navigateToDetails(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
