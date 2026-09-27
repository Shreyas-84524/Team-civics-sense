import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';

/// Zonal SLA Monitoring Center for tracking 48h deadline breaches across the zone.
class ZoneSlaMonitoringSection extends StatelessWidget {
  final List<ComplaintModel> slaBreachedComplaints;
  final bool isLoading;
  final ValueChanged<String>? onViewComplaint;

  const ZoneSlaMonitoringSection({
    super.key,
    required this.slaBreachedComplaints,
    this.isLoading = false,
    this.onViewComplaint,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);
    final count = slaBreachedComplaints.length;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(
          color: count > 0 ? GovtThemeTokens.error.withValues(alpha: 0.3) : GovtThemeTokens.border,
        ),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (count > 0 ? GovtThemeTokens.error : GovtThemeTokens.success).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.timer_off_outlined,
                  color: count > 0 ? GovtThemeTokens.error : GovtThemeTokens.success,
                  size: 20,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONAL SLA BREACH MONITORING CENTER',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Unresolved grievances exceeding statutory 48-hour municipal turnaround',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (count > 0 ? GovtThemeTokens.error : GovtThemeTokens.success).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (count > 0 ? GovtThemeTokens.error : GovtThemeTokens.success).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$count Overdue in Zone',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: count > 0 ? GovtThemeTokens.error : GovtThemeTokens.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceLg,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (slaBreachedComplaints.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.verified_rounded, color: GovtThemeTokens.success, size: 40),
                    CivicFixSpacing.vSpaceMd,
                    Text(
                      '100% SLA Compliance in Active Zone',
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.success,
                      ),
                    ),
                    Text(
                      'No grievances have exceeded the 48-hour resolution SLA in this zone.',
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slaBreachedComplaints.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (context, index) => _buildMobileBreachCard(context, slaBreachedComplaints[index]),
            )
          else
            _buildDesktopBreachTable(context),
        ],
      ),
    );
  }

  Widget _buildDesktopBreachTable(BuildContext context) {
    final now = DateTime.now();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GovtThemeTokens.surfaceMuted),
        horizontalMargin: CivicFixSpacing.md,
        columnSpacing: CivicFixSpacing.lg,
        columns: const [
          DataColumn(label: Text('TICKET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('GRIEVANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('WARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('DEPARTMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('PRIORITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('ELAPSED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('OVERDUE BY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: slaBreachedComplaints.map((c) {
          final elapsed = now.difference(c.slaStartedAt).inHours;
          final overdue = elapsed - 48;

          return DataRow(
            cells: [
              DataCell(
                Text(
                  c.ticketNumber,
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.primaryDark,
                  ),
                ),
              ),
              DataCell(
                Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CivicFixTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              DataCell(
                Text(
                  'Ward ${c.location.ward ?? c.wardId ?? 'N/A'}',
                  style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Text(
                  c.effectiveDepartment,
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ),
              DataCell(GovtPriorityBadge.fromPriority(c.priority, isCompact: true)),
              DataCell(
                Text(
                  '$elapsed hrs',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.error,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.errorLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+$overdue hrs overdue',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              DataCell(
                onViewComplaint != null
                    ? ElevatedButton(
                        onPressed: () => onViewComplaint!(c.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GovtThemeTokens.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Inspect'),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileBreachCard(BuildContext context, ComplaintModel complaint) {
    final now = DateTime.now();
    final elapsed = now.difference(complaint.slaStartedAt).inHours;
    final overdue = elapsed - 48;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                complaint.ticketNumber,
                style: CivicFixTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: GovtThemeTokens.primaryDark,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              GovtPriorityBadge.fromPriority(complaint.priority, isCompact: true),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.errorLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+$overdue hrs overdue',
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Text(
            complaint.title,
            style: CivicFixTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textPrimary,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            'Ward ${complaint.location.ward ?? complaint.wardId ?? 'N/A'} · ${complaint.effectiveDepartment}',
            style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
          ),
          if (onViewComplaint != null) ...[
            CivicFixSpacing.vSpaceSm,
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onViewComplaint!(complaint.id),
                child: const Text('Inspect Grievance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
