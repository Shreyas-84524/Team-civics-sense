import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../theme/govt_theme_tokens.dart';

/// Categorized Evidence Item Model for structured gallery display.
class GovernmentEvidenceItem {
  final String imageUrl;
  final String title;
  final String stage; // 'citizen', 'before', 'during', 'after', 'resolution'
  final DateTime? timestamp;
  final String? uploader;

  const GovernmentEvidenceItem({
    required this.imageUrl,
    required this.title,
    required this.stage,
    this.timestamp,
    this.uploader,
  });
}

/// Standardized, reusable Evidence Gallery supporting full-screen zoom and stage classification.
class GovernmentEvidenceGallery extends StatelessWidget {
  final List<GovernmentEvidenceItem> evidenceItems;
  final String? title;

  const GovernmentEvidenceGallery({
    super.key,
    required this.evidenceItems,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (evidenceItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GovtThemeTokens.borderLight),
        ),
        alignment: Alignment.center,
        child: Text(
          'No photographic evidence uploaded for this grievance.',
          style: CivicFixTypography.caption.copyWith(
            color: GovtThemeTokens.textMuted,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: CivicFixTypography.captionMedium.copyWith(
              color: GovtThemeTokens.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
        ],
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: evidenceItems.length,
            separatorBuilder: (context, index) => CivicFixSpacing.hSpaceMd,
            itemBuilder: (context, index) {
              final item = evidenceItems[index];
              return _buildEvidenceThumbnail(context, item, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceThumbnail(
    BuildContext context,
    GovernmentEvidenceItem item,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _openFullscreenViewer(context, index),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: GovtThemeTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GovtThemeTokens.borderLight),
          boxShadow: GovtThemeTokens.cardShadow,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_not_supported_outlined,
                          size: 24, color: GovtThemeTokens.textMuted),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'Preview Unavailable',
                        style: CivicFixTypography.caption.copyWith(
                          fontSize: 9,
                          color: GovtThemeTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Text(
                  item.title,
                  style: CivicFixTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Stage Pill
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStageColor(item.stage).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.stage.toUpperCase(),
                  style: CivicFixTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'before':
        return const Color(0xFFD97706);
      case 'during':
        return const Color(0xFF3B82F6);
      case 'after':
      case 'resolution':
        return const Color(0xFF10B981);
      case 'citizen':
      default:
        return GovtThemeTokens.primary;
    }
  }

  void _openFullscreenViewer(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) => _FullscreenEvidenceDialog(
        evidenceItems: evidenceItems,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _FullscreenEvidenceDialog extends StatefulWidget {
  final List<GovernmentEvidenceItem> evidenceItems;
  final int initialIndex;

  const _FullscreenEvidenceDialog({
    required this.evidenceItems,
    required this.initialIndex,
  });

  @override
  State<_FullscreenEvidenceDialog> createState() =>
      _FullscreenEvidenceDialogState();
}

class _FullscreenEvidenceDialogState extends State<_FullscreenEvidenceDialog> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.evidenceItems[_currentIndex];

    return Dialog(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Carousel View
          PageView.builder(
            controller: _pageController,
            itemCount: widget.evidenceItems.length,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemBuilder: (ctx, idx) {
              final item = widget.evidenceItems[idx];
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Center(
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image_outlined,
                            size: 64, color: Colors.white54),
                        CivicFixSpacing.vSpaceSm,
                        Text(
                          'Unable to load high-resolution image.',
                          style: CivicFixTypography.bodySmall
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Header: Counter & Close
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.evidenceItems.length} · ${currentItem.stage.toUpperCase()}',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Footer: Title & Metadata
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(CivicFixSpacing.md),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentItem.title,
                    style: CivicFixTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (currentItem.timestamp != null ||
                      currentItem.uploader != null) ...[
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      '${currentItem.uploader != null ? "Uploaded by ${currentItem.uploader} · " : ""}${currentItem.timestamp != null ? "${currentItem.timestamp!.day}/${currentItem.timestamp!.month} ${currentItem.timestamp!.hour}:${currentItem.timestamp!.minute.toString().padLeft(2, '0')}" : ""}',
                      style: CivicFixTypography.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
