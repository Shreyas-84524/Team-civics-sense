/// Centralized registry of Cloud Firestore collection names, sub-collections,
/// and Firebase Storage folder paths across CivicFix.
class FirestoreCollections {
  FirestoreCollections._();

  /// Primary complaints collection.
  static const String complaints = 'complaints';

  /// Audit trail and status updates timeline subcollection / collection.
  static const String complaintUpdates = 'complaint_updates';

  /// Citizen profiles collection.
  static const String users = 'users';

  /// Government officer and administrator profiles collection.
  static const String govtUsers = 'govt_users';

  /// Live geotagged community hazards collection.
  static const String hazards = 'hazards';

  /// Citizen and broadcast notifications collection.
  static const String notifications = 'notifications';

  /// Gamification rewards and perks catalog collection.
  static const String rewards = 'rewards';

  /// Municipal departments collection.
  static const String departments = 'departments';

  /// Municipal officers and maintenance personnel collection.
  static const String officers = 'officers';
}

/// Firebase Cloud Storage path prefixes, limits, and directory hierarchies.
class FirebaseStoragePaths {
  FirebaseStoragePaths._();

  /// Path prefix for citizen grievance photographic evidence.
  /// Example: 'complaint_evidence/{complaintId}/{filename}.jpg'
  static const String complaintEvidence = 'complaint_evidence';

  /// Alternative structured path prefix for complaint evidence images.
  /// Example: 'complaints/{complaintId}/images/{filename}.jpg'
  static const String complaintsPrefix = 'complaints';

  /// Path prefix for citizen user profile avatars.
  /// Example: 'user_avatars/{userId}/{filename}.jpg'
  static const String userAvatars = 'user_avatars';

  /// Path prefix for government officer profile avatars.
  /// Example: 'govt_avatars/{officerId}/{filename}.jpg'
  static const String govtAvatars = 'govt_avatars';

  /// Maximum allowed evidence file size in bytes (10 MB).
  static const int maxEvidenceFileSize = 10 * 1024 * 1024;

  /// Maximum allowed avatar file size in bytes (5 MB).
  static const int maxAvatarFileSize = 5 * 1024 * 1024;

  /// Minimum valid file size in bytes to prevent empty/corrupted uploads.
  static const int minValidFileSize = 100;

  /// Allowed MIME content types for photographic evidence uploads.
  static const List<String> allowedEvidenceMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];

  /// Allowed image file extensions.
  static const List<String> allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  /// Helper to format full evidence storage path for a complaint.
  static String complaintEvidencePath(String complaintId, String fileName) {
    final sanitizedFileName = sanitizeFileName(fileName);
    return '$complaintEvidence/$complaintId/$sanitizedFileName';
  }

  /// Helper to format structured complaint image storage path.
  static String complaintImagePath(String complaintId, String fileName) {
    final sanitizedFileName = sanitizeFileName(fileName);
    return '$complaintsPrefix/$complaintId/images/$sanitizedFileName';
  }

  /// Helper to format avatar storage path.
  static String userAvatarPath(String userId, String fileName) {
    final sanitizedFileName = sanitizeFileName(fileName);
    return '$userAvatars/$userId/$sanitizedFileName';
  }

  /// Helper to format government officer avatar storage path.
  static String govtAvatarPath(String officerId, String fileName) {
    final sanitizedFileName = sanitizeFileName(fileName);
    return '$govtAvatars/$officerId/$sanitizedFileName';
  }

  /// Sanitizes file names to remove special characters, spaces, and path traversal sequences.
  static String sanitizeFileName(String rawName) {
    // Strip directory traversal components
    var name = rawName.split(RegExp(r'[\\/]')).last.trim();
    // Replace non-alphanumeric (except standard dots, dashes, underscores) with underscores
    name = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    // Ensure it doesn't start with a dot
    if (name.startsWith('.')) {
      name = 'file$name';
    }
    return name.isEmpty ? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg' : name;
  }
}
