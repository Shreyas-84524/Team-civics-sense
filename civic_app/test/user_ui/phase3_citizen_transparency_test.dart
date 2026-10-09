import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/mappers/complaint_firestore_mapper.dart';
import 'package:civic_app/core/local/models/complaint_local_model.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/complaint_upvote_result.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_result.dart';
import 'package:civic_app/core/ai/models/ai_analysis_status.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/User UI/services/mock_auth_service.dart';
import 'package:civic_app/User UI/screens/complaint_details_screen.dart';
import 'package:civic_app/User UI/widgets/complaint_details/officers_handling_card.dart';
import 'package:civic_app/User UI/widgets/complaint_details/resolution_evidence_card.dart';
import 'package:civic_app/User UI/widgets/complaint_details/rework_status_card.dart';
import 'package:civic_app/User UI/widgets/complaint_details/status_history_timeline.dart';
import 'package:civic_app/User UI/widgets/complaint_details/complaint_tracker.dart';
import 'package:civic_app/User UI/widgets/complaint_card.dart';
import 'package:civic_app/User UI/widgets/hazard_map/hazard_info_card.dart';
import 'package:civic_app/core/models/hazard_model.dart';

/// In-memory mock [ComplaintRepository] for widget & stream testing.
class _MockCitizenComplaintRepo implements ComplaintRepository {
  final Map<String, ComplaintModel> _store = {};
  final StreamController<ComplaintModel?> _streamController =
      StreamController<ComplaintModel?>.broadcast();

  void setComplaint(ComplaintModel c) {
    _store[c.id] = c;
    _store[c.ticketNumber] = c;
    _streamController.add(c);
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async => _store[id];

  @override
  Future<ComplaintModel?> getComplaintByTicketId(String ticketId) async =>
      _store[ticketId];

  @override
  Stream<ComplaintModel?> watchComplaint(String id) {
    return _streamController.stream.startWith(_store[id]);
  }

  @override
  Future<List<ComplaintModel>> getCitizenComplaints(String citizenId) async =>
      _store.values.where((c) => c.citizenId == citizenId).toList();

  @override
  Future<List<ComplaintModel>> getComplaints() async => _store.values.toList();

  @override
  Future<ComplaintModel> createComplaint({
    required String citizenId,
    required String title,
    required String description,
    required CivicCategory category,
    required CivicLocation location,
    required ComplaintPriority priority,
    List<String> imageUrls = const [],
    bool isHazard = false,
  }) async {
    final complaint = ComplaintModel(
      id: 'cmp_new_${DateTime.now().millisecondsSinceEpoch}',
      citizenId: citizenId,
      ticketNumber: 'CF-2026-000999',
      title: title,
      description: description,
      category: category,
      status: ComplaintStatus.reported,
      priority: priority,
      location: location,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isHazard: isHazard,
    );
    setComplaint(complaint);
    return complaint;
  }

  @override
  Future<ComplaintModel> saveOfflineComplaint(ComplaintModel complaint) async {
    setComplaint(complaint);
    return complaint;
  }

  @override
  Future<List<ComplaintModel>> getPendingComplaints() async => const [];

  @override
  Future<void> updateSyncStatus(
    String complaintId,
    SyncStatus status, {
    String? serverId,
    AiAuthenticityResult? aiAuthenticity,
    AiAnalysisStatus? aiAnalysisStatus,
  }) async {}

  @override
  Future<ComplaintUpvoteResult> upvoteComplaint(String id) async {
    final existing = _store[id];
    if (existing != null) {
      final updated = existing.copyWith(upvotes: existing.upvotes + 1);
      setComplaint(updated);
      return ComplaintUpvoteResult(upvotes: updated.upvotes, added: true);
    }
    return const ComplaintUpvoteResult(upvotes: 1, added: true);
  }

  @override
  Future<List<ComplaintModel>> getNearbyHazards() async =>
      _store.values.where((c) => c.isHazard).toList();

  @override
  Future<List<ComplaintModel>> getCitizenVisibleComplaints({
    String? citizenId,
    int limit = 100,
  }) async => _store.values.toList();

  @override
  Stream<List<TimelineEvent>> watchComplaintTimeline(String complaintId) async* {
    yield _store[complaintId]?.timeline ?? const [];
  }

  @override
  Stream<List<ComplaintModel>> watchCitizenComplaints(String citizenId) async* {
    yield _store.values.where((c) => c.citizenId == citizenId).toList();
  }

  @override
  Stream<List<ComplaintModel>> watchComplaints() async* {
    yield _store.values.toList();
  }

  @override
  Stream<List<ComplaintModel>> watchNearbyHazards() async* {
    yield _store.values.where((c) => c.isHazard).toList();
  }

  @override
  Stream<List<ComplaintModel>> watchCitizenVisibleComplaints({
    String? citizenId,
    int limit = 100,
  }) async* {
    yield _store.values.toList();
  }

  void dispose() {
    _streamController.close();
  }
}

extension _StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T initial) async* {
    yield initial;
    yield* this;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final baseLocation = const CivicLocation(
    latitude: 19.0350,
    longitude: 72.8420,
    address: 'Dharavi Main Road',
    landmark: 'Near Kumbharwada',
    ward: 'G/North',
    city: 'Mumbai',
    pincode: '400017',
  );

  final baseCreatedAt = DateTime(2026, 3, 15, 10, 0);
  final baseSlaStartedAt = DateTime(2026, 3, 15, 10, 0);

  group('CIVICFIX PHASE 3 — OFFICER IDENTITY & TRANSPARENCY DATA MODEL', () {
    test('1. ComplaintModel exposes Junior Engineer snapshots and clean fallback getters', () {
      final complaintWithSnapshot = ComplaintModel(
        id: 'cmp_301',
        ticketNumber: 'CF-2026-000301',
        title: 'Water pipe leak',
        description: 'Pavement water pipeline leaking',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.high,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
        wardId: 'G_NORTH',
        assignedDepartmentId: 'hydraulic_engineer',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-HYDRAULIC-01',
        assignedJuniorEngineerNameSnapshot: 'Rajesh Sharma',
        assignedJuniorEngineerDesignationSnapshot: 'Junior Engineer (Water Supply)',
      );

      expect(complaintWithSnapshot.isJuniorEngineerAssigned, isTrue);
      expect(complaintWithSnapshot.assignedJuniorEngineerId, 'GOV-CREW-G_NORTH-HYDRAULIC-01');
      expect(complaintWithSnapshot.assignedJuniorEngineerName, 'Rajesh Sharma');
      expect(complaintWithSnapshot.assignedJuniorEngineerDesignation, 'Junior Engineer (Water Supply)');

      // Fallback behavior when explicit snapshot strings are null
      final complaintFallback = ComplaintModel(
        id: 'cmp_302',
        ticketNumber: 'CF-2026-000302',
        title: 'Drainage blockage',
        description: 'Debris accumulated in drain',
        category: CivicCategory.defaultCategories[5],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.medium,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
        wardId: 'G_NORTH',
        assignedDepartmentId: 'sewerage_operations',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-SEWERAGE-01',
        assignedTo: 'Vikram Joshi',
      );

      expect(complaintFallback.isJuniorEngineerAssigned, isTrue);
      expect(complaintFallback.assignedJuniorEngineerName, 'Vikram Joshi');
      expect(complaintFallback.assignedJuniorEngineerDesignation, contains('Junior Engineer'));
    });

    test('2. ComplaintModel exposes Field Officer snapshots and execution state getters', () {
      final workStart = DateTime(2026, 3, 15, 12, 30);
      final complaint = ComplaintModel(
        id: 'cmp_303',
        ticketNumber: 'CF-2026-000303',
        title: 'Deep crater on junction',
        description: 'Road surface crater',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: workStart,
        wardId: 'G_NORTH',
        assignedDepartmentId: 'maintenance_roads',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-01',
        assignedFieldOfficerId: 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-02',
        assignedFieldOfficerAt: DateTime(2026, 3, 15, 11, 0),
        assignedFieldOfficerNameSnapshot: 'Amit Patel',
        assignedFieldOfficerDesignationSnapshot: 'Field Officer (Pothole Rapid Squad)',
        workStartedAt: workStart,
        workStartedBy: 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-02',
        beforeWorkPhoto: 'https://storage.supabase.co/before.jpg',
        afterWorkPhoto: 'https://storage.supabase.co/after.jpg',
        resolutionRemarks: 'Cold mix bitumen applied and leveled.',
        resolvedBy: 'Amit Patel',
      );

      expect(complaint.isFieldOfficerAssigned, isTrue);
      expect(complaint.assignedFieldOfficerName, 'Amit Patel');
      expect(complaint.assignedFieldOfficerDesignation, 'Field Officer (Pothole Rapid Squad)');
      expect(complaint.fieldExecutionStartedAt, workStart);
      expect(complaint.resolvedByFieldOfficerId, 'Amit Patel');
      expect(complaint.isBlocked, isFalse);
      expect(complaint.isReopened, isFalse);
    });

    test('3. ComplaintModel copyWith updates Junior Engineer and Field Officer snapshots', () {
      final initial = ComplaintModel(
        id: 'cmp_304',
        ticketNumber: 'CF-2026-000304',
        title: 'Streetlight fault',
        description: 'Lamp out',
        category: CivicCategory.defaultCategories[4],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
      );

      final updated = initial.copyWith(
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-ELECTRICAL-01',
        assignedJuniorEngineerNameSnapshot: 'Suresh Raina',
        assignedJuniorEngineerDesignationSnapshot: 'Junior Engineer (Street Lights)',
        assignedFieldOfficerId: 'GOV-CREW-G_NORTH-ELECTRICAL-02',
        assignedFieldOfficerNameSnapshot: 'Rohan Deshmukh',
        assignedFieldOfficerDesignationSnapshot: 'Field Officer (Electrical Crew)',
      );

      expect(updated.assignedJuniorEngineerName, 'Suresh Raina');
      expect(updated.assignedJuniorEngineerDesignation, 'Junior Engineer (Street Lights)');
      expect(updated.assignedFieldOfficerName, 'Rohan Deshmukh');
      expect(updated.assignedFieldOfficerDesignation, 'Field Officer (Electrical Crew)');
    });

    test('4. ComplaintFirestoreMapper round-trips JE and FO snapshots cleanly', () {
      final original = ComplaintModel(
        id: 'cmp_305',
        ticketNumber: 'CF-2026-000305',
        title: 'Tree branch blocking lane',
        description: 'Fallen branch',
        category: CivicCategory.defaultCategories[2],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.medium,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
        wardId: 'G_NORTH',
        assignedDepartmentId: 'garden_trees',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-GARDEN-01',
        assignedJuniorEngineerNameSnapshot: 'Anil Kapoor',
        assignedJuniorEngineerDesignationSnapshot: 'Junior Engineer (Garden Dept)',
        assignedFieldOfficerId: 'GOV-CREW-G_NORTH-GARDEN-02',
        assignedFieldOfficerNameSnapshot: 'Sunil Gavaskar',
        assignedFieldOfficerDesignationSnapshot: 'Field Officer (Tree Trimming)',
      );

      final map = ComplaintFirestoreMapper.toFirestore(original);
      expect(map['assignedJuniorEngineerNameSnapshot'], 'Anil Kapoor');
      expect(map['assignedJuniorEngineerDesignationSnapshot'], 'Junior Engineer (Garden Dept)');
      expect(map['assignedFieldOfficerNameSnapshot'], 'Sunil Gavaskar');
      expect(map['assignedFieldOfficerDesignationSnapshot'], 'Field Officer (Tree Trimming)');

      final restored = ComplaintFirestoreMapper.fromFirestore(
        documentId: 'cmp_305',
        data: map,
      );

      expect(restored.assignedJuniorEngineerName, 'Anil Kapoor');
      expect(restored.assignedJuniorEngineerDesignation, 'Junior Engineer (Garden Dept)');
      expect(restored.assignedFieldOfficerName, 'Sunil Gavaskar');
      expect(restored.assignedFieldOfficerDesignation, 'Field Officer (Tree Trimming)');
    });

    test('5. ComplaintLocalModel & ComplaintHiveAdapter round-trip offline persistence cleanly', () {
      final complaint = ComplaintModel(
        id: 'cmp_306',
        ticketNumber: 'CF-2026-000306',
        title: 'Manhole cover broken',
        description: 'Severe safety hazard',
        category: CivicCategory.defaultCategories[5],
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.emergency,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
        wardId: 'G_NORTH',
        assignedDepartmentId: 'drainage',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-DRAINAGE-01',
        assignedJuniorEngineerNameSnapshot: 'Harish Mehta',
        assignedJuniorEngineerDesignationSnapshot: 'Junior Engineer (Drainage)',
        assignedFieldOfficerId: 'GOV-CREW-G_NORTH-DRAINAGE-02',
        assignedFieldOfficerNameSnapshot: 'Kiran More',
        assignedFieldOfficerDesignationSnapshot: 'Field Officer (Emergency Response)',
        workStartedAt: DateTime(2026, 3, 15, 11, 30),
        beforeWorkPhoto: 'https://storage.supabase.co/manhole_before.jpg',
        afterWorkPhoto: 'https://storage.supabase.co/manhole_after.jpg',
        resolutionRemarks: 'Reinforced concrete lid installed.',
        resolvedBy: 'Kiran More',
        reopenCount: 1,
        reopenedAt: DateTime(2026, 3, 15, 14, 0),
        reopenedBy: 'Ward Department Lead',
        reopenReason: 'Edge seal alignment inspection required.',
        previousResolvedAt: DateTime(2026, 3, 15, 13, 0),
        previousResolutionEvidence: ['https://storage.supabase.co/manhole_after.jpg'],
      );

      final localModel = ComplaintLocalModel.fromDomain(complaint);
      expect(localModel.assignedJuniorEngineerNameSnapshot, 'Harish Mehta');
      expect(localModel.assignedFieldOfficerNameSnapshot, 'Kiran More');
      expect(localModel.reopenCount, 1);
      expect(localModel.reopenReason, 'Edge seal alignment inspection required.');

      final domain = localModel.toDomain();
      expect(domain.assignedJuniorEngineerName, 'Harish Mehta');
      expect(domain.assignedFieldOfficerName, 'Kiran More');
      expect(domain.isReopened, isTrue);
      expect(domain.reopenReason, 'Edge seal alignment inspection required.');
      expect(domain.previousResolutionEvidence.length, 1);
    });
  });

  group('CIVICFIX PHASE 3 — OFFICERS HANDLING CARD (WIDGET)', () {
    testWidgets('6. Displays Supervising Junior Engineer and Pending Field Allocation when FO is unassigned', (tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_307',
        ticketNumber: 'CF-2026-000307',
        title: 'Garbage dump on roadside',
        description: 'Waste overflowing',
        category: CivicCategory.defaultCategories[3],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.medium,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
        wardId: 'G_NORTH',
        assignedDepartmentId: 'solid_waste_management',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-SWM-01',
        assignedJuniorEngineerNameSnapshot: 'Pradeep Kumar',
        assignedJuniorEngineerDesignationSnapshot: 'Junior Engineer (Solid Waste)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficersHandlingCard(complaint: complaint),
          ),
        ),
      );

      // Verify JE details
      expect(find.text('Assigned Municipal Team'), findsOneWidget);
      expect(find.text('Supervising Junior Engineer'), findsOneWidget);
      expect(find.text('Pradeep Kumar'), findsOneWidget);
      expect(find.text('Junior Engineer (Solid Waste)'), findsOneWidget);
      expect(find.text('Supervising'), findsOneWidget);

      // Verify FO Progressive Pending State
      expect(find.text('Field Execution Officer'), findsOneWidget);
      expect(find.text('Pending Field Allocation'), findsOneWidget);
      expect(find.text('Awaiting field officer assignment by the Supervising Junior Engineer.'), findsOneWidget);
    });

    testWidgets('7. Displays both Junior Engineer and Field Officer when allocated', (tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_308',
        ticketNumber: 'CF-2026-000308',
        title: 'Pothole cluster',
        description: 'Road potholes',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.high,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
        wardId: 'G_NORTH',
        assignedDepartmentId: 'maintenance_roads',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-01',
        assignedJuniorEngineerNameSnapshot: 'S. Sharma',
        assignedJuniorEngineerDesignationSnapshot: 'Junior Engineer (Roads)',
        assignedFieldOfficerId: 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-02',
        assignedFieldOfficerNameSnapshot: 'R. Kulkarni',
        assignedFieldOfficerDesignationSnapshot: 'Field Officer (Asphalt Crew)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficersHandlingCard(complaint: complaint),
          ),
        ),
      );

      expect(find.text('S. Sharma'), findsOneWidget);
      expect(find.text('Junior Engineer (Roads)'), findsOneWidget);
      expect(find.text('R. Kulkarni'), findsOneWidget);
      expect(find.text('Field Officer (Asphalt Crew)'), findsOneWidget);
      expect(find.text('Assigned for Field Work'), findsOneWidget);
      expect(find.text('Field officer allocated. Ground operations scheduled.'), findsOneWidget);
    });

    testWidgets('8. Displays Work In Progress state with start time for Field Officer', (tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_309',
        ticketNumber: 'CF-2026-000309',
        title: 'Road trench',
        description: 'Road excavation repair',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        wardId: 'G_NORTH',
        assignedDepartmentId: 'maintenance_roads',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-01',
        assignedJuniorEngineerNameSnapshot: 'S. Sharma',
        assignedFieldOfficerId: 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-02',
        assignedFieldOfficerNameSnapshot: 'R. Kulkarni',
        assignedFieldOfficerDesignationSnapshot: 'Field Officer (Ground Execution)',
        workStartedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficersHandlingCard(complaint: complaint),
          ),
        ),
      );

      expect(find.text('Work In Progress'), findsOneWidget);
      expect(find.text('R. Kulkarni'), findsOneWidget);
      expect(find.textContaining('Commenced'), findsOneWidget);
    });

    testWidgets('9. Displays Temporarily On Hold state when complaint is blocked', (tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_310',
        ticketNumber: 'CF-2026-000310',
        title: 'Flooded subway',
        description: 'Water accumulation',
        category: CivicCategory.defaultCategories[5],
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: DateTime.now(),
        wardId: 'G_NORTH',
        assignedDepartmentId: 'storm_water_drains',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-SWD-01',
        assignedJuniorEngineerNameSnapshot: 'K. Verma',
        assignedFieldOfficerId: 'GOV-CREW-G_NORTH-SWD-02',
        assignedFieldOfficerNameSnapshot: 'D. Shinde',
        blockedAt: DateTime.now().subtract(const Duration(hours: 1)),
        blockedReason: 'High tide water influx; waiting for water level to recede',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficersHandlingCard(complaint: complaint),
          ),
        ),
      );

      expect(find.text('Temporarily On Hold'), findsOneWidget);
      expect(find.textContaining('Ground obstacle: High tide water influx'), findsOneWidget);
    });

    testWidgets('10. Strictly guards citizen privacy with zero leakage of phone/password/raw auth', (tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_311',
        ticketNumber: 'CF-2026-000311',
        title: 'Broken streetlight',
        description: 'Dark junction',
        category: CivicCategory.defaultCategories[4],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.medium,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
        wardId: 'G_NORTH',
        assignedDepartmentId: 'electrical',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-ELEC-01',
        assignedJuniorEngineerNameSnapshot: 'Officer SafeName',
        assignedJuniorEngineerDesignationSnapshot: 'Junior Engineer (Electrical)',
        assignedFieldOfficerId: 'GOV-CREW-G_NORTH-ELEC-02',
        assignedFieldOfficerNameSnapshot: 'Tech SafeName',
        assignedFieldOfficerDesignationSnapshot: 'Field Officer (Maintenance)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficersHandlingCard(complaint: complaint),
          ),
        ),
      );

      // Verify no sensitive tokens or strings are leaked in widget tree
      expect(find.textContaining('password'), findsNothing);
      expect(find.textContaining('+91'), findsNothing);
      expect(find.textContaining('@bmcmumbai.gov.in'), findsNothing);
      expect(find.textContaining('token'), findsNothing);
      expect(find.textContaining('secret'), findsNothing);
    });
  });

  group('CIVICFIX PHASE 3 — RESOLUTION EVIDENCE & BEFORE/AFTER COMPARISON (WIDGET)', () {
    testWidgets('11. Renders Before & After evidence comparison and remarks when resolved', (tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_312',
        ticketNumber: 'CF-2026-000312',
        title: 'Pothole on 60 Feet Road',
        description: 'Dangerous pothole',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.resolved,
        priority: ComplaintPriority.high,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: DateTime(2026, 3, 15, 16, 0),
        resolvedAt: DateTime(2026, 3, 15, 16, 0),
        imageUrls: ['https://storage.supabase.co/pothole_citizen_before.jpg'],
        beforeWorkPhoto: 'https://storage.supabase.co/pothole_citizen_before.jpg',
        afterWorkPhoto: 'https://storage.supabase.co/pothole_officer_after.jpg',
        resolutionRemarks: 'Bitumen patch layered, compacted with road roller.',
        resolvedBy: 'Field Officer R. Kulkarni',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResolutionEvidenceCard(complaint: complaint),
          ),
        ),
      );

      expect(find.text('Resolution & Work Verification'), findsOneWidget);
      expect(find.text('Reported Issue (Before)'), findsOneWidget);
      expect(find.text('Resolved Condition (After)'), findsOneWidget);
      expect(find.textContaining('Bitumen patch layered, compacted with road roller.'), findsOneWidget);
      expect(find.textContaining('Field Officer R. Kulkarni'), findsOneWidget);
    });

    testWidgets('12. Hides ResolutionEvidenceCard when complaint is unresolved and has no evidence', (tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_313',
        ticketNumber: 'CF-2026-000313',
        title: 'Open garbage spot',
        description: 'Littering',
        category: CivicCategory.defaultCategories[3],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.low,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResolutionEvidenceCard(complaint: complaint),
          ),
        ),
      );

      expect(find.text('Resolution & Work Verification'), findsNothing);
    });
  });

  group('CIVICFIX PHASE 3 — REWORK & SUPERVISORY REOPEN STATUS (WIDGET)', () {
    testWidgets('13. Displays prominent amber alert card with citizen-safe reopen reason and SLA notice', (tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_314',
        ticketNumber: 'CF-2026-000314',
        title: 'Road leveling incomplete',
        description: 'Bumpy patch left after repair',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: DateTime(2026, 3, 16, 9, 0),
        slaStartedAt: baseSlaStartedAt,
        wardId: 'G_NORTH',
        assignedDepartmentId: 'maintenance_roads',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-01',
        assignedJuniorEngineerNameSnapshot: 'S. Sharma',
        assignedFieldOfficerId: 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-02',
        assignedFieldOfficerNameSnapshot: 'R. Kulkarni',
        reopenedAt: DateTime(2026, 3, 16, 9, 0),
        reopenedBy: 'Ward Department Lead (Roads)',
        reopenReason: 'Supervisory quality audit identified uneven edges and improper leveling. Reassigned for resurfacing.',
        reopenCount: 1,
        previousResolvedAt: DateTime(2026, 3, 15, 17, 0),
        previousResolutionEvidence: ['https://storage.supabase.co/old_pothole_fix.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReworkStatusCard(complaint: complaint),
          ),
        ),
      );

      expect(find.text('Reopened for Quality Rework'), findsOneWidget);
      expect(find.text('Supervisory Quality Review Action'), findsOneWidget);
      expect(find.text('Rework Required'), findsOneWidget);
      expect(find.textContaining('Supervisory quality audit identified uneven edges'), findsOneWidget);
      expect(find.textContaining('Reviewed by: Ward Department Lead (Roads)'), findsOneWidget);
      expect(find.textContaining('Original SLA preserved from submission'), findsOneWidget);
      expect(find.textContaining('View Previous Resolution Record'), findsOneWidget);

      // Tap to expand previous resolution record
      await tester.tap(find.textContaining('View Previous Resolution Record'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Prior resolution timestamp'), findsOneWidget);
    });

    testWidgets('14. Hides ReworkStatusCard when complaint has never been reopened', (tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_315',
        ticketNumber: 'CF-2026-000315',
        title: 'Leaking tap',
        description: 'Public tap leak',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.medium,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReworkStatusCard(complaint: complaint),
          ),
        ),
      );

      expect(find.text('Reopened for Quality Rework'), findsNothing);
    });
  });

  group('CIVICFIX PHASE 3 — TIMELINE & PROGRESS TRACKER (WIDGET)', () {
    testWidgets('15. StatusHistoryTimeline renders lifecycle milestones with appropriate icons and tags', (tester) async {
      final timeline = [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Citizen report received via app.',
          timestamp: DateTime(2026, 3, 15, 10, 0),
          status: ComplaintStatus.reported,
        ),
        TimelineEvent(
          title: 'Assigned to Junior Engineer',
          description: 'Auto-routed to S. Sharma (Junior Engineer).',
          timestamp: DateTime(2026, 3, 15, 10, 1),
          status: ComplaintStatus.assigned,
          updatedBy: 'BMC_AUTO_ROUTING_ENGINE',
        ),
        TimelineEvent(
          title: 'Field Officer Assigned',
          description: 'Assigned ground execution to R. Kulkarni.',
          timestamp: DateTime(2026, 3, 15, 11, 0),
          status: ComplaintStatus.assigned,
          updatedBy: 'S. Sharma',
        ),
        TimelineEvent(
          title: 'Ground Work Started',
          description: 'Field officer commenced work on site.',
          timestamp: DateTime(2026, 3, 15, 12, 0),
          status: ComplaintStatus.inProgress,
          updatedBy: 'R. Kulkarni',
        ),
        TimelineEvent(
          title: 'Work Temporarily Blocked',
          description: 'Traffic diversion delayed asphalt roller.',
          timestamp: DateTime(2026, 3, 15, 13, 0),
          status: ComplaintStatus.inProgress,
          updatedBy: 'R. Kulkarni',
        ),
        TimelineEvent(
          title: 'Issue Resolved',
          description: 'Asphalt paving completed and verified.',
          timestamp: DateTime(2026, 3, 15, 15, 0),
          status: ComplaintStatus.resolved,
          updatedBy: 'R. Kulkarni',
        ),
        TimelineEvent(
          title: 'Reopened for Quality Rework',
          description: 'Leveling unsatisfactory upon lead review.',
          timestamp: DateTime(2026, 3, 16, 9, 0),
          status: ComplaintStatus.inProgress,
          updatedBy: 'Ward Department Lead',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatusHistoryTimeline(timeline: timeline),
            ),
          ),
        ),
      );

      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('7 entries'), findsOneWidget);
      expect(find.text('Reopened for Quality Rework'), findsOneWidget);
      expect(find.text('Issue Resolved'), findsOneWidget);
      expect(find.text('Work Temporarily Blocked'), findsOneWidget);
      expect(find.text('Ground Work Started'), findsOneWidget);
      expect(find.text('Field Officer Assigned'), findsOneWidget);
      expect(find.text('Assigned to Junior Engineer'), findsOneWidget);
      expect(find.text('Issue Reported'), findsOneWidget);
    });

    testWidgets('16. ComplaintTracker renders 5-stage progress properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ComplaintTracker(
              currentStatus: ComplaintStatus.inProgress,
              customStatusMessage: 'Squad currently leveling asphalt on site.',
            ),
          ),
        ),
      );

      expect(find.text('Progress Tracker'), findsOneWidget);
      expect(find.text('Stage 3 of 5'), findsOneWidget);
      expect(find.text('Squad currently leveling asphalt on site.'), findsOneWidget);
    });
  });

  group('CIVICFIX PHASE 3 — COMPLAINT DETAILS SCREEN INTEGRATION & LIVE STREAM', () {
    testWidgets('17. ComplaintDetailsScreen displays full transparency cards and reacts to live stream updates', (tester) async {
      final mockRepo = _MockCitizenComplaintRepo();
      final mockAuth = MockAuthService();
      mockAuth.resetForTesting(authenticated: true);
      mockAuth.setMockUser(const UserModel(
        id: 'user_citizen_001',
        fullName: 'Rahul Sharma',
        email: 'citizen@civicfix.test',
        phone: '+91 98765 43210',
      ));

      final initialComplaint = ComplaintModel(
        id: 'cmp_stream_01',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000401',
        title: 'Pipeline water leakage',
        description: 'Water gushing on road',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.high,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
        wardId: 'G_NORTH',
        assignedDepartmentId: 'hydraulic_engineer',
        assignedCrewMemberId: 'GOV-CREW-G_NORTH-HYDRAULIC-01',
        assignedJuniorEngineerNameSnapshot: 'Rajesh Sharma',
        assignedJuniorEngineerDesignationSnapshot: 'Junior Engineer (Water Supply)',
      );

      mockRepo.setComplaint(initialComplaint);

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintDetailsScreen(
            complaint: initialComplaint,
            repository: mockRepo,
            authService: mockAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Initial JE assigned, FO pending state
      expect(find.text('CF-2026-000401'), findsOneWidget);
      expect(find.text('Pipeline water leakage'), findsOneWidget);
      expect(find.text('Rajesh Sharma'), findsOneWidget);
      expect(find.text('Pending Field Allocation'), findsOneWidget);

      // LIVE REAL-TIME UPDATE 1: Junior Engineer assigns Field Officer
      final foAssigned = initialComplaint.copyWith(
        assignedFieldOfficerId: 'GOV-CREW-G_NORTH-HYDRAULIC-02',
        assignedFieldOfficerNameSnapshot: 'Mahesh Patil',
        assignedFieldOfficerDesignationSnapshot: 'Field Officer (Pipeline Repair)',
        assignmentStatus: ComplaintAssignmentStatus.fieldOfficerAssigned,
        updatedAt: DateTime.now(),
      );
      mockRepo.setComplaint(foAssigned);
      await tester.pumpAndSettle();

      expect(find.text('Mahesh Patil'), findsOneWidget);
      expect(find.text('Assigned for Field Work'), findsOneWidget);

      // LIVE REAL-TIME UPDATE 2: Field Officer starts work
      final workStarted = foAssigned.copyWith(
        status: ComplaintStatus.inProgress,
        workStartedAt: DateTime.now(),
        beforeWorkPhoto: 'https://storage.supabase.co/pipe_before.jpg',
      );
      mockRepo.setComplaint(workStarted);
      await tester.pumpAndSettle();

      expect(find.text('Work In Progress'), findsWidgets);

      // LIVE REAL-TIME UPDATE 3: Field Officer resolves complaint
      final resolved = workStarted.copyWith(
        status: ComplaintStatus.resolved,
        resolvedAt: DateTime.now(),
        afterWorkPhoto: 'https://storage.supabase.co/pipe_after.jpg',
        resolutionRemarks: 'Valve replaced and high-pressure gasket sealed.',
        resolvedBy: 'Mahesh Patil',
      );
      mockRepo.setComplaint(resolved);
      await tester.pumpAndSettle();

      expect(find.text('✓ Issue Resolved'), findsOneWidget);
      expect(find.text('Resolution & Work Verification'), findsOneWidget);
      expect(find.textContaining('Valve replaced and high-pressure gasket sealed.'), findsOneWidget);
      expect(find.text('Work Completed'), findsOneWidget);

      // LIVE REAL-TIME UPDATE 4: Department Lead reopens for rework
      final reopened = resolved.copyWith(
        status: ComplaintStatus.inProgress,
        reopenedAt: DateTime.now(),
        reopenedBy: 'Assistant Engineer (Oversight)',
        reopenReason: 'Pressure testing indicated residual moisture at joint.',
        reopenCount: 1,
        previousResolvedAt: DateTime.now(),
        previousResolutionEvidence: ['https://storage.supabase.co/pipe_after.jpg'],
      );
      mockRepo.setComplaint(reopened);
      await tester.pumpAndSettle();

      expect(find.text('Reopened for Quality Rework'), findsOneWidget);
      expect(find.textContaining('Pressure testing indicated residual moisture'), findsOneWidget);
    });

    testWidgets('18. ComplaintDetailsScreen blocks unauthorized access to other citizen complaints', (tester) async {
      final mockRepo = _MockCitizenComplaintRepo();
      final otherUserAuth = MockAuthService();
      otherUserAuth.resetForTesting(authenticated: true);
      otherUserAuth.setMockUser(const UserModel(
        id: 'user_citizen_999',
        fullName: 'Intruder User',
        email: 'intruder@example.com',
        phone: '+919999999999',
      ));

      final privateComplaint = ComplaintModel(
        id: 'cmp_private_01',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000501',
        title: 'Private Grievance',
        description: 'Private citizen notes',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.medium,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
        isHazard: false,
      );

      mockRepo.setComplaint(privateComplaint);

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintDetailsScreen(
            complaint: privateComplaint,
            repository: mockRepo,
            authService: otherUserAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to open this complaint.'), findsOneWidget);
      expect(find.text('This report belongs to a different citizen account.'), findsOneWidget);
    });
  });

  group('CIVICFIX PHASE 3 — COMPLAINT CARD & MAP INFO CARD (WIDGET)', () {
    testWidgets('19. ComplaintCard displays Supervising JE / Field Officer / Rework badge', (tester) async {
      final complaintWithFO = ComplaintModel(
        id: 'cmp_card_01',
        ticketNumber: 'CF-2026-000601',
        title: 'Broken paving slab',
        description: 'Footpath damage',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.medium,
        location: baseLocation,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
        assignedFieldOfficerId: 'GOV-CREW-02',
        assignedFieldOfficerNameSnapshot: 'R. Kulkarni',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintCard(
              complaint: complaintWithFO,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Field Officer: R. Kulkarni'), findsOneWidget);

      final reopenedComplaint = complaintWithFO.copyWith(
        reopenedAt: DateTime.now(),
        status: ComplaintStatus.inProgress,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintCard(
              complaint: reopenedComplaint,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Reopened for quality rework'), findsOneWidget);
    });

    testWidgets('20. HazardInfoCard displays current working phase and view details action', (tester) async {
      final hazard = HazardModel(
        id: 'haz_01',
        complaintId: 'cmp_haz_01',
        ticketNumber: 'CF-2026-000701',
        title: 'Exposed live electric wire',
        category: CivicCategory.defaultCategories[4],
        status: ComplaintStatus.inProgress,
        latitude: baseLocation.latitude,
        longitude: baseLocation.longitude,
        address: baseLocation.address,
        ward: baseLocation.ward,
        severity: HazardSeverity.critical,
        createdAt: baseCreatedAt,
        updatedAt: baseCreatedAt,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HazardInfoCard(
              hazard: hazard,
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Exposed live electric wire'), findsOneWidget);
      expect(find.text('Current Phase'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
    });
  });
}
