import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/hazard_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Zonal Operations GIS Map & Hazard Distribution for Zonal DMC Command Center.
class ZoneOperationsMapSection extends StatelessWidget {
  final String zoneDisplayName;
  final List<HazardModel> hazards;
  final bool isLoading;
  final ValueChanged<String>? onViewComplaint;

  const ZoneOperationsMapSection({
    super.key,
    required this.zoneDisplayName,
    required this.hazards,
    this.isLoading = false,
    this.onViewComplaint,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

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
                child: const Icon(Icons.map_outlined, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONAL SPATIAL HAZARDS & GIS OVERVIEW',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Spatial telemetry and verified hazard coordinates within $zoneDisplayName',
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
                  border: Border.all(color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${hazards.length} Mapped Hazards',
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

          // Map Canvas Placeholder & Telemetry List
          if (isMobile) ...[
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Stack(
        children: [
          // Grid lines background
          Positioned.fill(
            child: CustomPaint(
              painter: _ZonalMapGridPainter(),
            ),
          ),

          // Center Label & Zone Focus Indicator
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: GovtThemeTokens.primary, width: 2),
                  ),
                  child: const Icon(Icons.location_searching_rounded, color: Colors.white, size: 28),
                ),
                CivicFixSpacing.vSpaceSm,
                Text(
                  '$zoneDisplayName GIS Spatial Sector',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${hazards.length} Active spatial pins rendered',
                  style: CivicFixTypography.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Map Overlay Controls
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'LIVE GIS TELEMETRY ACTIVE',
                style: CivicFixTypography.caption.copyWith(
                  color: GovtThemeTokens.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardList(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE HAZARDS IN ZONE',
            style: CivicFixTypography.captionMedium.copyWith(
              color: GovtThemeTokens.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          Expanded(
            child: hazards.isEmpty
                ? Center(
                    child: Text(
                      'No active hazards logged in this zone.',
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: hazards.length,
                    separatorBuilder: (context, index) => const Divider(color: GovtThemeTokens.divider, height: 1),
                    itemBuilder: (context, index) {
                      final h = hazards[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: h.severity == HazardSeverity.critical
                                    ? GovtThemeTokens.error
                                    : GovtThemeTokens.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                            CivicFixSpacing.hSpaceSm,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CivicFixTypography.captionMedium.copyWith(
                                      color: GovtThemeTokens.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Ward ${h.ward ?? 'N/A'} · ${h.category.name}',
                                    style: CivicFixTypography.caption.copyWith(
                                      color: GovtThemeTokens.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (h.complaintId != null && onViewComplaint != null)
                              IconButton(
                                onPressed: () => onViewComplaint!(h.complaintId!),
                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                padding: EdgeInsets.zero,
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

class _ZonalMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
