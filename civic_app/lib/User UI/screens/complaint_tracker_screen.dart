import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/complaint_model.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';
import '../widgets/complaint_details/complaint_tracker.dart';
import '../widgets/complaint_details/status_history_timeline.dart';

/// Screen showing focused 5-stage grievance resolution tracker and SLA details.
class ComplaintTrackerScreen extends StatelessWidget {
  final ComplaintModel complaint;
  final ComplaintRepository? repository;

  const ComplaintTrackerScreen({
    super.key,
    required this.complaint,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? RepositoryLocator.complaintRepository;

    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: const CivicFixAppBar(
        title: 'Status Tracker',
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: CivicFixSpacing.pagePadding,
          child: StreamBuilder<ComplaintModel?>(
            stream: repo.watchComplaint(complaint.id),
            initialData: complaint,
            builder: (context, snapshot) {
              final activeComplaint = snapshot.data ?? complaint;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket Header Card
                    CivicFixCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ticket Reference', style: CivicFixTypography.caption),
                              CivicFixSpacing.vSpaceXs,
                              Text(
                                activeComplaint.ticketNumber,
                                style: CivicFixTypography.h3.copyWith(color: CivicFixColors.primary),
                              ),
                            ],
                          ),
                          StatusBadge(status: activeComplaint.status),
                        ],
                      ),
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // 5-Stage Complaint Progress Tracker
                    ComplaintTracker(
                      currentStatus: activeComplaint.status,
                      customStatusMessage: activeComplaint.officerNotes,
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // Status Updates Timeline
                    StatusHistoryTimeline(timeline: activeComplaint.timeline),
                    CivicFixSpacing.vSpaceXxl,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

