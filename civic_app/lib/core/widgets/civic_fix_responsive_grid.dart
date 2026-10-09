import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Responsive grid layout for card arrays, dashboard modules, and KPI metrics.
///
/// Follows Design.md:
/// - Desktop (>= 1280px): 3 or 4 columns (or custom [desktopColumns])
/// - Tablet (768px - 1279px): 2 or 3 columns (or custom [tabletColumns])
/// - Mobile (< 768px): 1 column (or custom [mobileColumns])
/// - Standard 16px / 24px gutters
class CivicFixResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double? itemAspectRatio;
  final double? crossAxisExtent;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const CivicFixResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = CivicFixSpacing.spaceMd,
    this.runSpacing = CivicFixSpacing.spaceMd,
    this.itemAspectRatio,
    this.crossAxisExtent,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  /// 4-column desktop layout for small KPI stat cards.
  const CivicFixResponsiveGrid.stats({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 2,
    this.desktopColumns = 4,
    this.spacing = CivicFixSpacing.spaceMd,
    this.runSpacing = CivicFixSpacing.spaceMd,
    this.itemAspectRatio,
    this.crossAxisExtent,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  /// 2-column desktop layout for large feature comparison or dual module cards.
  const CivicFixResponsiveGrid.dual({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 2,
    this.spacing = CivicFixSpacing.gutter,
    this.runSpacing = CivicFixSpacing.gutter,
    this.itemAspectRatio,
    this.crossAxisExtent,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns;
        if (width >= CivicFixBreakpoints.desktop) {
          columns = desktopColumns;
        } else if (width >= CivicFixBreakpoints.mobile) {
          columns = tabletColumns;
        } else {
          columns = mobileColumns;
        }

        if (columns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: runSpacing),
                children[i],
              ],
            ],
          );
        }

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: itemAspectRatio ?? 1.2,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
