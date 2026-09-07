import 'package:flutter/material.dart';
import '../../../core/models/hazard_model.dart';
import '../../theme/govt_theme_tokens.dart';

/// Government GIS Map Marker representing a geotagged civic hazard or grievance on the map.
class GovtHazardMarker extends StatelessWidget {
  final HazardModel hazard;
  final bool isSelected;
  final VoidCallback onTap;

  const GovtHazardMarker({
    super.key,
    required this.hazard,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 48.0 : 38.0;
    final iconSize = isSelected ? 22.0 : 18.0;

    return Semantics(
      label: 'Hazard: ${hazard.title}, Category: ${hazard.category.name}, Status: ${hazard.statusLabel}, Severity: ${hazard.severity.label}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size + 10,
          height: size + 10,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Halo for Selected State
              if (isSelected)
                Container(
                  width: size + 10,
                  height: size + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hazard.statusColor.withValues(alpha: 0.28),
                  ),
                ),

              // Severity Ring Base
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? GovtThemeTokens.primary : hazard.statusColor,
                    width: isSelected ? 3.0 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.3 : 0.15),
                      blurRadius: isSelected ? 10 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: size - 8,
                    height: size - 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hazard.statusColor.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      hazard.categoryIcon,
                      size: iconSize,
                      color: hazard.statusColor,
                    ),
                  ),
                ),
              ),

              // Status Indicator Dot (Top Right)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: hazard.statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),

              // Severity Tag (Bottom)
              if (hazard.severity == HazardSeverity.critical || hazard.severity == HazardSeverity.high)
                Positioned(
                  bottom: -1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: hazard.severity.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hazard.severity == HazardSeverity.critical ? 'P1' : 'P2',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
