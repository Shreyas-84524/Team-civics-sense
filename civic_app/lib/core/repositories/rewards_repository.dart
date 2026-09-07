import '../local/mock_data_source.dart';
import '../models/reward_model.dart';

/// Abstract contract for Rewards & Gamification repository.
abstract class RewardsRepository {
  Future<RewardDataModel> getRewardData(String userId);
  Future<List<CivicAchievement>> getAchievements();
  Future<CivicAchievement?> getAchievementById(String id);
  Future<List<CivicRewardItem>> getRewardsCatalog();
  Future<bool> redeemReward(String rewardId);
}

/// In-memory Mock implementation of RewardsRepository.
class MockRewardsRepository implements RewardsRepository {
  final MockDataSource _dataSource = MockDataSource();

  @override
  Future<RewardDataModel> getRewardData(String userId) async {
    final user = _dataSource.currentUser;
    return RewardDataModel(
      userId: user.id,
      currentPoints: user.civicPoints,
      nextMilestoneTarget: 1000,
      reportsSubmitted: user.reportsSubmitted,
      reportsResolved: user.reportsResolved,
      achievements: _dataSource.achievements,
      perks: _dataSource.rewardsCatalog,
    );
  }

  @override
  Future<List<CivicAchievement>> getAchievements() async {
    return _dataSource.achievements;
  }

  @override
  Future<CivicAchievement?> getAchievementById(String id) async {
    try {
      return _dataSource.achievements.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CivicRewardItem>> getRewardsCatalog() async {
    return _dataSource.rewardsCatalog;
  }

  @override
  Future<bool> redeemReward(String rewardId) async {
    try {
      final reward = _dataSource.rewardsCatalog.firstWhere((r) => r.id == rewardId);
      if (_dataSource.currentUser.civicPoints >= reward.pointsCost) {
        final updatedPoints = _dataSource.currentUser.civicPoints - reward.pointsCost;
        _dataSource.currentUser = _dataSource.currentUser.copyWith(civicPoints: updatedPoints);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
