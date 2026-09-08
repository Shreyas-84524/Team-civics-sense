import 'package:flutter/foundation.dart';
import '../local/hive/hive_boxes.dart';
import '../local/hive/hive_storage_service.dart';
import '../local/local_storage_service.dart';
import '../local/mock_data_source.dart';
import '../local/models/user_local_model.dart';
import '../models/reward_model.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

/// Hive-backed cache-aware repository for the citizen user profile and session settings.
class HiveUserRepository implements UserRepository {
  final LocalStorageService _storage;
  final MockDataSource _dataSource;
  final ValueNotifier<UserModel> _userNotifier;
  DateTime? _lastCachedAt;

  HiveUserRepository({
    LocalStorageService? storage,
    MockDataSource? dataSource,
  })  : _storage = storage ?? HiveStorageService.instance,
        _dataSource = dataSource ?? MockDataSource(),
        _userNotifier = ValueNotifier<UserModel>(
          (dataSource ?? MockDataSource()).currentUser,
        ) {
    _initFromCache();
  }

  DateTime? get lastCachedAt => _lastCachedAt;

  Future<void> _initFromCache() async {
    if (_storage.isInitialized) {
      try {
        final cached = await _storage.get<UserLocalModel>(
          HiveBoxes.user,
          HiveBoxes.currentUserKey,
        );
        if (cached != null) {
          final domainUser = cached.toDomain();
          _userNotifier.value = domainUser;
          _dataSource.currentUser = domainUser;
          _lastCachedAt = DateTime.now();
        } else {
          // Prime cache with default user
          await cacheUser(_dataSource.currentUser);
        }
      } catch (e) {
        debugPrint('Warning: HiveUserRepository failed reading user cache: $e');
      }
    }
  }

  /// Store user profile securely in Hive cache.
  Future<void> cacheUser(UserModel user) async {
    // Security check: ensure only public/safe profile attributes are cached
    final localModel = UserLocalModel.fromDomain(user);

    if (_storage.isInitialized) {
      try {
        await _storage.put<UserLocalModel>(
          HiveBoxes.user,
          HiveBoxes.currentUserKey,
          localModel,
        );
        _lastCachedAt = DateTime.now();
      } catch (e) {
        debugPrint('Warning: HiveUserRepository.cacheUser fallback: $e');
      }
    }

    _dataSource.currentUser = user;
    _userNotifier.value = user;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    if (_storage.isInitialized) {
      try {
        final cached = await _storage.get<UserLocalModel>(
          HiveBoxes.user,
          HiveBoxes.currentUserKey,
        );
        if (cached != null) {
          final user = cached.toDomain();
          _userNotifier.value = user;
          return user;
        }
      } catch (e) {
        debugPrint('Warning: HiveUserRepository.getCurrentUser fallback to memory: $e');
      }
    }
    return _dataSource.currentUser;
  }

  @override
  ValueListenable<UserModel> getUserListenable() {
    return _userNotifier;
  }

  @override
  Future<UserModel> updateUserProfile({
    String? fullName,
    String? email,
    String? phone,
    String? wardNumber,
    String? languageCode,
    String? avatarUrl,
  }) async {
    final current = await getCurrentUser();
    final updated = current.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
      wardNumber: wardNumber,
      languageCode: languageCode,
      avatarUrl: avatarUrl,
    );

    await cacheUser(updated);
    return updated;
  }

  @override
  Future<List<CivicRewardItem>> getRewardsCatalog() async {
    return _dataSource.rewardsCatalog;
  }

  @override
  Future<List<CivicAchievement>> getUserBadges() async {
    return _dataSource.achievements;
  }

  @override
  Future<bool> redeemReward(String rewardId) async {
    try {
      final reward = _dataSource.rewardsCatalog.firstWhere((r) => r.id == rewardId);
      final current = await getCurrentUser();
      if (current.civicPoints >= reward.pointsCost) {
        final updatedPoints = current.civicPoints - reward.pointsCost;
        final updated = current.copyWith(civicPoints: updatedPoints);
        await cacheUser(updated);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
