import 'package:flutter/foundation.dart';
import '../local/mock_data_source.dart';
import '../models/reward_model.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Future<UserModel> getCurrentUser();
  ValueListenable<UserModel> getUserListenable();
  Future<UserModel> updateUserProfile({
    String? fullName,
    String? email,
    String? phone,
    String? wardNumber,
    String? languageCode,
    String? avatarUrl,
  });
  Future<List<CivicRewardItem>> getRewardsCatalog();
  Future<List<CivicAchievement>> getUserBadges();
  Future<bool> redeemReward(String rewardId);
}

class MockUserRepository implements UserRepository {
  static final MockUserRepository _instance = MockUserRepository._internal();
  factory MockUserRepository() => _instance;
  MockUserRepository._internal();

  final MockDataSource _dataSource = MockDataSource();

  @override
  Future<UserModel> getCurrentUser() async {
    return _dataSource.currentUser;
  }

  @override
  ValueListenable<UserModel> getUserListenable() {
    return _dataSource.userListenable;
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
    final updated = _dataSource.currentUser.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
      wardNumber: wardNumber,
      languageCode: languageCode,
      avatarUrl: avatarUrl,
    );
    _dataSource.updateCurrentUser(updated);
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
      if (_dataSource.currentUser.civicPoints >= reward.pointsCost) {
        final updatedPoints = _dataSource.currentUser.civicPoints - reward.pointsCost;
        _dataSource.updateCurrentUser(
          _dataSource.currentUser.copyWith(civicPoints: updatedPoints),
        );
        return true;
      }
    } catch (_) {}
    return false;
  }
}

