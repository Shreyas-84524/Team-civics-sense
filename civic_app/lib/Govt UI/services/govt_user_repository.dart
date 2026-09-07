import 'package:flutter/foundation.dart';
import '../models/govt_settings_model.dart';
import '../models/govt_user_model.dart';
import 'govt_auth_service.dart';

/// Contract for Government User Profile & Settings Management.
abstract class GovernmentUserRepository {
  ValueListenable<GovtUserModel?> get profileListenable;
  ValueListenable<GovtSettingsModel> get settingsListenable;
  GovtUserModel? get currentProfile;
  GovtSettingsModel get currentSettings;

  Future<GovtUserModel?> getProfile();

  Future<GovtUserModel> updateProfile({
    required String fullName,
    required String phone,
    required String designation,
    String? avatarUrl,
  });

  Future<GovtSettingsModel> getSettings();
  Future<GovtSettingsModel> updateNotificationSettings(GovtNotificationSettings settings);
  Future<GovtSettingsModel> updateLanguage(GovtLanguage language);
  Future<GovtSettingsModel> updateAppearance({
    GovtPortalThemeMode? themeMode,
    GovtLayoutDensity? density,
  });
}

/// In-Memory Mock Implementation of GovernmentUserRepository.
class MockGovernmentUserRepository implements GovernmentUserRepository {
  static final MockGovernmentUserRepository _instance = MockGovernmentUserRepository._internal();
  factory MockGovernmentUserRepository() => _instance;

  final GovtAuthService _authService;
  late final ValueNotifier<GovtSettingsModel> _settingsNotifier;

  MockGovernmentUserRepository._internal({GovtAuthService? authService})
      : _authService = authService ?? MockGovtAuthService() {
    _settingsNotifier = ValueNotifier<GovtSettingsModel>(const GovtSettingsModel());
  }

  @override
  ValueListenable<GovtUserModel?> get profileListenable => _authService.userListenable;

  @override
  ValueListenable<GovtSettingsModel> get settingsListenable => _settingsNotifier;

  @override
  GovtUserModel? get currentProfile => _authService.currentUser;

  @override
  GovtSettingsModel get currentSettings => _settingsNotifier.value;

  @override
  Future<GovtUserModel?> getProfile() async {
    return _authService.currentUser;
  }

  @override
  Future<GovtUserModel> updateProfile({
    required String fullName,
    required String phone,
    required String designation,
    String? avatarUrl,
  }) async {
    final current = _authService.currentUser;
    if (current == null) {
      throw StateError('No active government session to update profile.');
    }

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Officer name cannot be empty.');
    }

    final trimmedPhone = phone.trim();
    if (trimmedPhone.isEmpty) {
      throw ArgumentError('Official phone number cannot be empty.');
    }

    final trimmedDesignation = designation.trim();
    if (trimmedDesignation.isEmpty) {
      throw ArgumentError('Official designation cannot be empty.');
    }

    // Role, Email, EmployeeId, Department, and Organization remain strictly immutable during user edit profile.
    final updated = current.copyWith(
      fullName: trimmedName,
      phone: trimmedPhone,
      designation: trimmedDesignation,
      avatarUrl: avatarUrl ?? current.avatarUrl,
    );

    _authService.updateUser(updated);
    return updated;
  }

  @override
  Future<GovtSettingsModel> getSettings() async {
    return _settingsNotifier.value;
  }

  @override
  Future<GovtSettingsModel> updateNotificationSettings(GovtNotificationSettings settings) async {
    final updated = _settingsNotifier.value.copyWith(notifications: settings);
    _settingsNotifier.value = updated;
    return updated;
  }

  @override
  Future<GovtSettingsModel> updateLanguage(GovtLanguage language) async {
    final updated = _settingsNotifier.value.copyWith(language: language);
    _settingsNotifier.value = updated;
    return updated;
  }

  @override
  Future<GovtSettingsModel> updateAppearance({
    GovtPortalThemeMode? themeMode,
    GovtLayoutDensity? density,
  }) async {
    final updated = _settingsNotifier.value.copyWith(
      themeMode: themeMode ?? _settingsNotifier.value.themeMode,
      density: density ?? _settingsNotifier.value.density,
    );
    _settingsNotifier.value = updated;
    return updated;
  }

  void resetForTesting() {
    _settingsNotifier.value = const GovtSettingsModel();
  }
}
