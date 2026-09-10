import '../firebase/firestore/firebase_rewards_data_source.dart';
import '../models/reward_model.dart';
import 'rewards_repository.dart';

/// Firebase Firestore remote implementation of [RewardsRepository].
class FirebaseRewardsRepository implements RewardsRepository {
  final FirebaseRewardsDataSource _dataSource;

  FirebaseRewardsRepository({FirebaseRewardsDataSource? dataSource})
      : _dataSource = dataSource ?? FirebaseRewardsDataSource();

  @override
  Future<RewardDataModel> getRewardData(String userId) async {
    return _dataSource.getRewardData(userId);
  }

  @override
  Future<List<CivicAchievement>> getAchievements() async {
    return _dataSource.getAchievements();
  }

  @override
  Future<CivicAchievement?> getAchievementById(String id) async {
    final list = await _dataSource.getAchievements();
    try {
      return list.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CivicRewardItem>> getRewardsCatalog() async {
    return const [];
  }

  @override
  Future<bool> redeemReward(String rewardId) async {
    // Reward redemption is managed by authoritative backend logic / Cloud Functions
    return false;
  }
}
