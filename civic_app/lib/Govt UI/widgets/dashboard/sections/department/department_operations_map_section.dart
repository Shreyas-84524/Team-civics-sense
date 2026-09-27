import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/hazard_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Department GIS Map & Spatial Hazard Distribution Section for Central Department HOD.
/// Shows citywide spatial hazard telemetry across all 24 wards strictly scoped to this department.
class DepartmentOperationsMapSection extends StatelessWidget {
  final String departmentName;
  final List<HazardModel> hazards;
  final bool isLoading;
  final ValueChanged<String>? onViewComplaint;

  const DepartmentOperationsMapSection({
    super.key,
    required this.departmentName,
    required this.hazards,
    this.isLoading = false,
    this.onViewComplaint,
  });

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
                      'DEPARTMENT SPATIAL HAZARDS & GIS OVERVIEW',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Citywide spatial telemetry and verified hazard hotspots for $departmentName across 24 Wards',
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
                  color: GovtThemeTokens.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${hazards.length} Department Hazards',
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
          CivicFixSpacing.vSpaceLg,

          if (!GovtResponsive.isDesktop(context)) ...[
            _buildMapCanvas(context),
            CivicFixSpacing.vSpaceLg,
            _buildHazardList(context),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildMapCanvas(context),
                ),
                CivicFixSpacing.hSpaceLg,
                Expanded(
                  flex: 4,
                  child: _buildHazardList(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapCanvas(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Stack(
        children: [
          // Grid overlay pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(
                painter: _DepartmentMapGridPainter(),
              ),
            ),
          ),
          // Center title & telemetry status
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.satellite_alt_outlined,
                    size: 36, color: Color(0xFF94A3B8)),
                CivicFixSpacing.vSpaceSm,
                Text(
                  'CITYWIDE DEPARTMENT GIS TELEMETRY',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: const Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Greater Mumbai Ward Boundary GIS Grid • $departmentName',
                  style: CivicFixTypography.caption.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Map Control Badges
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: GovtThemeTokens.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  CivicFixSpacing.hSpaceXs,
                  Text(
                    'GIS LIVE FEED',
                    style: CivicFixTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '24 Wards Active',
                style: CivicFixTypography.caption.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardList(BuildContext context) {
    if (hazards.isEmpty) {
      return Container(
        height: 320,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GovtThemeTokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 36, color: GovtThemeTokens.success),
            CivicFixSpacing.vSpaceSm,
            Text(
              'No Verified Hazards',
              style: CivicFixTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textPrimary,
              ),
            ),
            Text(
              'No high-risk spatial hazard hotspots currently active.',
              textAlign: TextAlign.center,
              style: CivicFixTypography.captionMedium.copyWith(
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'ACTIVE HAZARD SPOTS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${hazards.length} Total',
                style: CivicFixTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: GovtThemeTokens.primaryDark,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Expanded(
            child: ListView.separated(
              itemCount: hazards.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceXs,
              itemBuilder: (context, index) {
                final h = hazards[index];
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: GovtThemeTokens.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: GovtThemeTokens.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            size: 16, color: GovtThemeTokens.error),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.title,
                              style: CivicFixTypography.captionMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: GovtThemeTokens.textPrimary,
                              ),
                            ),
                            Text(
                              h.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CivicFixTypography.caption.copyWith(
                                color: GovtThemeTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _DepartmentMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 0.5;

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
