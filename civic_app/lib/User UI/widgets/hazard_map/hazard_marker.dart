import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/hazard_model.dart';

/// Interactive map pin marker representing a geotagged civic hazard.
class HazardMarker extends StatelessWidget {
  final HazardModel hazard;
  final bool isSelected;
  final VoidCallback onTap;

  const HazardMarker({
    super.key,
    required this.hazard,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 46.0 : 38.0;
    final iconSize = isSelected ? 22.0 : 18.0;

    return Semantics(
      label: 'Hazard: ${hazard.title}, Category: ${hazard.category.name}, Status: ${hazard.statusLabel}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size + 8,
          height: size + 8,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Halo for Selected State
              if (isSelected)
                Container(
                  width: size + 8,
                  height: size + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hazard.statusColor.withValues(alpha: 0.25),
                  ),
                ),

              // Pin Base
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? hazard.statusColor : CivicFixColors.border,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.25 : 0.12),
                      blurRadius: isSelected ? 8 : 4,
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
            ],
          ),
        ),
      ),
    );
  }
}
