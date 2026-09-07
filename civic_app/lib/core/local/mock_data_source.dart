import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../location/location_model.dart';
import '../models/category_model.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';
import '../models/notification_model.dart';
import '../models/reward_model.dart';
import '../models/user_model.dart';

/// In-memory mock data provider for Phase 1 Citizen UI.
class MockDataSource {
  static final MockDataSource _instance = MockDataSource._internal();
  factory MockDataSource() => _instance;
  MockDataSource._internal() {
    userNotifier = ValueNotifier<UserModel>(currentUser);
  }

  static UserModel _createDefaultUser() => const UserModel(
        id: 'user_citizen_001',
        fullName: 'Shreyas Shigwan',
        email: 'citizen@civicfix.test',
        phone: '+91 98765 43210',
        civicPoints: 850,
        reportsSubmitted: 12,
        reportsResolved: 8,
        wardNumber: 'Ward 14 (Central Ward)',
        languageCode: 'en',
        badges: [
          'First Report',
          'Civic Contributor',
          'Community Helper',
        ],
      );

  late UserModel currentUser = _createDefaultUser();
  late ValueNotifier<UserModel> userNotifier;

  ValueListenable<UserModel> get userListenable => userNotifier;

  void updateCurrentUser(UserModel user) {
    currentUser = user;
    userNotifier.value = user;
  }

  late List<ComplaintModel> complaints = _createInitialComplaints();
  late List<HazardModel> hazards = _createInitialHazards();
  late List<NotificationModel> notifications = _createInitialNotifications();
  late List<CivicAchievement> achievements = CivicAchievement.defaultAchievements();

  void resetMockData() {
    currentUser = _createDefaultUser();
    userNotifier.value = currentUser;
    complaints = _createInitialComplaints();
    hazards = _createInitialHazards();
    notifications = _createInitialNotifications();
    achievements = CivicAchievement.defaultAchievements();
  }

  static List<ComplaintModel> _createInitialComplaints() => [
    ComplaintModel(
      id: 'cmp_101',
      citizenId: 'user_citizen_001',
      ticketNumber: 'CF-2026-000024',
      title: 'Broken street light near park',
      description: 'The pole streetlight opposite the children play area has been dark for 3 days.',
      category: CivicCategory.defaultCategories[4], // Street Lights
      status: ComplaintStatus.reported,
      priority: ComplaintPriority.medium,
      location: const CivicLocation(
        latitude: 12.9716,
        longitude: 77.5946,
        address: '4th Cross Road',
        landmark: 'Near Andheri East',
        ward: 'Ward 14',
        city: 'Bengaluru',
      ),
      imageUrls: const [],
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      upvotes: 4,
      isHazard: false,
      timeline: [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Grievance registered and queued for electrical department review.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          status: ComplaintStatus.reported,
        ),
      ],
    ),
    ComplaintModel(
      id: 'cmp_102',
      citizenId: 'user_citizen_001',
      ticketNumber: 'CF-2026-000021',
      title: 'Road damage near junction',
      description: 'Large potholes forming dangerous craters after heavy rain at main intersection.',
      category: CivicCategory.defaultCategories[0], // Roads
      status: ComplaintStatus.inProgress,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 12.9750,
        longitude: 77.5980,
        address: '4th Main Road, Metro Cross',
        landmark: 'Near Main Junction',
        ward: 'Ward 14',
        city: 'Bengaluru',
      ),
      imageUrls: const [
        'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=500',
        'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=500',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      upvotes: 24,
      isHazard: true,
      officerNotes: 'Asphalt repair vehicle dispatched.',
      timeline: [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Report lodged with photo evidence.',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          status: ComplaintStatus.reported,
        ),
        TimelineEvent(
          title: 'Site Inspected & Verified',
          description: 'Classified as high priority road hazard by Ward Engineer.',
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          status: ComplaintStatus.verified,
        ),
        TimelineEvent(
          title: 'Assigned to Road Maintenance Crew',
          description: 'Dispatched to Asphalt Rapid Response Team 4.',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          status: ComplaintStatus.assigned,
        ),
        TimelineEvent(
          title: 'Repair In Progress',
          description: 'Road maintenance unit currently working on surface leveling.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          status: ComplaintStatus.inProgress,
        ),
      ],
    ),
    ComplaintModel(
      id: 'cmp_103',
      citizenId: 'user_citizen_001',
      ticketNumber: 'CF-2026-000018',
      title: 'Garbage accumulation',
      description: 'Community waste bins overflowing on footpath, requiring municipal compactor.',
      category: CivicCategory.defaultCategories[3], // Waste Management
      status: ComplaintStatus.verified,
      priority: ComplaintPriority.medium,
      location: const CivicLocation(
        latitude: 12.9690,
        longitude: 77.6010,
        address: '12th Cross, Sector 2',
        landmark: 'Near Community Park',
        ward: 'Ward 14',
        city: 'Bengaluru',
      ),
      imageUrls: const [
        'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=500',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      upvotes: 11,
      isHazard: false,
      timeline: [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Reported by citizen Rahul Sharma.',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
          status: ComplaintStatus.reported,
        ),
        TimelineEvent(
          title: 'Verified by Sanitary Inspector',
          description: 'Site verified. Route compactor requested for next sanitation shift.',
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          status: ComplaintStatus.verified,
        ),
      ],
    ),
    ComplaintModel(
      id: 'cmp_104',
      citizenId: 'user_citizen_001',
      ticketNumber: 'CF-2026-000015',
      title: 'Blocked drainage',
      description: 'Stormwater drain is blocked with debris causing street waterlogging.',
      category: CivicCategory.defaultCategories[5], // Drainage
      status: ComplaintStatus.assigned,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 12.9730,
        longitude: 77.5920,
        address: '2nd Avenue, Block C',
        landmark: 'Near Residential Block',
        ward: 'Ward 14',
        city: 'Bengaluru',
      ),
      imageUrls: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      upvotes: 18,
      isHazard: true,
      assignedTo: 'Drainage Squad 2',
      timeline: [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Submitted with GPS coordinates.',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          status: ComplaintStatus.reported,
        ),
        TimelineEvent(
          title: 'Grievance Verified',
          description: 'Drainage blockage confirmed by zonal coordinator.',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 12)),
          status: ComplaintStatus.verified,
        ),
        TimelineEvent(
          title: 'Assigned to Crew',
          description: 'Assigned to Drainage Squad 2 for desilting.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          status: ComplaintStatus.assigned,
        ),
      ],
    ),
    ComplaintModel(
      id: 'cmp_105',
      citizenId: 'user_citizen_001',
      ticketNumber: 'CF-2026-000011',
      title: 'Water leakage',
      description: 'Potable water supply line leaking near pavement junction.',
      category: CivicCategory.defaultCategories[1], // Water
      status: ComplaintStatus.resolved,
      priority: ComplaintPriority.medium,
      location: const CivicLocation(
        latitude: 12.9780,
        longitude: 77.5910,
        address: '8th Main Road, Market Area',
        landmark: 'Near Market Road',
        ward: 'Ward 14',
        city: 'Bengaluru',
      ),
      imageUrls: const [
        'https://images.unsplash.com/photo-1584467735815-f778f274e296?w=500',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      upvotes: 38,
      isHazard: false,
      resolvedAt: DateTime.now().subtract(const Duration(days: 3)),
      officerNotes: 'Pipe collar replaced and tested leak-free.',
      timeline: [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Ticket created and assigned priority.',
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          status: ComplaintStatus.reported,
        ),
        TimelineEvent(
          title: 'Leak Verified',
          description: 'Water distribution engineer inspected junction pipe.',
          timestamp: DateTime.now().subtract(const Duration(days: 4, hours: 18)),
          status: ComplaintStatus.verified,
        ),
        TimelineEvent(
          title: 'Assigned to Plumbing Wing',
          description: 'Assigned to Zonal Water Maintenance Team B.',
          timestamp: DateTime.now().subtract(const Duration(days: 4, hours: 12)),
          status: ComplaintStatus.assigned,
        ),
        TimelineEvent(
          title: 'Repair In Progress',
          description: 'Excavation and pipe collar replacement.',
          timestamp: DateTime.now().subtract(const Duration(days: 4)),
          status: ComplaintStatus.inProgress,
        ),
        TimelineEvent(
          title: 'Issue Resolved',
          description: 'Water leak repaired and mains pressure restored.',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          status: ComplaintStatus.resolved,
        ),
      ],
    ),
  ];

  static List<HazardModel> _createInitialHazards() => [
    // 1. Road Damage - In Progress (linked to cmp_102 / CF-2026-000021)
    HazardModel(
      id: 'haz_101',
      complaintId: 'cmp_102',
      ticketNumber: 'CF-2026-000021',
      title: 'Road damage near junction',
      category: CivicCategory.defaultCategories[0], // Roads
      status: ComplaintStatus.inProgress,
      latitude: 12.9750,
      longitude: 77.5980,
      address: '4th Main Road, Metro Cross',
      landmark: 'Near Main Junction',
      ward: 'Ward 14',
      severity: HazardSeverity.high,
      imageUrl: 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=500',
      upvotes: 24,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    // 2. Waterlogging - Reported (Standalone civic hazard)
    HazardModel(
      id: 'haz_102',
      ticketNumber: 'CF-2026-000028',
      title: 'Waterlogging near park',
      category: CivicCategory.defaultCategories[1], // Water
      status: ComplaintStatus.reported,
      latitude: 12.9720,
      longitude: 77.6040,
      address: 'Park View Road, Sector 3',
      landmark: 'Near Community Park',
      ward: 'Ward 14',
      severity: HazardSeverity.medium,
      upvotes: 8,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    // 3. Garbage - Verified (linked to cmp_103 / CF-2026-000018)
    HazardModel(
      id: 'haz_103',
      complaintId: 'cmp_103',
      ticketNumber: 'CF-2026-000018',
      title: 'Garbage accumulation',
      category: CivicCategory.defaultCategories[3], // Waste Management
      status: ComplaintStatus.verified,
      latitude: 12.9690,
      longitude: 77.6010,
      address: '12th Cross, Sector 2',
      landmark: 'Near Residential Block',
      ward: 'Ward 14',
      severity: HazardSeverity.medium,
      imageUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=500',
      upvotes: 11,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    // 4. Open Manhole - Assigned (Standalone critical hazard)
    HazardModel(
      id: 'haz_104',
      ticketNumber: 'CF-2026-000030',
      title: 'Open manhole on footpath',
      category: CivicCategory.defaultCategories[0], // Infrastructure/Roads
      status: ComplaintStatus.assigned,
      latitude: 12.9770,
      longitude: 77.5960,
      address: '7th Avenue, Commercial Zone',
      landmark: 'Near Market Road',
      ward: 'Ward 14',
      severity: HazardSeverity.critical,
      upvotes: 32,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    // 5. Street Light - Resolved (linked to cmp_105 / CF-2026-000011)
    HazardModel(
      id: 'haz_105',
      complaintId: 'cmp_105',
      ticketNumber: 'CF-2026-000011',
      title: 'Water leakage near pavement',
      category: CivicCategory.defaultCategories[1], // Water
      status: ComplaintStatus.resolved,
      latitude: 12.9780,
      longitude: 77.5910,
      address: '8th Main Road, Market Area',
      landmark: 'Near Market Road',
      ward: 'Ward 14',
      severity: HazardSeverity.low,
      imageUrl: 'https://images.unsplash.com/photo-1584467735815-f778f274e296?w=500',
      upvotes: 38,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    // 6. Drainage - Assigned (linked to cmp_104 / CF-2026-000015)
    HazardModel(
      id: 'haz_106',
      complaintId: 'cmp_104',
      ticketNumber: 'CF-2026-000015',
      title: 'Blocked drainage',
      category: CivicCategory.defaultCategories[5], // Drainage
      status: ComplaintStatus.assigned,
      latitude: 12.9730,
      longitude: 77.5920,
      address: '2nd Avenue, Block C',
      landmark: 'Near Residential Block',
      ward: 'Ward 14',
      severity: HazardSeverity.high,
      upvotes: 18,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    // 7. Street Light - Reported (linked to cmp_101 / CF-2026-000024)
    HazardModel(
      id: 'haz_107',
      complaintId: 'cmp_101',
      ticketNumber: 'CF-2026-000024',
      title: 'Broken street light near park',
      category: CivicCategory.defaultCategories[4], // Street Lights
      status: ComplaintStatus.reported,
      latitude: 12.9716,
      longitude: 77.5946,
      address: '4th Cross Road',
      landmark: 'Near Bus Stop',
      ward: 'Ward 14',
      severity: HazardSeverity.low,
      upvotes: 4,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    // 8. Other - Verified
    HazardModel(
      id: 'haz_108',
      ticketNumber: 'CF-2026-000035',
      title: 'Illegal hoarding obstructing signal view',
      category: CivicCategory.defaultCategories[8], // Other / General
      status: ComplaintStatus.verified,
      latitude: 12.9760,
      longitude: 77.6020,
      address: 'Main Highway Junction',
      landmark: 'Near Traffic Signal',
      ward: 'Ward 14',
      severity: HazardSeverity.medium,
      upvotes: 6,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  static List<NotificationModel> _createInitialNotifications() => [
    // 1. Unread - Complaint Verified (CF-2026-000018)
    NotificationModel(
      id: 'notif_1',
      userId: 'user_citizen_001',
      title: 'Complaint Verified',
      message: 'Your complaint CF-2026-000018 has been verified by the municipal authority.',
      type: NotificationType.complaintVerified,
      complaintId: 'cmp_103',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    // 2. Unread - Complaint Assigned (CF-2026-000015)
    NotificationModel(
      id: 'notif_2',
      userId: 'user_citizen_001',
      title: 'Complaint Assigned',
      message: 'Your complaint CF-2026-000015 has been assigned to Drainage Squad 2.',
      type: NotificationType.complaintAssigned,
      complaintId: 'cmp_104',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    // 3. Read - Complaint Status Changed (CF-2026-000021)
    NotificationModel(
      id: 'notif_3',
      userId: 'user_citizen_001',
      title: 'Complaint Update',
      message: 'Work is currently underway on complaint CF-2026-000021.',
      type: NotificationType.complaintStatusChanged,
      complaintId: 'cmp_102',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    // 4. Read - Complaint Resolved (CF-2026-000011)
    NotificationModel(
      id: 'notif_4',
      userId: 'user_citizen_001',
      title: 'Complaint Resolved',
      message: 'Your complaint CF-2026-000011 has been marked as resolved.',
      type: NotificationType.complaintResolved,
      complaintId: 'cmp_105',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    // 5. Read - Complaint Submitted (CF-2026-000024)
    NotificationModel(
      id: 'notif_5',
      userId: 'user_citizen_001',
      title: 'Complaint Submitted',
      message: 'Your complaint CF-2026-000024 has been registered successfully.',
      type: NotificationType.complaintSubmitted,
      complaintId: 'cmp_101',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    // 6. Read - General Civic Info
    NotificationModel(
      id: 'notif_6',
      userId: 'user_citizen_001',
      title: 'Welcome to CivicFix',
      message: 'Thank you for helping improve your community. You can report civic issues and track their resolution in real time.',
      type: NotificationType.generalCivic,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  final List<CivicRewardItem> rewardsCatalog = const [
    CivicRewardItem(
      id: 'rew_1',
      title: 'Metro Pass Discount (20%)',
      description: 'Get 20% off on your next monthly BMTC/Metro smart card recharge.',
      pointsCost: 500,
      partner: 'City Transport Corp',
      expiryDate: 'Dec 31, 2026',
      icon: Icons.directions_subway_rounded,
    ),
    CivicRewardItem(
      id: 'rew_2',
      title: 'Plant a Tree in Your Name',
      description: 'Municipal Parks Dept will plant an indigenous sapling with your nameplate in Ward 14.',
      pointsCost: 350,
      partner: 'Parks & Recreation Dept',
      expiryDate: 'Ongoing Initiative',
      icon: Icons.park_rounded,
    ),
    CivicRewardItem(
      id: 'rew_3',
      title: 'Community Center Pass',
      description: 'One-day complimentary access to city sports complex & indoor badminton court.',
      pointsCost: 200,
      partner: 'Civic Sports Club',
      expiryDate: 'Nov 30, 2026',
      icon: Icons.sports_tennis_rounded,
    ),
  ];

  List<CivicBadge> get allBadges => achievements;
}
