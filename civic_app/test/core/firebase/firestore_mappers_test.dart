import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/mappers/complaint_firestore_mapper.dart';
import 'package:civic_app/core/firebase/mappers/department_firestore_mapper.dart';
import 'package:civic_app/core/firebase/mappers/firestore_mapper_helpers.dart';
import 'package:civic_app/core/firebase/mappers/hazard_firestore_mapper.dart';
import 'package:civic_app/core/firebase/mappers/notification_firestore_mapper.dart';
import 'package:civic_app/core/firebase/mappers/reward_firestore_mapper.dart';
import 'package:civic_app/core/firebase/mappers/user_firestore_mapper.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/core/models/notification_model.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/Govt UI/models/department_model.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';

void main() {
  group('FirestoreMapperHelpers Unit Tests', () {
    test('timestampToDateTime converts Timestamp, String, int, and null', () {
      final now = DateTime(2026, 9, 8, 12, 0, 0);
      final ts = Timestamp.fromDate(now);

      expect(FirestoreMapperHelpers.timestampToDateTime(ts), equals(now));
      expect(FirestoreMapperHelpers.timestampToDateTime(now.toIso8601String()), equals(now));
      expect(FirestoreMapperHelpers.timestampToDateTime(now.millisecondsSinceEpoch), equals(now));
      expect(FirestoreMapperHelpers.timestampToDateTime(null), isNull);
      expect(FirestoreMapperHelpers.timestampToDateTime(123.45), isNull);
    });

    test('location conversions handle valid maps and fallbacks safely', () {
      const loc = CivicLocation(
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'MG Road, Fort',
        landmark: 'Near Fountain',
        ward: 'Ward 14',
        city: 'Mumbai',
      );

      final map = FirestoreMapperHelpers.locationToMap(loc);
      expect(map['latitude'], equals(19.0760));
      expect(map['longitude'], equals(72.8777));
      expect(map['address'], equals('MG Road, Fort'));

      final parsed = FirestoreMapperHelpers.locationFromMap(map);
      expect(parsed.latitude, equals(19.0760));
      expect(parsed.address, equals('MG Road, Fort'));

      final fallback = FirestoreMapperHelpers.locationFromMap(null);
      expect(fallback.latitude, equals(0.0));
      expect(fallback.address, equals('Unknown Location'));
    });

    test('Enum parsers handle known values and fallback gracefully on unknown/null', () {
      expect(FirestoreMapperHelpers.parseComplaintStatus('inProgress'), equals(ComplaintStatus.inProgress));
      expect(FirestoreMapperHelpers.parseComplaintStatus('submitted'), equals(ComplaintStatus.reported));
      expect(FirestoreMapperHelpers.parseComplaintStatus('unknown_status'), equals(ComplaintStatus.reported));
      expect(FirestoreMapperHelpers.parseComplaintStatus(null), equals(ComplaintStatus.reported));

      expect(FirestoreMapperHelpers.parseComplaintPriority('emergency'), equals(ComplaintPriority.emergency));
      expect(FirestoreMapperHelpers.parseComplaintPriority('invalid'), equals(ComplaintPriority.medium));

      expect(FirestoreMapperHelpers.parseHazardSeverity('critical'), equals(HazardSeverity.critical));
      expect(FirestoreMapperHelpers.parseHazardSeverity(null), equals(HazardSeverity.medium));

      expect(FirestoreMapperHelpers.parseNotificationType('complaintVerified'), equals(NotificationType.complaintVerified));
      expect(FirestoreMapperHelpers.parseNotificationType(null), equals(NotificationType.generalCivic));
    });
  });

  group('ComplaintFirestoreMapper Unit Tests', () {
    test('toFirestore and fromFirestore serialize and deserialize accurately', () {
      final now = DateTime(2026, 9, 8, 10, 0, 0);
      final complaint = ComplaintModel(
        id: 'cmp_101',
        citizenId: 'usr_001',
        ticketNumber: 'CF-2026-000024',
        title: 'Broken streetlight',
        description: 'Streetlight has been dark for 3 days',
        category: CivicCategory.defaultCategories[4],
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Park Avenue',
        ),
        imageUrls: const ['https://storage.civicfix.com/evidence_1.jpg'],
        createdAt: now,
        updatedAt: now,
        upvotes: 5,
        isHazard: true,
        assignedTo: 'off_105',
        departmentName: 'Electrical / Public Works',
      );

      final map = ComplaintFirestoreMapper.toFirestore(complaint, isCreate: true);
      expect(map['citizenId'], equals('usr_001'));
      expect(map['ticketNumber'], equals('CF-2026-000024'));
      expect(map['status'], equals('inProgress'));
      expect(map['priority'], equals('high'));
      expect(map['upvotes'], equals(5));
      expect(map['isHazard'], isTrue);

      final restored = ComplaintFirestoreMapper.fromFirestore(
        documentId: 'doc_cmp_101',
        data: {
          'citizenId': 'usr_001',
          'ticketNumber': 'CF-2026-000024',
          'title': 'Broken streetlight',
          'description': 'Streetlight has been dark for 3 days',
          'category': {'id': 'cat_electrical', 'name': 'Street Lights'},
          'status': 'inProgress',
          'priority': 'high',
          'location': {'latitude': 12.9716, 'longitude': 77.5946, 'address': 'Park Avenue'},
          'imageUrls': ['https://storage.civicfix.com/evidence_1.jpg'],
          'createdAt': now,
          'updatedAt': now,
          'upvotes': 5,
          'isHazard': true,
        },
      );

      expect(restored.id, equals('doc_cmp_101'));
      expect(restored.citizenId, equals('usr_001'));
      expect(restored.status, equals(ComplaintStatus.inProgress));
      expect(restored.priority, equals(ComplaintPriority.high));
      expect(restored.isHazard, isTrue);
    });

    test('timelineEventToFirestore and timelineEventFromFirestore map correctly', () {
      final now = DateTime(2026, 9, 8, 11, 0, 0);
      final event = TimelineEvent(
        title: 'Status Updated to Verified',
        description: 'Issue confirmed on site.',
        timestamp: DateTime(2026, 9, 8, 11, 0, 0),
        status: ComplaintStatus.verified,
        updatedBy: 'govt_off_001',
      );

      final map = ComplaintFirestoreMapper.timelineEventToFirestore(event);
      expect(map['title'], equals('Status Updated to Verified'));
      expect(map['status'], equals('verified'));
      expect(map['updatedBy'], equals('govt_off_001'));

      final restored = ComplaintFirestoreMapper.timelineEventFromFirestore({
        'title': 'Status Updated to Verified',
        'description': 'Issue confirmed on site.',
        'timestamp': now,
        'status': 'verified',
        'updatedBy': 'govt_off_001',
      });

      expect(restored.title, equals('Status Updated to Verified'));
      expect(restored.status, equals(ComplaintStatus.verified));
      expect(restored.updatedBy, equals('govt_off_001'));
    });
  });

  group('UserFirestoreMapper Unit Tests', () {
    test('Citizen UserModel maps bidirectional correctly', () {
      const citizen = UserModel(
        id: 'usr_citizen_001',
        fullName: 'Rahul Sharma',
        email: 'citizen@civicfix.test',
        phone: '+91 98765 43210',
        civicPoints: 480,
        reportsSubmitted: 8,
        reportsResolved: 6,
        badges: ['First Report'],
        languageCode: 'hi',
        wardNumber: 'Ward 14 (Central)',
      );

      final map = UserFirestoreMapper.citizenToFirestore(citizen, isCreate: true);
      expect(map['fullName'], equals('Rahul Sharma'));
      expect(map['role'], equals('citizen'));
      expect(map['civicPoints'], equals(480));

      final restored = UserFirestoreMapper.citizenFromFirestore(
        documentId: 'usr_citizen_001',
        data: map,
      );

      expect(restored.id, equals('usr_citizen_001'));
      expect(restored.fullName, equals('Rahul Sharma'));
      expect(restored.languageCode, equals('hi'));
      expect(restored.role, equals('citizen'));
    });

    test('GovtUserModel maps bidirectional correctly', () {
      const officer = GovtUserModel(
        id: 'govt_001',
        fullName: 'Arun Deshmukh',
        email: 'officer@civicfix.test',
        employeeId: 'MC-2026-ENG-842',
        departmentId: 'dept_roads',
        departmentName: 'Roads Department',
        designation: 'Nodal Officer',
        assignedWard: 'Ward 14',
      );

      final map = UserFirestoreMapper.govtUserToFirestore(officer);
      expect(map['employeeId'], equals('MC-2026-ENG-842'));
      expect(map['role'], equals('government'));

      final restored = UserFirestoreMapper.govtUserFromFirestore(
        documentId: 'govt_001',
        data: map,
      );

      expect(restored.employeeId, equals('MC-2026-ENG-842'));
      expect(restored.role, equals('government'));
    });
  });

  group('NotificationFirestoreMapper Unit Tests', () {
    test('NotificationModel maps bidirectional accurately', () {
      final now = DateTime(2026, 9, 8, 10, 30, 0);
      final notif = NotificationModel(
        id: 'notif_1',
        userId: 'usr_001',
        title: 'Issue Assigned',
        message: 'Your report has been assigned to a maintenance crew.',
        type: NotificationType.complaintAssigned,
        complaintId: 'cmp_101',
        isRead: false,
        createdAt: now,
      );

      final map = NotificationFirestoreMapper.toFirestore(notif);
      expect(map['userId'], equals('usr_001'));
      expect(map['type'], equals('complaintAssigned'));

      final restored = NotificationFirestoreMapper.fromFirestore(
        documentId: 'notif_1',
        data: {
          'userId': 'usr_001',
          'title': 'Issue Assigned',
          'message': 'Your report has been assigned to a maintenance crew.',
          'type': 'complaintAssigned',
          'complaintId': 'cmp_101',
          'isRead': false,
          'createdAt': now,
        },
      );

      expect(restored.id, equals('notif_1'));
      expect(restored.type, equals(NotificationType.complaintAssigned));
      expect(restored.isRead, isFalse);
    });
  });

  group('HazardFirestoreMapper Unit Tests', () {
    test('HazardModel maps without exposing citizen PII', () {
      final now = DateTime(2026, 9, 8, 9, 0, 0);
      final hazard = HazardModel(
        id: 'haz_101',
        complaintId: 'cmp_101',
        ticketNumber: 'CF-2026-000021',
        title: 'Road Crater',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.inProgress,
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Main Road',
        severity: HazardSeverity.high,
        upvotes: 10,
        createdAt: now,
        updatedAt: now,
      );

      final map = HazardFirestoreMapper.toFirestore(hazard);
      expect(map.containsKey('citizenEmail'), isFalse);
      expect(map.containsKey('citizenPhone'), isFalse);
      expect(map.containsKey('citizenName'), isFalse);
      expect(map['severity'], equals('high'));

      final restored = HazardFirestoreMapper.fromFirestore(
        documentId: 'haz_101',
        data: {
          'complaintId': 'cmp_101',
          'ticketNumber': 'CF-2026-000021',
          'title': 'Road Crater',
          'category': {'id': 'cat_roads', 'name': 'Roads & Potholes'},
          'status': 'inProgress',
          'latitude': 19.0760,
          'longitude': 72.8777,
          'address': 'Main Road',
          'severity': 'high',
          'upvotes': 10,
          'createdAt': now,
          'updatedAt': now,
        },
      );

      expect(restored.id, equals('haz_101'));
      expect(restored.severity, equals(HazardSeverity.high));
      expect(restored.upvotes, equals(10));
    });
  });

  group('RewardFirestoreMapper Unit Tests', () {
    test('RewardDataModel and achievements map bidirectional correctly', () {
      const reward = RewardDataModel(
        userId: 'usr_001',
        currentPoints: 850,
        nextMilestoneTarget: 1000,
        reportsSubmitted: 12,
        reportsResolved: 8,
        achievements: [],
      );

      final map = RewardFirestoreMapper.toFirestore(reward);
      expect(map['points'], equals(850));

      final restored = RewardFirestoreMapper.fromFirestore(
        documentId: 'usr_001',
        data: map,
      );

      expect(restored.userId, equals('usr_001'));
      expect(restored.currentPoints, equals(850));
      expect(restored.achievements.isNotEmpty, isTrue);
    });
  });

  group('DepartmentFirestoreMapper Unit Tests', () {
    test('GovtDepartmentModel and GovtOfficerModel map bidirectional correctly', () {
      final dept = GovtDepartmentModel.defaultDepartments.first;
      final map = DepartmentFirestoreMapper.departmentToFirestore(dept);
      expect(map['name'], equals('Roads Department'));
      expect(map['code'], equals('PWD-RD'));

      final restored = DepartmentFirestoreMapper.departmentFromFirestore(
        documentId: dept.id,
        data: map,
      );

      expect(restored.id, equals('dept_roads'));
      expect(restored.code, equals('PWD-RD'));
    });
  });
}
