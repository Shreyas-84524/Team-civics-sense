import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../services/government_crew_work_service.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_sla_badge.dart';

/// Crew-scoped GIS Field Map showing assigned job pins.
class CrewMapSection extends StatefulWidget {
  final List<CrewJobItem> jobs;
  final void Function(CrewJobItem job) onViewDetails;

  const CrewMapSection({
    super.key,
    required this.jobs,
    required this.onViewDetails,
  });

  @override
  State<CrewMapSection> createState() => _CrewMapSectionState();
}

class _CrewMapSectionState extends State<CrewMapSection> {
  CrewJobItem? _selectedJob;

  @override
  void initState() {
    super.initState();
    if (widget.jobs.isNotEmpty) {
      _selectedJob = widget.jobs.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.map_outlined,
                color: Color(0xFF0284C7),
                size: 20,
              ),
            ),
            CivicFixSpacing.hSpaceSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY JOBS MAP',
                    style: CivicFixTypography.h3.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Field GPS spatial pins strictly scoped to your assigned complaints (${widget.jobs.length})',
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

        // Map Container
        Container(
          height: 380,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: GovtThemeTokens.cardRadius,
            border: Border.all(color: GovtThemeTokens.border),
          ),
          child: Stack(
            children: [
              // Map Grid Pattern Background
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapGridPainter(),
                ),
              ),

              // Interactive Job Pins
              ...widget.jobs.asMap().entries.map((entry) {
                final idx = entry.key;
                final job = entry.value;
                final isSelected = _selectedJob?.id == job.id;

                // Deterministic pin positions based on index
                final double top = 40.0 + ((idx * 67 + 23) % 260);
                final double left = 30.0 + ((idx * 113 + 47) % 520);

                Color pinColor = const Color(0xFF3B82F6);
                if (job.priority == ComplaintPriority.emergency) {
                  pinColor = const Color(0xFFEF4444);
                } else if (job.priority == ComplaintPriority.high) {
                  pinColor = const Color(0xFFF59E0B);
                } else if (job.isReturnedForRework) {
                  pinColor = const Color(0xFFDC2626);
                }

                return Positioned(
                  top: top,
                  left: left,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedJob = job),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: pinColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white70,
                          width: isSelected ? 3.0 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: pinColor.withValues(alpha: 0.5),
                            blurRadius: isSelected ? 12 : 6,
                            spreadRadius: isSelected ? 3 : 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        job.priority == ComplaintPriority.emergency
                            ? Icons.warning_amber_rounded
                            : Icons.engineering_rounded,
                        size: isSelected ? 20 : 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }),

              // Map Control Overlay
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gps_fixed_rounded, size: 14, color: Colors.white),
                      CivicFixSpacing.hSpaceXs,
                      Text(
                        'Ward Unit Field Telemetry',
                        style: CivicFixTypography.caption.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        CivicFixSpacing.vSpaceMd,

        // Selected Pin Job Summary Box
        if (_selectedJob != null) ...[
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
              boxShadow: GovtThemeTokens.cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'TICKET #${_selectedJob!.ticketNumber}',
                            style: CivicFixTypography.captionMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: GovtThemeTokens.primaryDark,
                            ),
                          ),
                          CivicFixSpacing.hSpaceSm,
                          GovtPriorityBadge.fromPriority(
                            _selectedJob!.priority,
                            isCompact: true,
                          ),
                          CivicFixSpacing.hSpaceSm,
                          GovtSlaBadge.fromDuration(
                            createdAt: _selectedJob!.complaint.slaStartedAt,
                            resolvedAt: _selectedJob!.complaint.resolvedAt,
                            isCompact: true,
                          ),
                        ],
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        _selectedJob!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        _selectedJob!.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => widget.onViewDetails(_selectedJob!),
                  child: const Text('View Job'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
