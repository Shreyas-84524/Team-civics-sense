import 'package:flutter/foundation.dart';
import '../firebase/firestore/firebase_rewards_data_source.dart';
import '../firebase/firestore/firebase_user_data_source.dart';
import '../models/reward_model.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

/// Firebase Firestore remote implementation of [UserRepository].
class FirebaseUserRepository implements UserRepository {
  final FirebaseUserDataSource _userDataSource;
  final FirebaseRewardsDataSource _rewardsDataSource;
  final String _currentUserId;
  final ValueNotifier<UserModel> _userNotifier;

  FirebaseUserRepository({
    FirebaseUserDataSource? userDataSource,
    FirebaseRewardsDataSource? rewardsDataSource,
    String currentUserId = '',
    UserModel? initialUser,
  })  : _userDataSource = userDataSource ?? FirebaseUserDataSource(),
        _rewardsDataSource = rewardsDataSource ?? FirebaseRewardsDataSource(),
        _currentUserId = currentUserId,
        _userNotifier = ValueNotifier<UserModel>(
          initialUser ??
              UserModel(
                id: currentUserId,
                fullName: 'Civic Citizen',
                email: '',
                phone: '',
                civicPoints: 20,
                reportsSubmitted: 0,
                reportsResolved: 0,
              ),
        );

  @override
  Future<UserModel> getCurrentUser() async {
    if (_currentUserId.isNotEmpty) {
      final user = await _userDataSource.getUserById(_currentUserId);
      if (user != null) {
        _userNotifier.value = user;
        return user;
      }
    }
    return _userNotifier.value;
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
    final updated = await _userDataSource.updateCitizenProfile(
      _currentUserId,
      fullName: fullName,
      phone: phone,
      wardNumber: wardNumber,
      languageCode: languageCode,
      avatarUrl: avatarUrl,
    );
    _userNotifier.value = updated;
    return updated;
  }

  @override
  Future<List<CivicRewardItem>> getRewardsCatalog() async {
    return const [];
  }

  @override
  Future<List<CivicAchievement>> getUserBadges() async {
    return _rewardsDataSource.getAchievements();
  }

  @override
  Future<bool> redeemReward(String rewardId) async {
    return false;
  }

  @override
  Future<void> clearUserCache() async {}
}
