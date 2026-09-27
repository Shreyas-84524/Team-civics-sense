import 'package:flutter/material.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Single node item inside [GovtBreadcrumbs].
class GovtBreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  final String? route;

  const GovtBreadcrumbItem({
    required this.label,
    this.onTap,
    this.route,
  });
}

/// Responsive, overflow-safe breadcrumb trail for municipal administrative hierarchies.
class GovtBreadcrumbs extends StatelessWidget {
  final List<GovtBreadcrumbItem> items;
  final TextStyle? style;
  final TextStyle? activeStyle;
  final double separatorSpacing;

  const GovtBreadcrumbs({
    super.key,
    required this.items,
    this.style,
    this.activeStyle,
    this.separatorSpacing = 4.0,
  });

  /// Convenient factory to create breadcrumbs from simple string hierarchy.
  factory GovtBreadcrumbs.fromStrings(
    List<String> labels, {
    void Function(int index)? onSelect,
  }) {
    return GovtBreadcrumbs(
      items: labels.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isLast = index == labels.length - 1;
        return GovtBreadcrumbItem(
          label: label,
          onTap: isLast || onSelect == null ? null : () => onSelect(index),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final defaultStyle = style ??
        GovtTypography.caption.copyWith(
          color: GovtThemeTokens.textSecondary,
          fontSize: 12,
        );

    final currentStyle = activeStyle ??
        GovtTypography.caption.copyWith(
          color: GovtThemeTokens.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0) ...[
                SizedBox(width: separatorSpacing),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: GovtThemeTokens.textMuted,
                ),
                SizedBox(width: separatorSpacing),
              ],
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Text(
                    item.label,
                    style: isLast ? currentStyle : defaultStyle,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
