import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/location/location_model.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../services/location_service.dart';

/// Screen allowing citizen to pinpoint and confirm civic issue location on an interactive map.
class SelectLocationScreen extends StatefulWidget {
  final CivicLocation? initialLocation;
  final LocationService? locationService;

  const SelectLocationScreen({
    super.key,
    this.initialLocation,
    this.locationService,
  });

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  late final LocationService _locationService;
  late CivicLocation _currentLocation;
  final TextEditingController _searchController = TextEditingController();
  List<CivicLocation> _searchResults = [];
  bool _isSearching = false;
  bool _isLocatingGps = false;

  // Normalized map offset for interactive pin simulation
  double _pinOffsetX = 0.0;
  double _pinOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? MockLocationService();
    _currentLocation = widget.initialLocation ??
        const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: '4th Main Road, Near Metro Pillar 142',
          landmark: 'Opposite Central Supermarket',
          ward: 'Ward 14 (Central Ward)',
          city: 'Bengaluru',
          pincode: '560001',
          source: LocationSource.manual,
        );
    _searchController.text = _currentLocation.address;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearchQuery(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _locationService.searchPlaces(query);
    if (!mounted) return;

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _selectSearchResult(CivicLocation location) {
    setState(() {
      _currentLocation = location.copyWith(source: LocationSource.manual);
      _searchController.text = location.address;
      _searchResults = [];
      _pinOffsetX = 0;
      _pinOffsetY = 0;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleMapTap(TapDownDetails details, Size mapSize) async {
    final centerX = mapSize.width / 2;
    final centerY = mapSize.height / 2;

    final dx = details.localPosition.dx - centerX;
    final dy = details.localPosition.dy - centerY;

    // Small synthetic delta for coordinates
    final latDelta = -(dy / mapSize.height) * 0.01;
    final lngDelta = (dx / mapSize.width) * 0.01;

    final newLat = (_currentLocation.latitude + latDelta).clamp(-90.0, 90.0);
    final newLng = (_currentLocation.longitude + lngDelta).clamp(-180.0, 180.0);

    setState(() {
      _pinOffsetX = dx.clamp(-mapSize.width * 0.4, mapSize.width * 0.4);
      _pinOffsetY = dy.clamp(-mapSize.height * 0.3, mapSize.height * 0.3);
    });

    final updatedLoc = await _locationService.reverseGeocode(newLat, newLng);
    if (!mounted) return;

    setState(() {
      _currentLocation = updatedLoc.copyWith(source: LocationSource.manual);
      _searchController.text = _currentLocation.address;
    });
  }

  Future<void> _centerOnGps() async {
    setState(() {
      _isLocatingGps = true;
    });

    try {
      final gpsLoc = await _locationService.getCurrentLocation();
      if (!mounted) return;

      if (gpsLoc != null) {
        setState(() {
          _currentLocation = gpsLoc;
          _searchController.text = gpsLoc.address;
          _pinOffsetX = 0;
          _pinOffsetY = 0;
          _isLocatingGps = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLocatingGps = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not acquire GPS position. Please adjust pin manually.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CivicFixAppBar(
        title: 'Confirm Location',
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapSize = Size(constraints.maxWidth, constraints.maxHeight);

          return ResponsiveContainer(
            child: Stack(
              children: [
                // 1. Interactive Map Simulation Canvas
                GestureDetector(
                  onTapDown: (details) => _handleMapTap(details, mapSize),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0xFFE5ECE9),
                    child: CustomPaint(
                      painter: _MapGridPainter(),
                      child: Stack(
                        children: [
                          // Center / Offset Pin Marker
                          Center(
                            child: Transform.translate(
                              offset: Offset(_pinOffsetX, _pinOffsetY),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: CivicFixSpacing.md,
                                      vertical: CivicFixSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CivicFixColors.primary,
                                      borderRadius: CivicFixRadius.chipRadius,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Tap map to position pin',
                                      style: CivicFixTypography.captionMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  CivicFixSpacing.vSpaceXs,
                                  const Icon(
                                    Icons.location_pin,
                                    size: 48,
                                    color: CivicFixColors.error,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Center to GPS Floating Button
                Positioned(
                  right: CivicFixSpacing.lg,
                  bottom: 220,
                  child: FloatingActionButton.small(
                    heroTag: 'gps_center_btn',
                    backgroundColor: Colors.white,
                    foregroundColor: CivicFixColors.secondaryDark,
                    elevation: 3,
                    tooltip: 'Center on My GPS',
                    onPressed: _isLocatingGps ? null : _centerOnGps,
                    child: _isLocatingGps
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ),

                // 3. Top Place Search Bar & Dropdown Results
                Positioned(
                  top: CivicFixSpacing.lg,
                  left: CivicFixSpacing.lg,
                  right: CivicFixSpacing.lg,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CivicFixCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CivicFixSpacing.md,
                          vertical: CivicFixSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: CivicFixColors.secondaryText),
                            CivicFixSpacing.hSpaceSm,
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: CivicFixTypography.bodySmall,
                                onChanged: _handleSearchQuery,
                                decoration: const InputDecoration(
                                  hintText: 'Search street, area or landmark...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  filled: false,
                                ),
                              ),
                            ),
                            if (_isSearching)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: CivicFixColors.secondaryText,
                                onPressed: () {
                                  _searchController.clear();
                                  _handleSearchQuery('');
                                },
                              ),
                          ],
                        ),
                      ),

                      // Autocomplete Suggestions Dropdown
                      if (_searchResults.isNotEmpty) ...[
                        CivicFixSpacing.vSpaceXs,
                        Material(
                          color: Colors.white,
                          borderRadius: CivicFixRadius.cardRadius,
                          elevation: 4,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                    color: CivicFixColors.primary,
                                    size: 20,
                                  ),
                                  title: Text(
                                    item.address,
                                    style: CivicFixTypography.bodySmallMedium,
                                  ),
                                  subtitle: Text(
                                    item.ward ?? item.city ?? '',
                                    style: CivicFixTypography.caption,
                                  ),
                                  onTap: () => _selectSearchResult(item),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 4. Bottom Location Confirmation Details Card
                Positioned(
                  bottom: CivicFixSpacing.lg,
                  left: CivicFixSpacing.lg,
                  right: CivicFixSpacing.lg,
                  child: CivicFixCard(
                    padding: const EdgeInsets.all(CivicFixSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.pin_drop_rounded,
                              color: CivicFixColors.primary,
                              size: 20,
                            ),
                            CivicFixSpacing.hSpaceSm,
                            Text(
                              'Selected Location',
                              style: CivicFixTypography.bodySmallMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _currentLocation.isGps
                                    ? CivicFixColors.secondary.withValues(alpha: 0.12)
                                    : CivicFixColors.primary.withValues(alpha: 0.08),
                                borderRadius: CivicFixRadius.chipRadius,
                              ),
                              child: Text(
                                _currentLocation.sourceLabel,
                                style: CivicFixTypography.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _currentLocation.isGps
                                      ? CivicFixColors.secondaryDark
                                      : CivicFixColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        CivicFixSpacing.vSpaceSm,
                        Text(
                          _currentLocation.shortDisplayAddress,
                          style: CivicFixTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentLocation.ward != null) ...[
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            '${_currentLocation.ward} • Lat: ${_currentLocation.latitude.toStringAsFixed(4)}, Long: ${_currentLocation.longitude.toStringAsFixed(4)}',
                            style: CivicFixTypography.caption.copyWith(
                              color: CivicFixColors.secondaryText,
                            ),
                          ),
                        ],
                        CivicFixSpacing.vSpaceLg,
                        CivicFixButton(
                          text: 'Confirm This Location',
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: () {
                            Navigator.pop(context, _currentLocation);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter to simulate subtle road grid texture on map canvas
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 6.0;

    final secondaryRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 3.0;

    // Draw main roads
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.38), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.62), roadPaint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.42, size.height), roadPaint);

    // Draw secondary roads
    canvas.drawLine(Offset(size.width * 0.15, 0), Offset(size.width * 0.18, size.height), secondaryRoadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.72, size.height), secondaryRoadPaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), secondaryRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
