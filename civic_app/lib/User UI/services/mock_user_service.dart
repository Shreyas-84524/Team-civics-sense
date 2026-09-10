import '../../core/models/user_model.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/repositories/user_repository.dart';

/// User state service for the Citizen UI.
class MockUserService {
  static final MockUserService _instance = MockUserService._internal();
  factory MockUserService() => _instance;
  MockUserService._internal();

  UserRepository get _userRepository => RepositoryLocator.userRepository;
  bool isLoggedIn = true;

  Future<UserModel> getUser() => _userRepository.getCurrentUser();

  Future<void> login(String email, String password) async {
    isLoggedIn = true;
  }

  Future<void> logout() async {
    isLoggedIn = false;
  }
}
