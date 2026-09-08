/// Local persistence model for application preferences stored in Hive.
class SettingsLocalModel {
  final String themeMode; // 'system' | 'light' | 'dark'
  final String languageCode; // 'en' | 'hi' | 'mr'
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool soundEnabled;
  final bool locationPermissionRequested;
  final int? lastSyncEpochMs;

  const SettingsLocalModel({
    this.themeMode = 'system',
    this.languageCode = 'en',
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.soundEnabled = true,
    this.locationPermissionRequested = false,
    this.lastSyncEpochMs,
  });

  SettingsLocalModel copyWith({
    String? themeMode,
    String? languageCode,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? soundEnabled,
    bool? locationPermissionRequested,
    int? lastSyncEpochMs,
  }) {
    return SettingsLocalModel(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      locationPermissionRequested: locationPermissionRequested ?? this.locationPermissionRequested,
      lastSyncEpochMs: lastSyncEpochMs ?? this.lastSyncEpochMs,
    );
  }
}
