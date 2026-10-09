import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/mappers/canonical_display_mappers.dart';
import '../../../core/models/hazard_model.dart';
import '../../../core/repositories/complaint_repository.dart';
import '../../../core/repositories/repository_locator.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/civic_fix_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Compact floating card displayed when a citizen taps an individual map complaint dot.
class HazardInfoCard extends StatelessWidget {
  final HazardModel hazard;
  final VoidCallback onClose;
  final ComplaintRepository? complaintRepository;

  const HazardInfoCard({
    super.key,
    required this.hazard,
    required this.onClose,
    this.complaintRepository,
  });

  Future<void> _navigateToComplaintDetails(BuildContext context) async {
    final repo = complaintRepository ?? RepositoryLocator.complaintRepository;
    final complaintId = hazard.complaintId ?? hazard.id;
    // The display ticket number is never an internal document identifier.
    final complaint = await repo.getComplaintById(complaintId);

    if (context.mounted) {
      if (complaint != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.complaintDetails,
          arguments: complaint,
        );
      } else {
        // Navigate with ID string argument
        Navigator.pushNamed(
          context,
          AppRoutes.complaintDetails,
          arguments: complaintId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayCategory = localizedCategory(hazard.category, context: context, l10n: l10n);

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      elevation: 6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Category Icon & Name + Ticket Number + Close 'X' Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hazard.statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hazard.categoryIcon,
                  color: hazard.statusColor,
                  size: 16,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayCategory,
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CivicFixColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hazard.ticketNumber != null)
                      Text(
                        hazard.ticketNumber!,
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: CivicFixColors.secondaryText,
                ),
                tooltip: l10n?.close ?? 'Close complaint card',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClose,
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,

          // 1. Complaint / Report Title (Citizen input is preserved)
          Text(
            hazard.title,
            style: CivicFixTypography.h3.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          CivicFixSpacing.vSpaceXs,

          // 2. Reported Timestamp (authoritative createdAt)
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: CivicFixColors.secondaryText,
              ),
              CivicFixSpacing.hSpaceXs,
              Text(
                '${l10n?.reportedTime ?? 'Reported'} ${DateFormatter.formatRelativeTime(hazard.createdAt)}',
                style: CivicFixTypography.caption.copyWith(
                  color: CivicFixColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Location Info (if address present)
          if (hazard.address.isNotEmpty) ...[
            CivicFixSpacing.vSpaceXs,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: CivicFixColors.secondaryText,
                ),
                CivicFixSpacing.hSpaceXs,
                Expanded(
                  child: Text(
                    '${hazard.address}${hazard.landmark != null && hazard.landmark!.isNotEmpty ? " (${hazard.landmark})" : ""}',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          CivicFixSpacing.vSpaceMd,

          // 3. Current Working Phase / Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.currentPhase ?? 'Current Phase',
                style: CivicFixTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: CivicFixColors.primaryText,
                ),
              ),
              StatusBadge(
                status: hazard.status,
                customLabel: hazard.citizenPhaseLabel,
                isCompact: true,
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // 4. Primary Action: View Details
          CivicFixButton(
            text: l10n?.viewDetails ?? 'View Details',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _navigateToComplaintDetails(context),
          ),
        ],
      ),
    );
  }
}
