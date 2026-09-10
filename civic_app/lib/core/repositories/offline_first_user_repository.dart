import 'dart:async';
import 'package:flutter/foundation.dart';
import '../auth/auth_service_locator.dart';
import '../firebase/firestore/firebase_rewards_data_source.dart';
import '../firebase/firestore/firebase_user_data_source.dart';
import '../models/reward_model.dart';
import '../models/user_model.dart';
import '../network/connectivity_service.dart';
import 'hive_user_repository.dart';
import 'user_repository.dart';

/// Offline-first cache-aware repository for the citizen user profile and rewards.
class OfflineFirstUserRepository implements UserRepository {
  final HiveUserRepository _localRepo;
  final FirebaseUserDataSource _remoteDataSource;
  final FirebaseRewardsDataSource _rewardsDataSource;
  final ConnectivityService _connectivity;
  final String? _currentUserId;

  OfflineFirstUserRepository({
    HiveUserRepository? localRepository,
    FirebaseUserDataSource? remoteDataSource,
    FirebaseRewardsDataSource? rewardsDataSource,
    ConnectivityService? connectivity,
    String? currentUserId,
  })  : _localRepo = localRepository ?? HiveUserRepository(),
        _remoteDataSource = remoteDataSource ?? FirebaseUserDataSource(),
        _rewardsDataSource = rewardsDataSource ?? FirebaseRewardsDataSource(),
        _connectivity = connectivity ?? AppConnectivityService(),
        _currentUserId = currentUserId;

  String get _activeUserId {
    final current = _currentUserId;
    if (current != null && current.isNotEmpty) {
      return current;
    }
    return AuthServiceLocator.citizenAuth.currentUid ?? '';
  }

  @override
  Future<UserModel> getCurrentUser() async {
    // 1. Return cached user profile from Hive
    final local = await _localRepo.getCurrentUser();

    // 2. If online, fetch remote Firestore profile & merge
    final uid = _activeUserId;
    if (_connectivity.isOnline && uid.isNotEmpty) {
      try {
        final remote = await _remoteDataSource.getUserById(uid);
        if (remote != null) {
          final merged = _mergeUser(local, remote);
          await _localRepo.cacheUser(merged);
          return merged;
        }
      } catch (e) {
        debugPrint('[OfflineFirstUserRepository] Remote user fetch failed (using cache): $e');
      }
    }

    return local;
  }

  @override
  ValueListenable<UserModel> getUserListenable() {
    return _localRepo.getUserListenable();
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
    // 1. Update local Hive cache immediately
    final updated = await _localRepo.updateUserProfile(
      fullName: fullName,
      email: email,
      phone: phone,
      wardNumber: wardNumber,
      languageCode: languageCode,
      avatarUrl: avatarUrl,
    );

    // 2. If online, sync to Cloud Firestore
    final uid = _activeUserId;
    if (_connectivity.isOnline && uid.isNotEmpty) {
      try {
        await _remoteDataSource.updateCitizenProfile(
          uid,
          fullName: fullName,
          phone: phone,
          wardNumber: wardNumber,
          languageCode: languageCode,
          avatarUrl: avatarUrl,
        );
      } catch (e) {
        debugPrint('[OfflineFirstUserRepository] Remote profile update failed (cached locally): $e');
      }
    }

    return updated;
  }

  @override
  Future<List<CivicRewardItem>> getRewardsCatalog() async {
    return _localRepo.getRewardsCatalog();
  }

  @override
  Future<List<CivicAchievement>> getUserBadges() async {
    final local = await _localRepo.getUserBadges();
    if (_connectivity.isOnline) {
      try {
        final remote = await _rewardsDataSource.getAchievements();
        if (remote.isNotEmpty) return remote;
      } catch (_) {}
    }
    return local;
  }

  @override
  Future<bool> redeemReward(String rewardId) async {
    // Redeem in local cache first
    final success = await _localRepo.redeemReward(rewardId);
    final uid = _activeUserId;
    if (success && _connectivity.isOnline && uid.isNotEmpty) {
      try {
        await _remoteDataSource.updateCitizenProfile(uid);
      } catch (_) {}
    }
    return success;
  }

  @override
  Future<void> clearUserCache() async {
    await _localRepo.clearUserCache();
  }

  UserModel _mergeUser(UserModel local, UserModel remote) {
    return local.copyWith(
      fullName: remote.fullName.isNotEmpty ? remote.fullName : local.fullName,
      email: remote.email.isNotEmpty ? remote.email : local.email,
      phone: remote.phone.isNotEmpty ? remote.phone : local.phone,
      wardNumber: remote.wardNumber.isNotEmpty ? remote.wardNumber : local.wardNumber,
      languageCode: remote.languageCode.isNotEmpty ? remote.languageCode : local.languageCode,
      avatarUrl: remote.avatarUrl ?? local.avatarUrl,
      civicPoints: remote.civicPoints > local.civicPoints ? remote.civicPoints : local.civicPoints,
      reportsSubmitted: remote.reportsSubmitted > local.reportsSubmitted ? remote.reportsSubmitted : local.reportsSubmitted,
      reportsResolved: remote.reportsResolved > local.reportsResolved ? remote.reportsResolved : local.reportsResolved,
    );
  }
}
