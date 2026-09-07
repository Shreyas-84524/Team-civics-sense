import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/location/location_model.dart';
import '../../../core/widgets/civic_fix_card.dart';
import '../../services/location_service.dart';

/// Location selection and confirmation widget for Step 3 of Report Issue.
///
/// Supports GPS auto-detection, permission handling, disabled service alerts,
/// manual map selection triggers, and verified location confirmation cards.
class LocationSelectionCard extends StatefulWidget {
  final CivicLocation? selectedLocation;
  final ValueChanged<CivicLocation> onLocationSelected;
  final VoidCallback onOpenMapPicker;
  final String? errorMessage;
  final LocationService? locationService;

  const LocationSelectionCard({
    super.key,
    required this.selectedLocation,
    required this.onLocationSelected,
    required this.onOpenMapPicker,
    this.errorMessage,
    this.locationService,
  });

  @override
  State<LocationSelectionCard> createState() => _LocationSelectionCardState();
}

class _LocationSelectionCardState extends State<LocationSelectionCard> {
  late final LocationService _locationService;
  bool _isDetecting = false;
  String? _detectionError;
  CivicPermissionStatus? _permissionStatus;
  bool _isServiceDisabled = false;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? MockLocationService();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isDetecting = true;
      _detectionError = null;
      _permissionStatus = null;
      _isServiceDisabled = false;
    });

    try {
      final isEnabled = await _locationService.isLocationServiceEnabled();
      if (!isEnabled) {
        if (!mounted) return;
        setState(() {
          _isDetecting = false;
          _isServiceDisabled = true;
          _detectionError = 'Location services are disabled on your device.';
        });
        return;
      }

      final perm = await _locationService.checkPermission();
      if (perm != CivicPermissionStatus.granted) {
        final requested = await _locationService.requestPermission();
        if (requested != CivicPermissionStatus.granted) {
          if (!mounted) return;
          setState(() {
            _isDetecting = false;
            _permissionStatus = requested;
            _detectionError = 'Location permission was denied. You can select your location manually on the map.';
          });
          return;
        }
      }

      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;

      if (location != null) {
        setState(() {
          _isDetecting = false;
        });
        widget.onLocationSelected(location);
      } else {
        setState(() {
          _isDetecting = false;
          _detectionError = 'Unable to determine GPS location. Please try again or select on map.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      setState(() {
        _isDetecting = false;
        if (errorStr.toLowerCase().contains('disabled')) {
          _isServiceDisabled = true;
        } else if (errorStr.toLowerCase().contains('permission')) {
          _permissionStatus = CivicPermissionStatus.denied;
        }
        _detectionError = errorStr.replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.selectedLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Issue Location',
              style: CivicFixTypography.bodySmallMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: CivicFixColors.primaryText,
              ),
            ),
            Text(
              ' *',
              style: CivicFixTypography.bodySmallMedium.copyWith(
                color: CivicFixColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceXs,
        Text(
          'Pinpoint where the problem is located so municipal crews can find it immediately.',
          style: CivicFixTypography.caption.copyWith(
            color: CivicFixColors.secondaryText,
          ),
        ),
        CivicFixSpacing.vSpaceMd,

        // Permission / Service Disabled Warning Banner
        if (_permissionStatus != null || _isServiceDisabled) ...[
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: CivicFixColors.statusUnderReviewBg,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(color: CivicFixColors.alert.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isServiceDisabled ? Icons.location_off_rounded : Icons.shield_outlined,
                      color: CivicFixColors.alertDark,
                      size: 20,
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Expanded(
                      child: Text(
                        _isServiceDisabled ? 'Location Services Disabled' : 'Location Permission Required',
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          color: CivicFixColors.alertDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  _detectionError ?? 'Please enable location access or select manually on the map.',
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.primaryText,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onOpenMapPicker,
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Select on Map Instead'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: CivicFixSpacing.md,
                          vertical: CivicFixSpacing.sm,
                        ),
                        visualDensity: VisualDensity.compact,
                        foregroundColor: CivicFixColors.primary,
                        side: const BorderSide(color: CivicFixColors.primary),
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    TextButton(
                      onPressed: _detectCurrentLocation,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: CivicFixSpacing.sm,
                          vertical: CivicFixSpacing.xs,
                        ),
                      ),
                      child: const Text('Retry GPS'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceMd,
        ],

        // General Error banner (if not permission/service issue)
        if (_detectionError != null && _permissionStatus == null && !_isServiceDisabled) ...[
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
                    _detectionError!,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: CivicFixColors.error,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _detectCurrentLocation,
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
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceMd,
        ],

        if (location == null) ...[
          // Option 1: Use Current GPS Location
          CivicFixCard(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: CivicFixColors.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: CivicFixColors.secondary,
                    size: 26,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                Text(
                  'Use Device Location',
                  style: CivicFixTypography.bodySmallMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  'Automatically detect your current street and ward using GPS',
                  textAlign: TextAlign.center,
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                  ),
                ),
                CivicFixSpacing.vSpaceMd,
                if (_isDetecting)
                  const SizedBox(
                    height: 48,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          SizedBox(width: 10),
                          Text('Detecting GPS location...', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _detectCurrentLocation,
                    icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                    label: const Text('Use My Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CivicFixColors.secondary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: CivicFixRadius.buttonRadius,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceMd,

          // Divider with "OR"
          Row(
            children: [
              const Expanded(child: Divider(color: CivicFixColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md),
                child: Text(
                  'OR',
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: CivicFixColors.border)),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // Option 2: Select on Map
          OutlinedButton.icon(
            onPressed: widget.onOpenMapPicker,
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text('Select on Map'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CivicFixColors.primary,
              side: const BorderSide(color: CivicFixColors.primary),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: CivicFixRadius.buttonRadius,
              ),
            ),
          ),
        ] else ...[
          // Confirmed Location Card
          CivicFixCard(
            borderColor: CivicFixColors.secondary,
            backgroundColor: CivicFixColors.accentLight.withValues(alpha: 0.18),
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: CivicFixSpacing.xs,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: CivicFixColors.secondary,
                                size: 18,
                              ),
                              CivicFixSpacing.hSpaceXs,
                              Text(
                                'Location Selected ✓',
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: CivicFixColors.secondaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: location.isGps
                                  ? CivicFixColors.secondary.withValues(alpha: 0.15)
                                  : CivicFixColors.primary.withValues(alpha: 0.1),
                              borderRadius: CivicFixRadius.chipRadius,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  location.isGps ? Icons.gps_fixed_rounded : Icons.pin_drop_outlined,
                                  size: 12,
                                  color: location.isGps ? CivicFixColors.secondaryDark : CivicFixColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  location.sourceLabel,
                                  style: CivicFixTypography.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: location.isGps ? CivicFixColors.secondaryDark : CivicFixColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: widget.onOpenMapPicker,
                      icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                      label: const Text('Change Location'),
                      style: TextButton.styleFrom(
                        foregroundColor: CivicFixColors.secondaryDark,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(CivicFixSpacing.sm),
                      decoration: BoxDecoration(
                        color: CivicFixColors.surface,
                        borderRadius: CivicFixRadius.chipRadius,
                        border: Border.all(color: CivicFixColors.border),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: CivicFixColors.primary,
                        size: 24,
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.address,
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (location.landmark != null && location.landmark!.isNotEmpty) ...[
                            CivicFixSpacing.vSpaceXs,
                            Text(
                              'Landmark: ${location.landmark}',
                              style: CivicFixTypography.caption.copyWith(
                                color: CivicFixColors.secondaryText,
                              ),
                            ),
                          ],
                          if (location.ward != null && location.ward!.isNotEmpty) ...[
                            CivicFixSpacing.vSpaceXs,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: CivicFixSpacing.xs + 2,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CivicFixColors.surface,
                                borderRadius: CivicFixRadius.chipRadius,
                                border: Border.all(color: CivicFixColors.border),
                              ),
                              child: Text(
                                location.ward!,
                                style: CivicFixTypography.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: CivicFixColors.primaryText,
                                ),
                              ),
                            ),
                          ],
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'Lat: ${location.latitude.toStringAsFixed(4)}, Long: ${location.longitude.toStringAsFixed(4)}${location.accuracyMeters != null ? ' • ±${location.accuracyMeters!.toStringAsFixed(1)}m' : ''}',
                            style: CivicFixTypography.caption.copyWith(
                              fontSize: 10,
                              color: CivicFixColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Error message if location is missing when advancing
        if (widget.errorMessage != null) ...[
          CivicFixSpacing.vSpaceXs,
          Padding(
            padding: const EdgeInsets.only(left: CivicFixSpacing.xs),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: CivicFixColors.error,
                  size: 14,
                ),
                CivicFixSpacing.hSpaceXs,
                Text(
                  widget.errorMessage!,
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
