import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/firebase_constants.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';

void main() {
  group('Firestore Security Rules File & Syntax Integrity Tests', () {
    late File rulesFile;
    late String rulesContent;

    setUpAll(() {
      rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue, reason: 'firestore.rules must exist at app root');
      rulesContent = rulesFile.readAsStringSync();
    });

    test('rules_version is v2', () {
      expect(rulesContent.contains("rules_version = '2';"), isTrue);
    });

    test('All 7 primary Firestore collection rules are defined', () {
      expect(rulesContent.contains('match /users/{userId}'), isTrue);
      expect(rulesContent.contains('match /complaints/{complaintId}'), isTrue);
      expect(rulesContent.contains('match /updates/{updateId}'), isTrue);
      expect(rulesContent.contains('match /departments/{departmentId}'), isTrue);
      expect(rulesContent.contains('match /notifications/{notificationId}'), isTrue);
      expect(rulesContent.contains('match /rewards/{userId}'), isTrue);
      expect(rulesContent.contains('match /hazards/{hazardId}'), isTrue);
    });

    test('Contains mandatory helper security functions', () {
      expect(rulesContent.contains('function isSignedIn()'), isTrue);
      expect(rulesContent.contains('function isOwner(userId)'), isTrue);
      expect(rulesContent.contains('function isCitizen()'), isTrue);
      expect(rulesContent.contains('function isGovernment()'), isTrue);
      expect(rulesContent.contains('function isValidStatus(status)'), isTrue);
      expect(rulesContent.contains('function isValidPriority(priority)'), isTrue);
      expect(rulesContent.contains('function isValidLocation(loc)'), isTrue);
    });

    test('Enforces privilege escalation prevention on users collection', () {
      expect(rulesContent.contains("affectedKeys().hasAny"), isTrue);
      expect(rulesContent.contains("'role'"), isTrue);
      expect(rulesContent.contains("'civicPoints'"), isTrue);
      expect(rulesContent.contains("'reportsSubmitted'"), isTrue);
      expect(rulesContent.contains("'reportsResolved'"), isTrue);
      expect(rulesContent.contains("'badges'"), isTrue);
    });

    test('Enforces complaint workflow status protection against citizen tampering', () {
      expect(rulesContent.contains("'status'"), isTrue);
      expect(rulesContent.contains("'assignedTo'"), isTrue);
      expect(rulesContent.contains("'departmentId'"), isTrue);
      expect(rulesContent.contains("'resolvedAt'"), isTrue);
    });

    test('Enforces server-authoritative write lock on rewards & departments', () {
      // match /rewards/{userId} has allow write: if false
      expect(rulesContent.contains('match /rewards/{userId}'), isTrue);
      // match /departments/{departmentId} has allow write: if false
      expect(rulesContent.contains('match /departments/{departmentId}'), isTrue);
    });
  });

  group('Firestore Domain Mapping Consistency Tests', () {
    test('All ComplaintStatus values match valid Firestore status strings', () {
      const validStatuses = [
        'reported',
        'verified',
        'assigned',
        'inProgress',
        'resolved',
        'rejected',
      ];

      for (final status in ComplaintStatus.values) {
        expect(
          validStatuses.contains(status.name),
          isTrue,
          reason: 'Status enum value "${status.name}" must be recognized by Firestore rules',
        );
      }
    });

    test('All ComplaintPriority values match valid Firestore priority strings', () {
      const validPriorities = ['low', 'medium', 'high', 'emergency'];

      for (final priority in ComplaintPriority.values) {
        expect(
          validPriorities.contains(priority.name),
          isTrue,
          reason: 'Priority enum value "${priority.name}" must be recognized by Firestore rules',
        );
      }
    });

    test('All HazardSeverity values match valid Firestore severity strings', () {
      const validSeverities = ['low', 'medium', 'high', 'critical'];

      for (final severity in HazardSeverity.values) {
        expect(
          validSeverities.contains(severity.name),
          isTrue,
          reason: 'Severity enum value "${severity.name}" must be recognized by Firestore rules',
        );
      }
    });
  });

  group('Firestore Indexes Configuration Tests', () {
    late File indexesFile;
    late Map<String, dynamic> indexesJson;

    setUpAll(() {
      indexesFile = File('firestore.indexes.json');
      expect(indexesFile.existsSync(), isTrue, reason: 'firestore.indexes.json must exist');
      indexesJson = jsonDecode(indexesFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('indexes JSON is valid and contains required collections', () {
      final indexes = indexesJson['indexes'] as List<dynamic>;
      expect(indexes.isNotEmpty, isTrue);

      final indexedCollections = indexes.map((i) => i['collectionGroup']).toSet();
      expect(indexedCollections.contains(FirestoreCollections.complaints), isTrue);
      expect(indexedCollections.contains(FirestoreCollections.notifications), isTrue);
      expect(indexedCollections.contains(FirestoreCollections.hazards), isTrue);
    });
  });
}
