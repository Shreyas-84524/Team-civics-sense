import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/hazard_model.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../common/government_section_header.dart';
import '../../map/govt_hazard_info_card.dart';
import '../../map/govt_map_canvas.dart';
import '../../map/govt_map_legend.dart';

/// Embedded citywide GIS complaint and hazard map for spatial monitoring.
class CityComplaintMapSection extends StatefulWidget {
  final List<HazardModel> hazards;
  final bool isLoading;
  final ValueChanged<String>? onViewComplaint;

  const CityComplaintMapSection({
    super.key,
    required this.hazards,
    this.isLoading = false,
    this.onViewComplaint,
  });

  @override
  State<CityComplaintMapSection> createState() => _CityComplaintMapSectionState();
}

class _CityComplaintMapSectionState extends State<CityComplaintMapSection> {
  final TransformationController _transformationController = TransformationController();
  HazardModel? _selectedHazard;
  bool _showLegend = false;
  bool _showHeatmap = true;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GovernmentSectionHeader(
            title: 'Citywide Complaint & Hazard Map',
            subtitle: 'Spatial distribution of active civic hazards, infrastructure issues, and high-density zones',
            count: widget.hazards.length,
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _showHeatmap ? Icons.layers_rounded : Icons.layers_clear_rounded,
                    color: _showHeatmap ? GovtThemeTokens.primary : GovtThemeTokens.textMuted,
                    size: 20,
                  ),
                  tooltip: _showHeatmap ? 'Disable Density Heatmap' : 'Enable Density Heatmap',
                  onPressed: () {
                    setState(() => _showHeatmap = !_showHeatmap);
                  },
                ),
                IconButton(
                  icon: Icon(
                    _showLegend ? Icons.info_rounded : Icons.info_outline_rounded,
                    color: _showLegend ? GovtThemeTokens.primary : GovtThemeTokens.textMuted,
                    size: 20,
                  ),
                  tooltip: 'Toggle GIS Legend',
                  onPressed: () {
                    setState(() => _showLegend = !_showLegend);
                  },
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceSm,

          // Map Canvas Container
          SizedBox(
            height: 380,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  GovtMapCanvas(
                    hazards: widget.hazards,
                    selectedHazard: _selectedHazard,
                    transformationController: _transformationController,
                    showHeatmap: _showHeatmap,
                    onHazardSelected: (h) {
                      setState(() => _selectedHazard = h);
                    },
                    onMapTap: () {
                      if (_selectedHazard != null) {
                        setState(() => _selectedHazard = null);
                      }
                    },
                  ),

                  // Selected Hazard Detail Card Popup
                  if (_selectedHazard != null)
                    Positioned(
                      top: CivicFixSpacing.md,
                      right: CivicFixSpacing.md,
                      left: CivicFixSpacing.md,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: GovtHazardInfoCard(
                            hazard: _selectedHazard!,
                            onClose: () => setState(() => _selectedHazard = null),
                          ),
                        ),
                      ),
                    ),

                  // Map Legend Overlay
                  if (_showLegend)
                    Positioned(
                      bottom: CivicFixSpacing.md,
                      left: CivicFixSpacing.md,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: GovtMapLegend(
                          onClose: () => setState(() => _showLegend = false),
                        ),
                      ),
                    ),

                  // Privacy indicator banner at bottom right
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'BMC Spatial GIS · Privacy Protected',
                        style: GovtTypography.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
