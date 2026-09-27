import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Skeleton loader card for Government KPI cards during asynchronous fetches.
class GovtKpiSkeleton extends StatelessWidget {
  const GovtKpiSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const shimmerColor = GovtThemeTokens.surfaceMuted;

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 90,
                height: 12,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Container(
            width: 70,
            height: 24,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          Container(
            width: 110,
            height: 10,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for table loading states.
class GovtTableSkeleton extends StatelessWidget {
  final int rowCount;
  final int columnCount;

  const GovtTableSkeleton({
    super.key,
    this.rowCount = 5,
    this.columnCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        children: [
          // Table header skeleton
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.lg),
            color: GovtThemeTokens.surfaceMuted,
            child: Row(
              children: List.generate(
                columnCount,
                (index) => Expanded(
                  child: Container(
                    height: 12,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D7D2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Skeleton rows
          ...List.generate(
            rowCount,
            (rIndex) => Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: GovtThemeTokens.borderLight, width: 1),
                ),
              ),
              child: Row(
                children: List.generate(
                  columnCount,
                  (cIndex) => Expanded(
                    child: Container(
                      height: 10,
                      margin: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clean full-page or partial-page loader.
class GovtPageLoader extends StatelessWidget {
  final String? message;

  const GovtPageLoader({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CivicFixSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(GovtThemeTokens.primary),
              ),
            ),
            if (message != null) ...[
              CivicFixSpacing.vSpaceMd,
              Text(
                message!,
                style: GovtTypography.bodySmall.copyWith(
                  color: GovtThemeTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Minimal inline loader for cards or table action buttons.
class GovtInlineLoader extends StatelessWidget {
  final double size;
  final Color color;

  const GovtInlineLoader({
    super.key,
    this.size = 16.0,
    this.color = GovtThemeTokens.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Button-integrated loading spinner.
class GovtButtonLoader extends StatelessWidget {
  final Color color;
  final double size;

  const GovtButtonLoader({
    super.key,
    this.color = Colors.white,
    this.size = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
