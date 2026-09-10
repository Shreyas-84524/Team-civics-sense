import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reward_model.dart';
import '../errors/firestore_error_handler.dart';
import '../firebase_constants.dart';
import '../mappers/reward_firestore_mapper.dart';

/// Remote Firestore Data Source for reading Server-Authoritative Gamification Rewards & Badges.
class FirebaseRewardsDataSource {
  final FirebaseFirestore? _firestore;

  FirebaseRewardsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rewardsRef =>
      _db.collection(FirestoreCollections.rewards);

  /// Fetches a citizen's authoritative reward summary, civic points, and unlocked achievements.
  Future<RewardDataModel> getRewardData(String userId) async {
    try {
      final doc = await _rewardsRef.doc(userId).get();
      if (!doc.exists || doc.data() == null) {
        return RewardDataModel(
          userId: userId,
          currentPoints: 20,
          nextMilestoneTarget: 1000,
          reportsSubmitted: 0,
          reportsResolved: 0,
          achievements: CivicAchievement.defaultAchievements(),
        );
      }

      return RewardFirestoreMapper.fromFirestore(
        documentId: doc.id,
        data: doc.data()!,
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Retrieves the standard catalog of Civic Achievements.
  Future<List<CivicAchievement>> getAchievements() async {
    return CivicAchievement.defaultAchievements();
  }
}
