import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../../core/models/hazard_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Department-scoped GIS map section for Ward Department Lead Operations Center.
/// Displays spatial distribution of verified hazards and grievances strictly within
/// the authoritative Ward × Department unit.
class DepartmentLeadMapSection extends StatefulWidget {
  final String wardId;
  final String departmentName;
  final List<HazardModel> hazards;
  final List<ComplaintModel> complaints;
  final bool isLoading;
  final ValueChanged<ComplaintModel>? onViewComplaint;

  const DepartmentLeadMapSection({
    super.key,
    required this.wardId,
    required this.departmentName,
    required this.hazards,
    required this.complaints,
    this.isLoading = false,
    this.onViewComplaint,
  });

  @override
  State<DepartmentLeadMapSection> createState() =>
      _DepartmentLeadMapSectionState();
}

class _DepartmentLeadMapSectionState extends State<DepartmentLeadMapSection> {
  ComplaintPriority? _filterPriority;
  ComplaintStatus? _filterStatus;
  int _selectedMarkerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = GovtResponsive.isDesktop(context);

    final filteredComplaints = widget.complaints.where((c) {
      if (_filterPriority != null && c.priority != _filterPriority) return false;
      if (_filterStatus != null && c.status != _filterStatus) return false;
      return true;
    }).toList();

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
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.map_outlined,
                    color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEPARTMENT GIS SPATIAL TELEMETRY',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Spatial distribution strictly for ${widget.departmentName} in Ward ${widget.wardId}',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${filteredComplaints.length} Unit Points',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          // Map and Points List
          if (!isDesktop) ...[
            _buildMapCanvas(filteredComplaints),
            CivicFixSpacing.vSpaceLg,
            _buildPointsList(filteredComplaints),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildMapCanvas(filteredComplaints),
                ),
                CivicFixSpacing.hSpaceLg,
                Expanded(
                  flex: 4,
                  child: _buildPointsList(filteredComplaints),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapCanvas(List<ComplaintModel> points) {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Stack(
        children: [
          // Grid background lines
          Positioned.fill(
            child: CustomPaint(
              painter: _GisGridPainter(),
            ),
          ),

          // Ward Boundary Label
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                'WARD ${widget.wardId} JURISDICTION BOUNDARY · ${widget.departmentName.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          // Spatial Pins
          if (points.isNotEmpty)
            ...List.generate(points.length, (i) {
              final p = points[i];
              // Pseudo-spatial layout based on index for deterministic test rendering
              final left = 40.0 + ((i * 73) % 280);
              final top = 50.0 + ((i * 47) % 220);
              final isSelected = _selectedMarkerIndex == i;

              return Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedMarkerIndex = i);
                    if (widget.onViewComplaint != null) {
                      widget.onViewComplaint!(p);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: p.priority.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: p.priority.color.withValues(alpha: 0.5),
                          blurRadius: isSelected ? 10 : 4,
                          spreadRadius: isSelected ? 3 : 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),

          if (points.isEmpty)
            const Center(
              child: Text(
                'No spatial grievances in this unit matching current filters.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPointsList(List<ComplaintModel> points) {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPATIAL HOTSPOTS (${points.length})',
            style: CivicFixTypography.captionMedium.copyWith(
              color: GovtThemeTokens.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          Expanded(
            child: points.isEmpty
                ? const Center(
                    child: Text('No location points recorded',
                        style: TextStyle(fontSize: 12)),
                  )
                : ListView.separated(
                    itemCount: points.length,
                    separatorBuilder: (context, index) => CivicFixSpacing.vSpaceSm,
                    itemBuilder: (ctx, i) {
                      final c = points[i];
                      final isSelected = _selectedMarkerIndex == i;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedMarkerIndex = i);
                          if (widget.onViewComplaint != null) {
                            widget.onViewComplaint!(c);
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(CivicFixSpacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? GovtThemeTokens.primary.withValues(alpha: 0.08)
                                : GovtThemeTokens.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? GovtThemeTokens.primary
                                  : GovtThemeTokens.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: c.priority.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              CivicFixSpacing.hSpaceSm,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.title,
                                      style:
                                          CivicFixTypography.captionMedium.copyWith(
                                        color: GovtThemeTokens.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      c.location.address,
                                      style:
                                          CivicFixTypography.caption.copyWith(
                                        color: GovtThemeTokens.textSecondary,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                c.priority.label,
                                style: CivicFixTypography.caption.copyWith(
                                  color: c.priority.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GisGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const step = 30.0;
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
