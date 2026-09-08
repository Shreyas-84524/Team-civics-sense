import 'package:flutter/foundation.dart';
import '../local/hive/hive_boxes.dart';
import '../local/hive/hive_storage_service.dart';
import '../local/local_storage_service.dart';
import '../local/mock_data_source.dart';
import '../local/models/reward_local_model.dart';
import '../models/reward_model.dart';
import 'rewards_repository.dart';

/// Hive-backed cache-aware repository for gamification, rewards, and achievements.
class HiveRewardsRepository implements RewardsRepository {
  final LocalStorageService _storage;
  final MockDataSource _dataSource;
  DateTime? _lastCachedAt;
  final List<CivicAchievement> _inMemoryAchievements = [];
  final List<CivicRewardItem> _inMemoryPerks = [];

  HiveRewardsRepository({
    LocalStorageService? storage,
    MockDataSource? dataSource,
  })  : _storage = storage ?? HiveStorageService.instance,
        _dataSource = dataSource ?? MockDataSource() {
    _initFromCache();
  }

  DateTime? get lastCachedAt => _lastCachedAt;

  Future<void> _initFromCache() async {
    if (_storage.isInitialized) {
      try {
        final achievements = await _storage.getAll<AchievementLocalModel>(HiveBoxes.rewards);
        if (achievements.isNotEmpty) {
          _inMemoryAchievements
            ..clear()
            ..addAll(achievements.map((e) => e.toDomain()));
          _lastCachedAt = DateTime.now();
        } else {
          await cacheAchievements(_dataSource.achievements);
          await cacheRewardsCatalog(_dataSource.rewardsCatalog);
        }
      } catch (e) {
        debugPrint('Warning: HiveRewardsRepository failed reading cache: $e');
      }
    }
  }

  /// Bulk cache achievements snapshot from server into Hive.
  Future<void> cacheAchievements(List<CivicAchievement> achievements) async {
    if (_storage.isInitialized) {
      try {
        final Map<String, AchievementLocalModel> map = {
          for (final a in achievements) 'ach_${a.id}': AchievementLocalModel.fromDomain(a),
        };
        await _storage.putAll<AchievementLocalModel>(HiveBoxes.rewards, map);
        _lastCachedAt = DateTime.now();
      } catch (e) {
        debugPrint('Warning: HiveRewardsRepository.cacheAchievements fallback: $e');
      }
    }

    _inMemoryAchievements
      ..clear()
      ..addAll(achievements);
  }

  /// Bulk cache rewards catalog snapshot from server into Hive.
  Future<void> cacheRewardsCatalog(List<CivicRewardItem> items) async {
    if (_storage.isInitialized) {
      try {
        final Map<String, RewardItemLocalModel> map = {
          for (final r in items) 'rew_${r.id}': RewardItemLocalModel.fromDomain(r),
        };
        await _storage.putAll<RewardItemLocalModel>(HiveBoxes.rewards, map);
        _lastCachedAt = DateTime.now();
      } catch (e) {
        debugPrint('Warning: HiveRewardsRepository.cacheRewardsCatalog fallback: $e');
      }
    }

    _inMemoryPerks
      ..clear()
      ..addAll(items);
  }

  @override
  Future<RewardDataModel> getRewardData(String userId) async {
    final user = _dataSource.currentUser;
    final achievements = await getAchievements();
    final perks = await getRewardsCatalog();

    return RewardDataModel(
      userId: user.id,
      currentPoints: user.civicPoints,
      nextMilestoneTarget: 1000,
      reportsSubmitted: user.reportsSubmitted,
      reportsResolved: user.reportsResolved,
      achievements: achievements,
      perks: perks,
    );
  }

  @override
  Future<List<CivicAchievement>> getAchievements() async {
    if (_storage.isInitialized) {
      try {
        final all = await _storage.getAll<AchievementLocalModel>(HiveBoxes.rewards);
        if (all.isNotEmpty) {
          return all.map((e) => e.toDomain()).toList();
        }
      } catch (e) {
        debugPrint('Warning: HiveRewardsRepository.getAchievements reading error: $e');
      }
    }

    return _inMemoryAchievements.isNotEmpty
        ? List.unmodifiable(_inMemoryAchievements)
        : _dataSource.achievements;
  }

  @override
  Future<CivicAchievement?> getAchievementById(String id) async {
    if (_storage.isInitialized) {
      try {
        final cached = await _storage.get<AchievementLocalModel>(HiveBoxes.rewards, 'ach_$id');
        if (cached != null) {
          return cached.toDomain();
        }
      } catch (e) {
        debugPrint('Warning: HiveRewardsRepository.getAchievementById reading error: $e');
      }
    }

    try {
      final list = _inMemoryAchievements.isNotEmpty ? _inMemoryAchievements : _dataSource.achievements;
      return list.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CivicRewardItem>> getRewardsCatalog() async {
    if (_storage.isInitialized) {
      try {
        final all = await _storage.getAll<RewardItemLocalModel>(HiveBoxes.rewards);
        if (all.isNotEmpty) {
          return all.map((e) => e.toDomain()).toList();
        }
      } catch (e) {
        debugPrint('Warning: HiveRewardsRepository.getRewardsCatalog reading error: $e');
      }
    }

    return _inMemoryPerks.isNotEmpty
        ? List.unmodifiable(_inMemoryPerks)
        : _dataSource.rewardsCatalog;
  }

  @override
  Future<bool> redeemReward(String rewardId) async {
    try {
      final catalog = await getRewardsCatalog();
      final reward = catalog.firstWhere((r) => r.id == rewardId);
      if (_dataSource.currentUser.civicPoints >= reward.pointsCost) {
        final updatedPoints = _dataSource.currentUser.civicPoints - reward.pointsCost;
        _dataSource.currentUser = _dataSource.currentUser.copyWith(civicPoints: updatedPoints);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
