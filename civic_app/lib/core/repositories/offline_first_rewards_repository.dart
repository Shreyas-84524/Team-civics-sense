import 'dart:async';
import 'package:flutter/foundation.dart';
import '../firebase/firestore/firebase_rewards_data_source.dart';
import '../models/reward_model.dart';
import '../network/connectivity_service.dart';
import 'hive_rewards_repository.dart';
import 'rewards_repository.dart';

/// Offline-first cache-aware repository for gamification, rewards, and achievements.
class OfflineFirstRewardsRepository implements RewardsRepository {
  final HiveRewardsRepository _localRepo;
  final FirebaseRewardsDataSource _remoteDataSource;
  final ConnectivityService _connectivity;

  OfflineFirstRewardsRepository({
    HiveRewardsRepository? localRepository,
    FirebaseRewardsDataSource? remoteDataSource,
    ConnectivityService? connectivity,
  })  : _localRepo = localRepository ?? HiveRewardsRepository(),
        _remoteDataSource = remoteDataSource ?? FirebaseRewardsDataSource(),
        _connectivity = connectivity ?? AppConnectivityService();

  @override
  Future<RewardDataModel> getRewardData(String userId) async {
    final localData = await _localRepo.getRewardData(userId);

    if (_connectivity.isOnline) {
      try {
        final remoteReward = await _remoteDataSource.getRewardData(userId);
        if (remoteReward.achievements.isNotEmpty) {
          await _localRepo.cacheAchievements(remoteReward.achievements);
        }

        final perks = await _localRepo.getRewardsCatalog();

        return RewardDataModel(
          userId: localData.userId,
          currentPoints: remoteReward.currentPoints > localData.currentPoints
              ? remoteReward.currentPoints
              : localData.currentPoints,
          nextMilestoneTarget: remoteReward.nextMilestoneTarget,
          reportsSubmitted: remoteReward.reportsSubmitted > localData.reportsSubmitted
              ? remoteReward.reportsSubmitted
              : localData.reportsSubmitted,
          reportsResolved: remoteReward.reportsResolved > localData.reportsResolved
              ? remoteReward.reportsResolved
              : localData.reportsResolved,
          achievements: remoteReward.achievements.isNotEmpty
              ? remoteReward.achievements
              : localData.achievements,
          perks: perks,
        );
      } catch (e) {
        debugPrint('[OfflineFirstRewardsRepository] Remote reward data fetch failed (using cache): $e');
      }
    }

    return localData;
  }

  @override
  Future<List<CivicAchievement>> getAchievements() async {
    final local = await _localRepo.getAchievements();

    if (_connectivity.isOnline) {
      try {
        final remote = await _remoteDataSource.getAchievements();
        if (remote.isNotEmpty) {
          await _localRepo.cacheAchievements(remote);
          return remote;
        }
      } catch (_) {}
    }

    return local;
  }

  @override
  Future<CivicAchievement?> getAchievementById(String id) async {
    final local = await _localRepo.getAchievementById(id);
    if (local != null) return local;

    final all = await getAchievements();
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CivicRewardItem>> getRewardsCatalog() async {
    return _localRepo.getRewardsCatalog();
  }

  @override
  Future<bool> redeemReward(String rewardId) async {
    return _localRepo.redeemReward(rewardId);
  }
}
