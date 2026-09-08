/// Centralized registry of Hive box names and constants used across CivicFix.
class HiveBoxes {
  HiveBoxes._();

  /// Complaints box storing [ComplaintLocalModel] keyed by complaint ID or ticket number.
  static const String complaints = 'complaints';

  /// Complaint updates / status timeline audit box storing [TimelineEventLocalModel].
  static const String complaintUpdates = 'complaint_updates';

  /// Queue for pending offline operations and mutations to be synchronized.
  static const String pendingSync = 'pending_sync';

  /// In-app citizen notifications box storing [NotificationLocalModel].
  static const String notifications = 'notifications';

  /// Current user profile and session metadata box storing [UserLocalModel].
  static const String user = 'user';

  /// Gamification achievements, badges, and perks catalog box.
  static const String rewards = 'rewards';

  /// Local app settings, theme, and language preferences box.
  static const String settings = 'settings';

  /// Civic hazards cache for the live hazard map.
  static const String hazards = 'hazards';

  /// List of all canonical box names managed by CivicFix.
  static const List<String> allBoxes = [
    complaints,
    complaintUpdates,
    pendingSync,
    notifications,
    user,
    rewards,
    settings,
    hazards,
  ];

  /// Standard key constants used inside singleton boxes.
  static const String currentUserKey = 'current_user_profile';
  static const String appSettingsKey = 'app_settings_config';
  static const String rewardsCatalogKey = 'rewards_catalog_list';
  static const String userAchievementsKey = 'user_achievements_list';
}
