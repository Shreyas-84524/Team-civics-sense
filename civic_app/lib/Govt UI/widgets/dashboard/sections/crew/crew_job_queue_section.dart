import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../services/government_crew_work_service.dart';
import '../../../../theme/govt_theme_tokens.dart';
import 'crew_job_card.dart';

/// Primary Work Queue Section for frontline crew technicians.
class CrewJobQueueSection extends StatelessWidget {
  final List<CrewJobItem> jobs;
  final String activeTab; // 'all', 'in_progress', 'critical', 'sla_risk'
  final ComplaintPriority? selectedPriority;
  final ComplaintStatus? selectedStatus;
  final String? selectedSla;
  final String searchQuery;
  final ValueChanged<String> onTabChanged;
  final ValueChanged<ComplaintPriority?> onPriorityChanged;
  final ValueChanged<ComplaintStatus?> onStatusChanged;
  final ValueChanged<String?> onSlaChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onResetFilters;
  final void Function(CrewJobItem job) onViewDetails;
  final void Function(CrewJobItem job)? onStartJob;

  const CrewJobQueueSection({
    super.key,
    required this.jobs,
    required this.activeTab,
    this.selectedPriority,
    this.selectedStatus,
    this.selectedSla,
    required this.searchQuery,
    required this.onTabChanged,
    required this.onPriorityChanged,
    required this.onStatusChanged,
    required this.onSlaChanged,
    required this.onSearchChanged,
    required this.onResetFilters,
    required this.onViewDetails,
    this.onStartJob,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header & Search
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: GovtThemeTokens.primary,
                size: 20,
              ),
            ),
            CivicFixSpacing.hSpaceSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY WORK QUEUE',
                    style: CivicFixTypography.h3.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Ordered by urgency, critical status, and SLA deadlines (${jobs.length} jobs)',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceMd,

        // Search & Filter Toolbar
        Container(
          padding: const EdgeInsets.all(CivicFixSpacing.md),
          decoration: BoxDecoration(
            color: GovtThemeTokens.surface,
            borderRadius: GovtThemeTokens.cardRadius,
            border: Border.all(color: GovtThemeTokens.border),
          ),
          child: Column(
            children: [
              // Search field
              TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by Ticket ID, Title, Address...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => onSearchChanged(''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: GovtThemeTokens.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: GovtThemeTokens.surfaceMuted,
                ),
              ),
              CivicFixSpacing.vSpaceSm,

              // Filter Dropdowns
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Priority Dropdown
                    DropdownButton<ComplaintPriority?>(
                      value: selectedPriority,
                      hint: const Text('Priority: All'),
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Priority: All'),
                        ),
                        DropdownMenuItem(
                          value: ComplaintPriority.emergency,
                          child: Text('Critical / Emergency'),
                        ),
                        DropdownMenuItem(
                          value: ComplaintPriority.high,
                          child: Text('High Priority'),
                        ),
                        DropdownMenuItem(
                          value: ComplaintPriority.medium,
                          child: Text('Medium Priority'),
                        ),
                        DropdownMenuItem(
                          value: ComplaintPriority.low,
                          child: Text('Low Priority'),
                        ),
                      ],
                      onChanged: onPriorityChanged,
                    ),
                    CivicFixSpacing.hSpaceMd,

                    // Status Dropdown
                    DropdownButton<ComplaintStatus?>(
                      value: selectedStatus,
                      hint: const Text('Status: All'),
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Status: All'),
                        ),
                        DropdownMenuItem(
                          value: ComplaintStatus.assigned,
                          child: Text('Assigned'),
                        ),
                        DropdownMenuItem(
                          value: ComplaintStatus.inProgress,
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: ComplaintStatus.verified,
                          child: Text('Awaiting Verification'),
                        ),
                      ],
                      onChanged: onStatusChanged,
                    ),
                    CivicFixSpacing.hSpaceMd,

                    // SLA Dropdown
                    DropdownButton<String?>(
                      value: selectedSla,
                      hint: const Text('SLA: All'),
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('SLA: All')),
                        DropdownMenuItem(
                          value: 'breached',
                          child: Text('SLA Breached'),
                        ),
                        DropdownMenuItem(
                          value: 'atRisk',
                          child: Text('SLA At Risk'),
                        ),
                        DropdownMenuItem(
                          value: 'healthy',
                          child: Text('SLA Healthy'),
                        ),
                      ],
                      onChanged: onSlaChanged,
                    ),

                    if (selectedPriority != null ||
                        selectedStatus != null ||
                        selectedSla != null ||
                        searchQuery.isNotEmpty) ...[
                      CivicFixSpacing.hSpaceMd,
                      TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text('Reset'),
                        onPressed: onResetFilters,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        CivicFixSpacing.vSpaceLg,

        // Jobs List
        if (jobs.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.xxl),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  size: 48,
                  color: Color(0xFF10B981),
                ),
                CivicFixSpacing.vSpaceMd,
                Text(
                  'No assigned jobs in this queue',
                  style: CivicFixTypography.h3.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                Text(
                  'You are all caught up! New complaints assigned by your Ward Department Lead will appear here.',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          ...jobs.map(
            (job) => CrewJobCard(
              key: ValueKey(job.id),
              job: job,
              onViewDetails: () => onViewDetails(job),
              onStartJob: onStartJob != null ? () => onStartJob!(job) : null,
            ),
          ),
        ],
      ],
    );
  }
}
