import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/location/location_model.dart';
import '../../../core/models/evidence_model.dart';
import '../../../core/widgets/civic_fix_card.dart';
import '../../services/evidence_service.dart';

/// Evidence photo picker widget for Step 2 of Report Issue.
///
/// Supports camera capture, gallery selection, interactive full preview dialogs,
/// 3-photo maximum limit, accessible remove/replace flows, permission banners,
/// and non-destructive error recovery.
class EvidencePicker extends StatefulWidget {
  final List<String> images;
  final ValueChanged<List<String>> onImagesChanged;
  final ValueChanged<List<EvidenceItem>>? onEvidenceItemsChanged;
  final List<EvidenceItem>? evidenceItems;
  final EvidenceService? evidenceService;
  final int maxImages;

  const EvidencePicker({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.onEvidenceItemsChanged,
    this.evidenceItems,
    this.evidenceService,
    this.maxImages = 3,
  });

  @override
  State<EvidencePicker> createState() => _EvidencePickerState();
}

class _EvidencePickerState extends State<EvidencePicker> {
  late final EvidenceService _service;
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastFailedAction;
  CivicPermissionStatus? _permissionIssue;
  EvidenceSource? _lastFailedSource;

  @override
  void initState() {
    super.initState();
    _service = widget.evidenceService ?? MockEvidenceService();
  }

  int get _count => widget.evidenceItems?.length ?? widget.images.length;
  bool get _canAddMore => _count < widget.maxImages && !_isLoading;

  Future<void> _handleCapture(EvidenceSource source) async {
    if (_count >= widget.maxImages) {
      _showMaxLimitSnackBar();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _permissionIssue = null;
      _lastFailedAction = null;
      _lastFailedSource = null;
    });

    try {
      final EvidenceItem? item = source == EvidenceSource.camera
          ? await _service.captureFromCamera()
          : await _service.pickFromGallery();

      if (!mounted) return;

      // User cancelled picker gracefully
      if (item == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Add item to draft lists
      final updatedStrings = List<String>.from(widget.images)..add(item.filePath);
      List<EvidenceItem>? updatedEvidence;
      if (widget.evidenceItems != null) {
        updatedEvidence = List<EvidenceItem>.from(widget.evidenceItems!)..add(item);
      } else {
        updatedEvidence = updatedStrings.map((path) {
          return EvidenceItem(
            id: 'evidence_${path.hashCode}',
            filePath: path,
            fileName: path.split('/').last,
            source: source,
            capturedAt: DateTime.now(),
          );
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });

      widget.onImagesChanged(updatedStrings);
      widget.onEvidenceItemsChanged?.call(updatedEvidence);
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString().toLowerCase();
      setState(() {
        _isLoading = false;
        if (errorStr.contains('permission')) {
          _permissionIssue = CivicPermissionStatus.denied;
          _lastFailedSource = source;
          _errorMessage = '${source.label} permission was denied. Please grant permission to add photos.';
        } else {
          _errorMessage = "Couldn't add the photo. Please try again.";
          _lastFailedAction = source == EvidenceSource.camera ? 'camera' : 'gallery';
        }
      });
    }
  }

  Future<void> _handleReplace(int index) async {
    // Show quick bottom sheet to pick replacement source
    final source = await showModalBottomSheet<EvidenceSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.lg,
            vertical: CivicFixSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Replace Photo ${index + 1}',
                style: CivicFixTypography.h3,
              ),
              CivicFixSpacing.vSpaceSm,
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: CivicFixColors.primary),
                title: const Text('Take a new photo'),
                onTap: () => Navigator.pop(ctx, EvidenceSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: CivicFixColors.secondary),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, EvidenceSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final EvidenceItem? item = source == EvidenceSource.camera
          ? await _service.captureFromCamera()
          : await _service.pickFromGallery();

      if (!mounted) return;

      if (item == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final updatedStrings = List<String>.from(widget.images);
      if (index < updatedStrings.length) {
        updatedStrings[index] = item.filePath;
      }

      List<EvidenceItem>? updatedEvidence;
      if (widget.evidenceItems != null) {
        updatedEvidence = List<EvidenceItem>.from(widget.evidenceItems!);
        if (index < updatedEvidence.length) {
          updatedEvidence[index] = item;
        }
      }

      setState(() {
        _isLoading = false;
      });

      widget.onImagesChanged(updatedStrings);
      if (updatedEvidence != null) {
        widget.onEvidenceItemsChanged?.call(updatedEvidence);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't replace photo. Please try again.";
      });
    }
  }

  void _removeImage(int index) {
    final updatedStrings = List<String>.from(widget.images);
    if (index < updatedStrings.length) {
      updatedStrings.removeAt(index);
    }

    List<EvidenceItem>? updatedEvidence;
    if (widget.evidenceItems != null) {
      updatedEvidence = List<EvidenceItem>.from(widget.evidenceItems!);
      if (index < updatedEvidence.length) {
        updatedEvidence.removeAt(index);
      }
    }

    setState(() {
      _errorMessage = null;
      _permissionIssue = null;
    });

    widget.onImagesChanged(updatedStrings);
    if (updatedEvidence != null) {
      widget.onEvidenceItemsChanged?.call(updatedEvidence);
    }
  }

  void _retryLastAction() {
    if (_lastFailedSource != null) {
      _handleCapture(_lastFailedSource!);
    } else if (_lastFailedAction == 'camera') {
      _handleCapture(EvidenceSource.camera);
    } else {
      _handleCapture(EvidenceSource.gallery);
    }
  }

  void _showMaxLimitSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maximum of ${widget.maxImages} photos reached.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openPhotoPreview(int index, String photoPath, EvidenceItem? item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: CivicFixRadius.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Photo Preview (${index + 1} of $_count)',
                    style: CivicFixTypography.h3,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close Preview',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceMd,
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: CivicFixColors.surfaceMuted,
                  borderRadius: CivicFixRadius.cardRadius,
                  border: Border.all(color: CivicFixColors.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item?.source == EvidenceSource.camera
                              ? Icons.camera_alt_rounded
                              : Icons.image_rounded,
                          size: 56,
                          color: CivicFixColors.primary.withValues(alpha: 0.6),
                        ),
                        CivicFixSpacing.vSpaceSm,
                        Text(
                          item?.fileName ?? photoPath.split('/').last,
                          textAlign: TextAlign.center,
                          style: CivicFixTypography.bodySmallMedium,
                        ),
                        CivicFixSpacing.vSpaceXs,
                        Text(
                          item != null
                              ? 'Captured via ${item.source.label} • ${item.formattedTime}'
                              : 'Attached Photo',
                          style: CivicFixTypography.caption.copyWith(
                            color: CivicFixColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.vSpaceLg,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleReplace(index);
                      },
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Replace'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CivicFixColors.primary,
                        side: const BorderSide(color: CivicFixColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: CivicFixRadius.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                  CivicFixSpacing.hSpaceSm,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _removeImage(index);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CivicFixColors.error,
                        side: const BorderSide(color: CivicFixColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: CivicFixRadius.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header & Counter Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photo Evidence',
              style: CivicFixTypography.bodySmallMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: CivicFixColors.primaryText,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CivicFixSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _count >= widget.maxImages
                    ? CivicFixColors.secondary.withValues(alpha: 0.12)
                    : CivicFixColors.surfaceMuted,
                borderRadius: CivicFixRadius.chipRadius,
                border: Border.all(
                  color: _count >= widget.maxImages
                      ? CivicFixColors.secondary
                      : CivicFixColors.border,
                ),
              ),
              child: Text(
                _count >= widget.maxImages
                    ? '$_count/${widget.maxImages} photos (Max)'
                    : '$_count/${widget.maxImages} photos added',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: _count > 0
                      ? CivicFixColors.secondaryDark
                      : CivicFixColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceXs,
        Text(
          'A clear photo showing the issue helps ward officers resolve it faster. Photos are optional.',
          style: CivicFixTypography.caption.copyWith(
            color: CivicFixColors.secondaryText,
          ),
        ),
        CivicFixSpacing.vSpaceMd,

        // Permission Banner (if permission denied)
        if (_permissionIssue != null) ...[
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: CivicFixColors.statusUnderReviewBg,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(color: CivicFixColors.alert.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: CivicFixColors.alertDark,
                  size: 20,
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Text(
                    _errorMessage ?? 'Permission required to access media.',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: CivicFixColors.alertDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _retryLastAction,
                  child: const Text('Grant Access'),
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceMd,
        ],

        // Error Recovery Banner
        if (_errorMessage != null && _permissionIssue == null) ...[
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: CivicFixColors.statusRejectedBg,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(color: CivicFixColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: CivicFixColors.error,
                  size: 20,
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: CivicFixColors.error,
                    ),
                  ),
                ),
                if (_lastFailedAction != null || _lastFailedSource != null)
                  ElevatedButton(
                    onPressed: _retryLastAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CivicFixColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: CivicFixSpacing.md,
                        vertical: CivicFixSpacing.xs,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Try Again'),
                  ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceMd,
        ],

        // Add Photo Card
        if (_canAddMore)
          CivicFixCard(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: CivicFixColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: CivicFixColors.primary,
                    size: 26,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                Text(
                  'Add Photo Evidence',
                  style: CivicFixTypography.bodySmallMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  'Take a clear photo or select from gallery (${widget.maxImages - _count} remaining)',
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                  ),
                ),
                CivicFixSpacing.vSpaceMd,

                if (_isLoading)
                  const SizedBox(
                    height: 44,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Processing photo...', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleCapture(EvidenceSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Take Photo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CivicFixColors.primary,
                            side: const BorderSide(color: CivicFixColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: CivicFixRadius.buttonRadius,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.md),
                          ),
                        ),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleCapture(EvidenceSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CivicFixColors.secondary,
                            side: const BorderSide(color: CivicFixColors.secondary),
                            shape: RoundedRectangleBorder(
                              borderRadius: CivicFixRadius.buttonRadius,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.md),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          )
        else if (_count >= widget.maxImages)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: CivicFixColors.surfaceMuted,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(color: CivicFixColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: CivicFixColors.secondary,
                  size: 20,
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Text(
                    'Maximum limit of ${widget.maxImages} photos reached. You can replace or remove photos below.',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Attached Photos List
        if (_count > 0) ...[
          CivicFixSpacing.vSpaceLg,
          Text(
            'Attached Photos ($_count)',
            style: CivicFixTypography.captionMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: CivicFixColors.primaryText,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _count,
            separatorBuilder: (_, _) => CivicFixSpacing.vSpaceSm,
            itemBuilder: (context, index) {
              final photoPath = widget.images.length > index ? widget.images[index] : '';
              final item = widget.evidenceItems != null && widget.evidenceItems!.length > index
                  ? widget.evidenceItems![index]
                  : null;

              return _EvidenceCard(
                index: index,
                photoPath: photoPath,
                evidenceItem: item,
                onTapPreview: () => _openPhotoPreview(index, photoPath, item),
                onRemove: () => _removeImage(index),
                onReplace: () => _handleReplace(index),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final int index;
  final String photoPath;
  final EvidenceItem? evidenceItem;
  final VoidCallback onTapPreview;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  const _EvidenceCard({
    required this.index,
    required this.photoPath,
    this.evidenceItem,
    required this.onTapPreview,
    required this.onRemove,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = evidenceItem?.fileName ?? photoPath.split('/').last;
    final isCamera = evidenceItem?.source == EvidenceSource.camera ||
        photoPath.toLowerCase().contains('cam') ||
        photoPath.toLowerCase().contains('camera');
    final sourceLabel = evidenceItem?.source.label ?? (isCamera ? 'Camera' : 'Gallery');

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.sm),
      child: Row(
        children: [
          // Photo Thumbnail Button (Tap to Preview)
          InkWell(
            onTap: onTapPreview,
            borderRadius: CivicFixRadius.chipRadius,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: CivicFixColors.surfaceMuted,
                borderRadius: CivicFixRadius.chipRadius,
                border: Border.all(color: CivicFixColors.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    isCamera ? Icons.camera_alt_outlined : Icons.image_outlined,
                    color: CivicFixColors.secondaryDark,
                    size: 26,
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: CivicFixColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          CivicFixSpacing.hSpaceMd,

          // Photo Details & Tap Preview trigger
          Expanded(
            child: InkWell(
              onTap: onTapPreview,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Photo ${index + 1}',
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: CivicFixColors.primary.withValues(alpha: 0.08),
                          borderRadius: CivicFixRadius.chipRadius,
                        ),
                        child: Text(
                          sourceLabel,
                          style: CivicFixTypography.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: CivicFixColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Replace Button
          IconButton(
            icon: const Icon(Icons.sync_rounded, size: 20),
            tooltip: 'Replace Photo',
            color: CivicFixColors.secondaryText,
            onPressed: onReplace,
          ),

          // Remove Button [ ✕ ]
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Remove Photo',
            color: CivicFixColors.error,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
