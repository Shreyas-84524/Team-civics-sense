/// Notification Preferences for Government Officers.
class GovtNotificationSettings {
  final bool newComplaintAlerts;
  final bool assignmentAlerts;
  final bool statusUpdateAlerts;
  final bool highPriorityAlerts;
  final bool systemNotifications;

  const GovtNotificationSettings({
    this.newComplaintAlerts = true,
    this.assignmentAlerts = true,
    this.statusUpdateAlerts = true,
    this.highPriorityAlerts = true,
    this.systemNotifications = true,
  });

  GovtNotificationSettings copyWith({
    bool? newComplaintAlerts,
    bool? assignmentAlerts,
    bool? statusUpdateAlerts,
    bool? highPriorityAlerts,
    bool? systemNotifications,
  }) {
    return GovtNotificationSettings(
      newComplaintAlerts: newComplaintAlerts ?? this.newComplaintAlerts,
      assignmentAlerts: assignmentAlerts ?? this.assignmentAlerts,
      statusUpdateAlerts: statusUpdateAlerts ?? this.statusUpdateAlerts,
      highPriorityAlerts: highPriorityAlerts ?? this.highPriorityAlerts,
      systemNotifications: systemNotifications ?? this.systemNotifications,
    );
  }

  Map<String, dynamic> toMap() => {
        'newComplaintAlerts': newComplaintAlerts,
        'assignmentAlerts': assignmentAlerts,
        'statusUpdateAlerts': statusUpdateAlerts,
        'highPriorityAlerts': highPriorityAlerts,
        'systemNotifications': systemNotifications,
      };
}

/// Supported Languages for Government Administration Portal.
enum GovtLanguage {
  english('English', 'English (Default)', 'en'),
  hindi('Hindi', 'हिन्दी (Hindi)', 'hi'),
  marathi('Marathi', 'मराठी (Marathi)', 'mr');

  final String label;
  final String localizedDisplay;
  final String code;

  const GovtLanguage(this.label, this.localizedDisplay, this.code);
}

/// Appearance Theme Mode.
enum GovtPortalThemeMode {
  system('System Default', 'Matches your OS appearance'),
  light('Light Mode', 'Clean daylight municipal theme'),
  dark('Dark Mode', 'High-contrast low-light operations');

  final String title;
  final String subtitle;

  const GovtPortalThemeMode(this.title, this.subtitle);
}

/// Layout Density Options for Government Officers.
enum GovtLayoutDensity {
  comfortable('Comfortable', 'Spacious tables and cards with generous padding'),
  compact('Compact', 'High information density for rapid multi-tasking');

  final String title;
  final String subtitle;

  const GovtLayoutDensity(this.title, this.subtitle);
}

/// Complete Government Portal Settings Container.
class GovtSettingsModel {
  final GovtNotificationSettings notifications;
  final GovtLanguage language;
  final GovtPortalThemeMode themeMode;
  final GovtLayoutDensity density;

  const GovtSettingsModel({
    this.notifications = const GovtNotificationSettings(),
    this.language = GovtLanguage.english,
    this.themeMode = GovtPortalThemeMode.system,
    this.density = GovtLayoutDensity.comfortable,
  });

  GovtSettingsModel copyWith({
    GovtNotificationSettings? notifications,
    GovtLanguage? language,
    GovtPortalThemeMode? themeMode,
    GovtLayoutDensity? density,
  }) {
    return GovtSettingsModel(
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      density: density ?? this.density,
    );
  }
}
