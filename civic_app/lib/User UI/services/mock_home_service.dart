import 'dart:async';
import '../../core/local/mock_data_source.dart';
import '../../core/location/location_model.dart';
import '../../core/models/category_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/utils/greeting_helper.dart';
import '../models/home_data_model.dart';
import 'mock_auth_service.dart';

/// Abstract service contract for fetching Home screen data.
abstract class HomeService {
  Future<HomeDataModel> getHomeData({bool forceRefresh = false, bool simulateError = false});
}

/// In-memory Mock Home Service implementation for User UI development.
class MockHomeService implements HomeService {
  static final MockHomeService _instance = MockHomeService._internal();
  factory MockHomeService() => _instance;
  MockHomeService._internal();

  final AuthService _authService = MockAuthService();
  final MockDataSource _dataSource = MockDataSource();

  List<ComplaintModel>? _overrideComplaints;
  List<NearbyHazardModel>? _overrideHazards;

  /// Allows unit tests to inject custom complaints (e.g. empty list).
  void setMockComplaints(List<ComplaintModel>? complaints) {
    _overrideComplaints = complaints;
  }

  /// Allows unit tests to inject custom hazards.
  void setMockHazards(List<NearbyHazardModel>? hazards) {
    _overrideHazards = hazards;
  }

  /// Resets test overrides back to default mock data.
  void resetMockData() {
    _overrideComplaints = null;
    _overrideHazards = null;
  }

  @override
  Future<HomeDataModel> getHomeData({bool forceRefresh = false, bool simulateError = false}) async {
    // Simulate brief asynchronous data loading (250ms)
    await Future.delayed(const Duration(milliseconds: 250));

    if (simulateError) {
      throw Exception('Failed to load civic dashboard data. Please try again.');
    }

    final user = _authService.currentUser ?? _dataSource.currentUser;
    final greeting = GreetingHelper.formatUserGreeting(user.fullName);
    const welcomeMessage = 'Help make your community better.';

    final unreadCount = _dataSource.notifications.where((n) => !n.isRead).length;

    // Default or overridden recent complaints
    final complaints = _overrideComplaints ?? _getDefaultRecentComplaints();

    // Default or overridden nearby hazards
    final hazards = _overrideHazards ?? _getDefaultNearbyHazards();

    // Civic progress
    final progress = CivicProgressSummary.fromUser(user);

    return HomeDataModel(
      user: user,
      greeting: greeting,
      welcomeMessage: welcomeMessage,
      unreadNotificationsCount: unreadCount,
      recentComplaints: complaints,
      nearbyHazards: hazards,
      progress: progress,
    );
  }

  List<ComplaintModel> _getDefaultRecentComplaints() {
    if (_dataSource.complaints.isNotEmpty) {
      return _dataSource.complaints;
    }
    return [
      ComplaintModel(
        id: 'cmp_201',
        ticketNumber: 'CF-2026-000021',
        title: 'Broken street light',
        description: 'Street light fixture is non-functional near corner of 4th cross.',
        category: CivicCategory.defaultCategories[2], // Streetlights
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: '4th Cross, 2nd Main Road',
          landmark: 'Opposite Community Park',
          ward: 'Ward 14',
          city: 'Bengaluru',
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        upvotes: 14,
        isHazard: false,
      ),
      ComplaintModel(
        id: 'cmp_202',
        ticketNumber: 'CF-2026-000018',
        title: 'Road damage near junction',
        category: CivicCategory.defaultCategories[0], // Roads
        description: 'Asphalt eroded creating dangerous trench near traffic junction.',
        status: ComplaintStatus.underReview, // Verified / Under Review
        priority: ComplaintPriority.high,
        location: const CivicLocation(
          latitude: 12.9740,
          longitude: 77.5960,
          address: 'Central Junction, Ring Road',
          landmark: 'Near Signal #3',
          ward: 'Ward 14',
          city: 'Bengaluru',
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        upvotes: 22,
        isHazard: true,
      ),
      ComplaintModel(
        id: 'cmp_203',
        ticketNumber: 'CF-2026-000014',
        title: 'Garbage accumulation',
        category: CivicCategory.defaultCategories[1], // Waste / Sanitation
        description: 'Waste cleared and bins sanitized.',
        status: ComplaintStatus.resolved,
        priority: ComplaintPriority.low,
        location: const CivicLocation(
          latitude: 12.9690,
          longitude: 77.5990,
          address: 'Market Lane, Sector 1',
          landmark: 'Beside Bus Shelter',
          ward: 'Ward 14',
          city: 'Bengaluru',
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        upvotes: 31,
        isHazard: false,
      ),
    ];
  }

  List<NearbyHazardModel> _getDefaultNearbyHazards() {
    if (_dataSource.hazards.isNotEmpty) {
      return _dataSource.hazards
          .take(3)
          .map((h) => NearbyHazardModel.fromHazard(h, distanceMeters: 350 + (_dataSource.hazards.indexOf(h) * 250)))
          .toList();
    }
    return [
      NearbyHazardModel(
        id: 'haz_01',
        ticketNumber: 'CF-2026-000018',
        title: 'Road Damage near junction',
        category: CivicCategory.defaultCategories[0], // Roads
        distanceMeters: 350,
        distanceText: '350 m away',
        status: ComplaintStatus.underReview,
        locality: 'Central Junction',
      ),
      NearbyHazardModel(
        id: 'haz_02',
        ticketNumber: 'CF-2026-000025',
        title: 'Waterlogging on walkway',
        category: CivicCategory.defaultCategories[3], // Water / Drainage
        distanceMeters: 620,
        distanceText: '620 m away',
        status: ComplaintStatus.inProgress,
        locality: '8th Avenue',
      ),
      NearbyHazardModel(
        id: 'haz_03',
        ticketNumber: 'CF-2026-000030',
        title: 'Open Manhole without barrier',
        category: CivicCategory.defaultCategories[0], // Roads / Hazard
        distanceMeters: 900,
        distanceText: '900 m away',
        status: ComplaintStatus.submitted,
        locality: 'School Cross Road',
      ),
    ];
  }
}
