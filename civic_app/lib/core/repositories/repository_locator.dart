import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../Govt UI/services/analytics_repository.dart';
import '../../Govt UI/services/govt_complaint_analytics_repository.dart';
import '../../Govt UI/services/govt_complaint_repository.dart';
import '../../Govt UI/services/govt_user_repository.dart';
import '../../User UI/services/app_home_service.dart';
import '../../User UI/services/evidence_service.dart';
import '../../User UI/services/geolocator_location_service.dart';
import '../../User UI/services/image_picker_evidence_service.dart';
import '../../User UI/services/location_service.dart';
import '../../User UI/services/mock_complaint_service.dart';
import '../../User UI/services/mock_home_service.dart';
import '../../User UI/services/offline_first_complaint_service.dart';
import 'complaint_repository.dart';
import 'hazard_repository.dart';
import 'notification_repository.dart';
import 'offline_first_complaint_repository.dart';
import 'offline_first_govt_complaint_repository.dart';
import 'offline_first_hazard_repository.dart';
import 'offline_first_notification_repository.dart';
import 'offline_first_rewards_repository.dart';
import 'offline_first_user_repository.dart';
import 'rewards_repository.dart';
import 'user_repository.dart';

/// Centralized Service Locator & Provider for Citizen and Government Repositories.
///
/// Provides a single source of truth for repository dependencies across the application,
/// ensuring the UI communicates with production [OfflineFirst] implementations when
/// Firebase is ready while supporting seamless mock overrides for unit and widget testing.
class RepositoryLocator {
  RepositoryLocator._();

  static bool _useProduction = true;

  /// Returns whether a Firebase application instance is initialized.
  static bool get isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Whether production repositories are currently active.
  static bool get isProductionActive => _useProduction;

  static ComplaintRepository? _complaintRepository;
  static GovtComplaintRepository? _govtComplaintRepository;
  static HazardRepository? _hazardRepository;
  static NotificationRepository? _notificationRepository;
  static RewardsRepository? _rewardsRepository;
  static UserRepository? _userRepository;
  static GovernmentUserRepository? _govtUserRepository;
  static AnalyticsRepository? _analyticsRepository;
  static HomeService? _homeService;
  static ComplaintService? _complaintService;
  static EvidenceService? _evidenceService;
  static LocationService? _locationService;

  // ===========================================================================
  // CITIZEN REPOSITORIES & SERVICES
  // ===========================================================================

  /// Active Citizen [ComplaintRepository] instance.
  static ComplaintRepository get complaintRepository {
    if (_complaintRepository != null) return _complaintRepository!;
    if (isProductionActive) {
      _complaintRepository = OfflineFirstComplaintRepository();
    } else {
      _complaintRepository = MockComplaintRepository();
    }
    return _complaintRepository!;
  }

  static set complaintRepository(ComplaintRepository repo) {
    _complaintRepository = repo;
  }

  /// Active [HazardRepository] instance.
  static HazardRepository get hazardRepository {
    if (_hazardRepository != null) return _hazardRepository!;
    if (isProductionActive) {
      _hazardRepository = OfflineFirstHazardRepository();
    } else {
      _hazardRepository = MockHazardRepository();
    }
    return _hazardRepository!;
  }

  static set hazardRepository(HazardRepository repo) {
    _hazardRepository = repo;
  }

  /// Active [NotificationRepository] instance.
  static NotificationRepository get notificationRepository {
    if (_notificationRepository != null) return _notificationRepository!;
    if (isProductionActive) {
      _notificationRepository = OfflineFirstNotificationRepository();
    } else {
      _notificationRepository = MockNotificationRepository();
    }
    return _notificationRepository!;
  }

  static set notificationRepository(NotificationRepository repo) {
    _notificationRepository = repo;
  }

  /// Active [RewardsRepository] instance.
  static RewardsRepository get rewardsRepository {
    if (_rewardsRepository != null) return _rewardsRepository!;
    if (isProductionActive) {
      _rewardsRepository = OfflineFirstRewardsRepository();
    } else {
      _rewardsRepository = MockRewardsRepository();
    }
    return _rewardsRepository!;
  }

  static set rewardsRepository(RewardsRepository repo) {
    _rewardsRepository = repo;
  }

  /// Active Citizen [UserRepository] instance.
  static UserRepository get userRepository {
    if (_userRepository != null) return _userRepository!;
    if (isProductionActive) {
      _userRepository = OfflineFirstUserRepository();
    } else {
      _userRepository = MockUserRepository();
    }
    return _userRepository!;
  }

  static set userRepository(UserRepository repo) {
    _userRepository = repo;
  }

  /// Active Citizen [HomeService] instance.
  static HomeService get homeService {
    if (_homeService != null) return _homeService!;
    if (isProductionActive) {
      _homeService = AppHomeService();
    } else {
      _homeService = MockHomeService();
    }
    return _homeService!;
  }

  static set homeService(HomeService service) {
    _homeService = service;
  }

  /// Active Citizen [ComplaintService] instance.
  static ComplaintService get complaintService {
    if (_complaintService != null) return _complaintService!;
    if (isProductionActive) {
      _complaintService = OfflineFirstComplaintService();
    } else {
      _complaintService = MockComplaintService();
    }
    return _complaintService!;
  }

  static set complaintService(ComplaintService service) {
    _complaintService = service;
  }

  /// Active Citizen [EvidenceService] instance.
  static EvidenceService get evidenceService {
    if (_evidenceService != null) return _evidenceService!;
    if (isProductionActive) {
      _evidenceService = ImagePickerEvidenceService();
    } else {
      _evidenceService = MockEvidenceService();
    }
    return _evidenceService!;
  }

  static set evidenceService(EvidenceService service) {
    _evidenceService = service;
  }

  /// Active Citizen [LocationService] instance.
  static LocationService get locationService {
    if (_locationService != null) return _locationService!;
    if (isProductionActive) {
      _locationService = const GeolocatorLocationService();
    } else {
      _locationService = MockLocationService();
    }
    return _locationService!;
  }

  static set locationService(LocationService service) {
    _locationService = service;
  }

  // ===========================================================================
  // GOVERNMENT REPOSITORIES & SERVICES
  // ===========================================================================

  /// Active [GovtComplaintRepository] instance.
  static GovtComplaintRepository get govtComplaintRepository {
    if (_govtComplaintRepository != null) return _govtComplaintRepository!;
    if (isProductionActive) {
      _govtComplaintRepository = OfflineFirstGovtComplaintRepository();
    } else {
      _govtComplaintRepository = MockGovtComplaintRepository();
    }
    return _govtComplaintRepository!;
  }

  static set govtComplaintRepository(GovtComplaintRepository repo) {
    _govtComplaintRepository = repo;
  }

  /// Active [GovernmentUserRepository] instance.
  static GovernmentUserRepository get govtUserRepository {
    _govtUserRepository ??= MockGovernmentUserRepository();
    return _govtUserRepository!;
  }

  static set govtUserRepository(GovernmentUserRepository repo) {
    _govtUserRepository = repo;
  }

  /// Active [AnalyticsRepository] instance.
  static AnalyticsRepository get analyticsRepository {
    if (_analyticsRepository != null) return _analyticsRepository!;
    if (isProductionActive) {
      _analyticsRepository = GovtComplaintAnalyticsRepository();
    } else {
      _analyticsRepository = MockAnalyticsRepository();
    }
    return _analyticsRepository!;
  }

  static set analyticsRepository(AnalyticsRepository repo) {
    _analyticsRepository = repo;
  }

  // ===========================================================================
  // ENVIRONMENT & TESTING HOOKS
  // ===========================================================================

  /// Configures the locator to use production OfflineFirst repositories.
  static void useProductionRepositories() {
    _useProduction = true;
    _complaintRepository = OfflineFirstComplaintRepository();
    _govtComplaintRepository = OfflineFirstGovtComplaintRepository();
    _hazardRepository = OfflineFirstHazardRepository();
    _notificationRepository = OfflineFirstNotificationRepository();
    _rewardsRepository = OfflineFirstRewardsRepository();
    _userRepository = OfflineFirstUserRepository();
    _govtUserRepository = MockGovernmentUserRepository();
    _analyticsRepository = GovtComplaintAnalyticsRepository();
    _homeService = AppHomeService();
    _complaintService = OfflineFirstComplaintService();
    _evidenceService = ImagePickerEvidenceService();
    _locationService = const GeolocatorLocationService();
  }

  /// Switches all repository instances to in-memory Mock implementations.
  static void useMockRepositories() {
    _useProduction = false;
    _complaintRepository = MockComplaintRepository();
    _govtComplaintRepository = MockGovtComplaintRepository();
    _hazardRepository = MockHazardRepository();
    _notificationRepository = MockNotificationRepository();
    _rewardsRepository = MockRewardsRepository();
    _userRepository = MockUserRepository();
    _govtUserRepository = MockGovernmentUserRepository();
    _analyticsRepository = MockAnalyticsRepository();
    _homeService = MockHomeService();
    _complaintService = MockComplaintService();
    _evidenceService = MockEvidenceService();
    _locationService = MockLocationService();
  }

  /// Resets all cached repository instances to trigger lazy default initialization.
  @visibleForTesting
  static void reset() {
    _useProduction = false;
    _complaintRepository = null;
    _govtComplaintRepository = null;
    _hazardRepository = null;
    _notificationRepository = null;
    _rewardsRepository = null;
    _userRepository = null;
    _govtUserRepository = null;
    _analyticsRepository = null;
    _homeService = null;
    _complaintService = null;
    _evidenceService = null;
    _locationService = null;
  }
}
