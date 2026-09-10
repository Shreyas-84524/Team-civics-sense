import 'dart:async';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/hazard_repository.dart';
import '../../core/repositories/notification_repository.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/utils/greeting_helper.dart';
import '../models/home_data_model.dart';
import 'mock_home_service.dart';

/// Production [HomeService] aggregating live state from offline-first repositories.
class AppHomeService implements HomeService {
  final ComplaintRepository? _complaintRepo;
  final HazardRepository? _hazardRepo;
  final UserRepository? _userRepo;
  final NotificationRepository? _notificationRepo;

  AppHomeService({
    ComplaintRepository? complaintRepository,
    HazardRepository? hazardRepository,
    UserRepository? userRepository,
    NotificationRepository? notificationRepository,
  })  : _complaintRepo = complaintRepository,
        _hazardRepo = hazardRepository,
        _userRepo = userRepository,
        _notificationRepo = notificationRepository;

  ComplaintRepository get _activeComplaintRepo =>
      _complaintRepo ?? RepositoryLocator.complaintRepository;

  HazardRepository get _activeHazardRepo =>
      _hazardRepo ?? RepositoryLocator.hazardRepository;

  UserRepository get _activeUserRepo =>
      _userRepo ?? RepositoryLocator.userRepository;

  NotificationRepository get _activeNotificationRepo =>
      _notificationRepo ?? RepositoryLocator.notificationRepository;

  @override
  Future<HomeDataModel> getHomeData({
    bool forceRefresh = false,
    bool simulateError = false,
  }) async {
    if (simulateError) {
      throw Exception('Failed to load civic dashboard data. Please try again.');
    }

    final user = await _activeUserRepo.getCurrentUser();
    final greeting = GreetingHelper.formatUserGreeting(user.fullName);
    const welcomeMessage = 'Help make your community better.';

    final unreadCount = await _activeNotificationRepo.getUnreadCount(userId: user.id);

    final complaints = await _activeComplaintRepo.getCitizenComplaints(user.id);

    final hazards = await _activeHazardRepo.getHazards();
    final nearbyHazards = hazards
        .take(3)
        .map((h) => NearbyHazardModel.fromHazard(h))
        .toList();

    final progress = CivicProgressSummary.fromUser(user);

    return HomeDataModel(
      user: user,
      greeting: greeting,
      welcomeMessage: welcomeMessage,
      unreadNotificationsCount: unreadCount,
      recentComplaints: complaints,
      nearbyHazards: nearbyHazards,
      progress: progress,
    );
  }
}
