import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Govt UI/models/govt_user_model.dart';
import '../../models/user_model.dart';
import '../errors/firestore_error_handler.dart';
import '../firebase_constants.dart';
import '../mappers/user_firestore_mapper.dart';

/// Remote Firestore Data Source for managing Citizen and Government User profiles.
class FirebaseUserDataSource {
  final FirebaseFirestore? _firestore;

  FirebaseUserDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection(FirestoreCollections.users);

  /// Fetches a citizen profile document by User ID.
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserFirestoreMapper.citizenFromFirestore(
        documentId: doc.id,
        data: doc.data()!,
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Fetches a government officer profile document by User ID.
  Future<GovtUserModel?> getGovtUserById(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserFirestoreMapper.govtUserFromFirestore(
        documentId: doc.id,
        data: doc.data()!,
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Creates a new citizen user profile document during registration.
  Future<UserModel> createCitizenProfile(UserModel user) async {
    try {
      final data = UserFirestoreMapper.citizenToFirestore(user, isCreate: true);
      await _usersRef.doc(user.id).set(data);
      return user;
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Updates allowed profile attributes for a citizen user.
  Future<UserModel> updateCitizenProfile(
    String userId, {
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? languageCode,
    String? wardNumber,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (fullName != null) updates['fullName'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (languageCode != null) updates['languageCode'] = languageCode;
      if (wardNumber != null) updates['wardNumber'] = wardNumber;

      await _usersRef.doc(userId).update(updates);

      final updated = await getUserById(userId);
      return updated ?? UserModel(
        id: userId,
        fullName: fullName ?? '',
        email: '',
        phone: phone ?? '',
        avatarUrl: avatarUrl,
        languageCode: languageCode ?? 'en',
        wardNumber: wardNumber ?? 'Ward 14 (Central)',
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  // ===========================================================================
  // FCM DEVICE TOKEN MANAGEMENT (Prompt 9)
  // ===========================================================================

  /// Subcollection path helper for user device tokens.
  CollectionReference<Map<String, dynamic>> _userDevicesRef(String userId) =>
      _usersRef.doc(userId).collection('devices');

  /// Sanitizes FCM token for use as a Firestore document ID.
  static String sanitizeTokenDocId(String token) {
    if (token.isEmpty) return 'default_device';
    // Use alphanumeric + underscores or hash if long
    return token.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  /// Registers or refreshes an FCM device token for a specific citizen or govt user.
  Future<void> registerDeviceToken(
    String userId,
    String token, {
    String platform = 'android',
    String? appVersion,
  }) async {
    if (userId.isEmpty || token.isEmpty) return;
    try {
      final docId = sanitizeTokenDocId(token);
      final docRef = _userDevicesRef(userId).doc(docId);

      await docRef.set({
        'token': token,
        'platform': platform,
        'appVersion': ?appVersion,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Unregisters an FCM device token upon user sign-out or token invalidation.
  Future<void> unregisterDeviceToken(String userId, String token) async {
    if (userId.isEmpty || token.isEmpty) return;
    try {
      final docId = sanitizeTokenDocId(token);
      await _userDevicesRef(userId).doc(docId).delete();
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Retrieves all active device tokens registered to a user.
  Future<List<String>> getDeviceTokens(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final snapshot = await _userDevicesRef(userId).get();
      return snapshot.docs
          .map((doc) => doc.data()['token'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }
}

