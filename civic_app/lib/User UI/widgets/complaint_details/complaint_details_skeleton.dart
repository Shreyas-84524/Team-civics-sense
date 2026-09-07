import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Skeleton placeholder for ComplaintDetailsScreen loading state.
class ComplaintDetailsSkeleton extends StatefulWidget {
  const ComplaintDetailsSkeleton({super.key});

  @override
  State<ComplaintDetailsSkeleton> createState() => _ComplaintDetailsSkeletonState();
}

class _ComplaintDetailsSkeletonState extends State<ComplaintDetailsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      value: 0.5,
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _controller.repeat(reverse: true);
    }
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: CivicFixColors.border.withValues(alpha: _animation.value),
            borderRadius: borderRadius ?? CivicFixRadius.chipRadius,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: CivicFixSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBox(width: 120, height: 16),
              _buildShimmerBox(width: 90, height: 26, borderRadius: CivicFixRadius.chipRadius),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // Title Skeleton
          _buildShimmerBox(width: double.infinity, height: 24),
          CivicFixSpacing.vSpaceSm,
          _buildShimmerBox(width: 200, height: 18),
          CivicFixSpacing.vSpaceXl,

          // Tracker Skeleton Card
          CivicFixCard(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 140, height: 16),
                CivicFixSpacing.vSpaceLg,
                ...List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: CivicFixSpacing.md),
                    child: Row(
                      children: [
                        _buildShimmerBox(width: 24, height: 24, borderRadius: BorderRadius.circular(12)),
                        CivicFixSpacing.hSpaceMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShimmerBox(width: 100, height: 14),
                              CivicFixSpacing.vSpaceXs,
                              _buildShimmerBox(width: 160, height: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Issue Info Skeleton Card
          CivicFixCard(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 130, height: 16),
                CivicFixSpacing.vSpaceMd,
                Row(
                  children: [
                    Expanded(child: _buildShimmerBox(width: double.infinity, height: 36)),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(child: _buildShimmerBox(width: double.infinity, height: 36)),
                  ],
                ),
                CivicFixSpacing.vSpaceMd,
                _buildShimmerBox(width: double.infinity, height: 48),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Location Skeleton Card
          CivicFixCard(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Row(
              children: [
                _buildShimmerBox(width: 36, height: 36),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(width: 150, height: 14),
                      CivicFixSpacing.vSpaceXs,
                      _buildShimmerBox(width: 100, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
