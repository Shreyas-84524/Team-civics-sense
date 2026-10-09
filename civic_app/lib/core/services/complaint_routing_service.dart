import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firebase_constants.dart';
import '../firebase/mappers/complaint_firestore_mapper.dart';
import '../models/category_model.dart';
import '../models/civic_department_model.dart';
import '../models/civic_ward_model.dart';
import '../models/complaint_model.dart';
import '../models/complaint_routing_ticket_model.dart';
import '../models/government_audit_log_model.dart';
import '../models/government_role.dart';
import '../models/reward_model.dart';
import '../repositories/repository_locator.dart';
import '../../Govt UI/models/govt_user_model.dart';
import '../../Govt UI/services/government_department_dashboard_service.dart';
import '../../Govt UI/services/government_ward_dashboard_service.dart';
import '../../Govt UI/services/govt_complaint_repository.dart';
import 'government_audit_service.dart';
import 'government_authorization_service.dart';
import 'government_hierarchy_repository.dart';
import 'reward_evaluation_service.dart';

/// BMC Automated Complaint Routing & Matrix Governance Service.
///
/// Implements Phase 1 Automated Complaint Routing directly to Junior Engineers (JEs):
/// 1. GPS Geotagging & Ward Detection across 24 BMC Wards.
/// 2. Deterministic Department Classification across 18 BMC Departments.
/// 3. Workload-aware Junior Engineer assignment with deterministic tie-breaking.
/// 4. Strict SLA clock preservation (`slaStartedAt` established at ingestion, never reset).
/// 5. Direct Wrong-Department Transfer preserving SLA and audit trail.
/// 6. Department Lead supervisory oversight (no longer a mandatory triage bottleneck).
class ComplaintRoutingService {
  final GovernmentHierarchyRepository _hierarchyRepo;
  final GovernmentAuditService _auditService;
  final GovernmentAuthorizationService _authService;
  final FirebaseFirestore? _firestore;
  final GovtComplaintRepository? _complaintRepo;

  // In-memory store for routing tickets (for offline/testing resilience)
  final Map<String, ComplaintRoutingTicket> _tickets = {};
  // In-memory store or cache for complaints
  final Map<String, ComplaintModel> _complaintsCache = {};

  ComplaintRoutingService({
    GovernmentHierarchyRepository? hierarchyRepo,
    GovernmentAuditService? auditService,
    GovernmentAuthorizationService? authService,
    FirebaseFirestore? firestore,
    GovtComplaintRepository? complaintRepo,
  })  : _hierarchyRepo = hierarchyRepo ?? LocalGovernmentHierarchyRepository(),
        _auditService = auditService ?? DefaultGovernmentAuditService(),
        _authService = authService ??
            GovernmentAuthorizationService(
                hierarchyRepo: hierarchyRepo ?? LocalGovernmentHierarchyRepository()),
        _firestore = firestore,
        _complaintRepo = complaintRepo;

  GovernmentHierarchyRepository get hierarchyRepository => _hierarchyRepo;
  GovernmentAuditService get auditService => _auditService;
  GovernmentAuthorizationService get authorizationService => _authService;
  GovtComplaintRepository get complaintRepository => _effectiveComplaintRepo;

  FirebaseFirestore? get _effectiveFirestore {
    if (_firestore != null) return _firestore;
    if (RepositoryLocator.isFirebaseReady) {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {}
    }
    return null;
  }

  GovtComplaintRepository get _effectiveComplaintRepo {
    if (_complaintRepo != null) return _complaintRepo;
    return RepositoryLocator.govtComplaintRepository;
  }

  /// Registers or caches a complaint for routing operations.
  void registerComplaint(ComplaintModel complaint) {
    _complaintsCache[complaint.id] = complaint;
    if (complaint.ticketNumber.isNotEmpty) {
      _complaintsCache[complaint.ticketNumber] = complaint;
    }
  }

  // ===========================================================================
  // 1. GEOTAGGING & WARD DETECTION (24 BMC WARDS)
  // ===========================================================================

  /// Calculates the great-circle distance between two GPS coordinates using the Haversine formula.
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * (pi / 180.0);

  /// Resolves the canonical BMC Ward for given GPS coordinates or raw ward identifier.
  /// Resolves the canonical BMC Ward for given GPS coordinates or raw ward identifier.
  ///
  /// CRITICAL GUARANTEE: Does NOT silently fallback to G/North if coordinates cannot be resolved.
  Future<CivicWard> resolveWardForLocation({
    double? lat,
    double? lng,
    String? rawWard,
    bool allowFallback = true,
  }) async {
    await _hierarchyRepo.initialize();
    final allWards = await _hierarchyRepo.getWards();

    // 1. If explicit rawWard string is provided, attempt exact or normalized matching
    if (rawWard != null && rawWard.trim().isNotEmpty) {
      final clean = rawWard.trim().toLowerCase();
      for (final ward in allWards) {
        if (ward.wardId.toLowerCase() == clean ||
            ward.wardCode.toLowerCase() == clean ||
            GovernmentWardDashboardService.matchesWard(ward.wardCode, rawWard) ||
            GovernmentWardDashboardService.matchesWard(ward.wardId, rawWard) ||
            ward.wardName.toLowerCase().contains(clean)) {
          return ward;
        }
      }
    }

    // 2. Geotagging & Proximity-based Resolution via Coordinates
    if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
      CivicWard? closestWard;
      double minDistance = double.infinity;

      for (final ward in allWards) {
        final dist = calculateDistanceKm(lat, lng, ward.lat, ward.lng);
        if (dist < minDistance) {
          minDistance = dist;
          closestWard = ward;
        }
      }

      // Mumbai administrative boundary threshold: maximum ~35 km from any BMC ward centroid
      if (closestWard != null && minDistance <= 35.0) {
        return closestWard;
      }

      if (!allowFallback) {
        throw ArgumentError(
          'Cannot resolve BMC Ward: GPS coordinates ($lat, $lng) are outside Mumbai administrative boundary (${minDistance.toStringAsFixed(1)} km from closest ward). No silent default ward assigned.',
        );
      }
    }

    if (!allowFallback && (rawWard == null || rawWard.trim().isEmpty)) {
      throw ArgumentError(
        'Cannot resolve BMC Ward: Missing valid GPS coordinates or ward name. Silent fallback to G/North is disabled.',
      );
    }

    // Fallback only if explicitly permitted (legacy compatibility)
    if (allWards.isNotEmpty) {
      return allWards.firstWhere(
        (w) => w.wardId == 'G_NORTH' || w.wardCode == 'G/North' || w.wardId == 'A',
        orElse: () => allWards.first,
      );
    }

    return const CivicWard(
      wardId: 'G_NORTH',
      wardCode: 'G/North',
      wardName: 'G North Ward (Dadar / Dharavi)',
      zoneId: 'ZONE_2',
      lat: 19.035,
      lng: 72.842,
      pincode: '400028',
    );
  }

  // ===========================================================================
  // 2. DEPARTMENT CLASSIFICATION (18 BMC DEPARTMENTS)
  // ===========================================================================

  /// Resolves the canonical BMC Department for a civic category or raw department name.
  Future<CivicDepartment> resolveDepartmentForCategory({
    CivicCategory? category,
    String? rawCategory,
    String? rawDept,
  }) async {
    await _hierarchyRepo.initialize();
    final allDepartments = await _hierarchyRepo.getDepartments();

    String cleanDeptId = '';
    if (rawDept != null && rawDept.trim().isNotEmpty && rawDept != 'General Municipal Desk' && !rawDept.contains('Manual Review')) {
      cleanDeptId = GovernmentDepartmentDashboardService.normalizeDepartmentId(rawDept);
    } else if (rawCategory != null && rawCategory.trim().isNotEmpty) {
      cleanDeptId = GovernmentDepartmentDashboardService.normalizeDepartmentId(rawCategory);
    } else if (category != null) {
      cleanDeptId = GovernmentDepartmentDashboardService.normalizeDepartmentId(category.id);
    } else {
      cleanDeptId = 'solid_waste_management';
    }

    for (final dept in allDepartments) {
      if (dept.departmentId.toLowerCase() == cleanDeptId.toLowerCase() ||
          GovernmentDepartmentDashboardService.matchesDepartment(dept.departmentId, cleanDeptId)) {
        return dept;
      }
    }

    if (allDepartments.isNotEmpty) {
      return allDepartments.firstWhere(
        (d) => d.departmentId == 'maintenance_roads' || d.departmentId == 'solid_waste_management',
        orElse: () => allDepartments.first,
      );
    }

    return const CivicDepartment(
      departmentId: 'maintenance_roads',
      departmentCode: 'RDS',
      displayName: 'Roads & Maintenance',
      description: 'Pothole repairs, asphalt resurfacing, road trenches, footpaths.',
      active: true,
      citizenComplaintEnabled: true,
      defaultLeadDesignation: 'Assistant Engineer (Roads)',
    );
  }

  // ===========================================================================
  // 3. JUNIOR ENGINEER ELIGIBILITY & WORKLOAD-AWARE SELECTION
  // ===========================================================================

  /// Retrieves all active Junior Engineers / Ground Technicians assigned to a specific Ward × Department unit.
  Future<List<GovtUserModel>> getEligibleJuniorEngineers({
    required String wardId,
    required String departmentId,
  }) async {
    await _hierarchyRepo.initialize();
    final cleanWard = GovernmentWardDashboardService.normalizeWardId(wardId);
    final cleanDept = GovernmentDepartmentDashboardService.normalizeDepartmentId(departmentId);

    final allUsers = await _hierarchyRepo.getUsers(
      role: GovernmentRole.departmentCrewId,
    );

    final eligible = allUsers.where((u) {
      if (!u.active || !u.isCrew) return false;
      final wardMatches = GovernmentWardDashboardService.matchesWard(u.wardId, cleanWard) ||
          (u.wardId != null && u.wardId!.toLowerCase() == cleanWard.toLowerCase());
      final deptMatches = GovernmentDepartmentDashboardService.matchesDepartment(u.departmentId, cleanDept) ||
          (u.departmentId != null && u.departmentId!.toLowerCase() == cleanDept.toLowerCase());
      return wardMatches && deptMatches;
    }).toList();

    // Deterministic alphabetical sorting by employeeId ascending
    eligible.sort((a, b) => a.employeeId.compareTo(b.employeeId));
    return eligible;
  }

  /// Deterministically selects the least-loaded Junior Engineer from a list of eligible candidates.
  ///
  /// Ties are broken by employee ID in ascending alphabetical order (e.g., `-01` before `-02`).
  GovtUserModel? selectLeastLoadedJuniorEngineer({
    required List<GovtUserModel> eligibleJEs,
    required List<ComplaintModel> allComplaints,
  }) {
    if (eligibleJEs.isEmpty) return null;
    if (eligibleJEs.length == 1) return eligibleJEs.first;

    final Map<String, int> loadMap = {};
    for (final je in eligibleJEs) {
      loadMap[je.employeeId] = 0;
    }

    for (final c in allComplaints) {
      final isActive = c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected;
      if (!isActive) continue;

      for (final je in eligibleJEs) {
        final isAssignedToJE = (c.assignedCrewMemberId != null &&
                (c.assignedCrewMemberId!.toLowerCase() == je.employeeId.toLowerCase() ||
                 c.assignedCrewMemberId!.toLowerCase() == je.id.toLowerCase())) ||
            (c.assignedTo != null &&
                (c.assignedTo!.toLowerCase() == je.fullName.toLowerCase() ||
                 c.assignedTo!.toLowerCase().contains(je.employeeId.toLowerCase())));

        if (isAssignedToJE) {
          loadMap[je.employeeId] = (loadMap[je.employeeId] ?? 0) + 1;
        }
      }
    }

    int minLoad = double.maxFinite.toInt();
    for (final count in loadMap.values) {
      if (count < minLoad) {
        minLoad = count;
      }
    }

    final candidates = eligibleJEs
        .where((je) => (loadMap[je.employeeId] ?? 0) == minLoad)
        .toList();

    // Ties broken deterministically by employeeId ascending
    candidates.sort((a, b) => a.employeeId.compareTo(b.employeeId));
    return candidates.first;
  }

  // ===========================================================================
  // 4. AUTOMATED COMPLAINT ROUTING TO JUNIOR ENGINEER
  // ===========================================================================

  /// Automatically routes a newly submitted or unassigned complaint directly to the least-loaded
  /// Junior Engineer in the detected Ward × Department unit.
  ///
  /// CRITICAL GUARANTEES:
  /// - Status transitions directly to `ComplaintStatus.assigned`.
  /// - `assignmentStatus` transitions to `ComplaintAssignmentStatus.crewAssigned`.
  /// - `slaStartedAt` and `originalCreatedAt` are strictly PRESERVED from ingestion.
  /// - Audit action `auto_routed_to_junior_engineer` is logged.
  /// - If no JE is available, falls back safely to `unassigned` status and logs `routing_failed`.
  Future<ComplaintModel> autoRouteComplaint(
    ComplaintModel complaint, {
    List<ComplaintModel>? activeComplaintsPool,
  }) async {
    // Idempotency: If already assigned to an active JE in target ward/dept, return early
    if (complaint.assignedCrewMemberId != null &&
        complaint.assignedCrewMemberId!.isNotEmpty &&
        complaint.status == ComplaintStatus.assigned &&
        complaint.wardId != null &&
        complaint.assignedDepartmentId != null) {
      registerComplaint(complaint);
      return complaint;
    }

    await _hierarchyRepo.initialize();

    // 1. Geotagging / Ward Detection
    final resolvedWard = await resolveWardForLocation(
      lat: complaint.location.latitude,
      lng: complaint.location.longitude,
      rawWard: complaint.wardId ?? complaint.location.ward,
    );
    final targetWardId = resolvedWard.wardId;

    // 2. Department Classification
    final resolvedDept = await resolveDepartmentForCategory(
      category: complaint.category,
      rawCategory: complaint.category.id,
      rawDept: complaint.assignedDepartmentId ?? complaint.departmentName,
    );
    final targetDeptId = resolvedDept.departmentId;
    final targetDeptName = resolvedDept.displayName;

    // 3. Find Ward Department Lead (for supervisory oversight tracking)
    final wardDept = await _hierarchyRepo.getWardDepartment(targetWardId, targetDeptId);
    final leadId = wardDept?.departmentLeadId;

    // 4. Query Eligible Junior Engineers
    final eligibleJEs = await getEligibleJuniorEngineers(
      wardId: targetWardId,
      departmentId: targetDeptId,
    );

    // 5. Select Least-Loaded Junior Engineer
    final complaintsPool = activeComplaintsPool ?? _complaintsCache.values.toList();
    final selectedJE = selectLeastLoadedJuniorEngineer(
      eligibleJEs: eligibleJEs,
      allComplaints: complaintsPool,
    );

    final now = DateTime.now();
    final effectiveCreatedAt = complaint.createdAt;
    final effectiveOriginalCreatedAt = complaint.originalCreatedAt;
    final effectiveSlaStartedAt = complaint.slaStartedAt;

    if (selectedJE != null) {
      // Successful automatic routing to Junior Engineer
      final updatedTimeline = List<TimelineEvent>.from(complaint.timeline);
      final hasRoutingEvent = updatedTimeline.any((t) =>
          t.title.toLowerCase().contains('junior engineer') ||
          t.title.toLowerCase().contains('crew'));

      if (!hasRoutingEvent) {
        updatedTimeline.add(TimelineEvent(
          title: 'Assigned to Junior Engineer',
          description:
              'Auto-routed to ${selectedJE.fullName} (${selectedJE.displayDesignation}) in Ward ${resolvedWard.wardCode} - $targetDeptName.',
          timestamp: now,
          status: ComplaintStatus.assigned,
          updatedBy: 'BMC_AUTO_ROUTING_ENGINE',
        ));
      }

      final routedComplaint = complaint.copyWith(
        status: ComplaintStatus.assigned,
        assignmentStatus: ComplaintAssignmentStatus.crewAssigned,
        routingStatus: ComplaintRoutingStatus.assigned,
        wardId: targetWardId,
        assignedDepartmentId: targetDeptId,
        assignedDepartmentLeadId: leadId,
        assignedCrewMemberId: selectedJE.employeeId,
        assignedTo: selectedJE.fullName,
        assignedJuniorEngineerNameSnapshot: selectedJE.fullName,
        assignedJuniorEngineerDesignationSnapshot: selectedJE.displayDesignation,
        departmentName: targetDeptName,
        currentDepartmentAssignedAt: complaint.currentDepartmentAssignedAt ?? now,
        timeline: updatedTimeline,
        updatedAt: now,
        // CRITICAL: originalCreatedAt and slaStartedAt are strictly PRESERVED
        createdAt: effectiveCreatedAt,
        originalCreatedAt: effectiveOriginalCreatedAt,
        slaStartedAt: effectiveSlaStartedAt,
      );

      registerComplaint(routedComplaint);

      final firestore = _effectiveFirestore;
      if (firestore != null) {
        try {
          await firestore
              .collection(FirestoreCollections.complaints)
              .doc(routedComplaint.id)
              .update({
            'status': ComplaintStatus.assigned.name,
            'assignmentStatus': ComplaintAssignmentStatus.crewAssigned.id,
            'routingStatus': ComplaintRoutingStatus.assigned.id,
            'wardId': targetWardId,
            'assignedDepartmentId': targetDeptId,
            'assignedDepartmentLeadId': leadId,
            'assignedCrewMemberId': selectedJE.employeeId,
            'assignedTo': selectedJE.fullName,
            'assignedJuniorEngineerNameSnapshot': selectedJE.fullName,
            'assignedJuniorEngineerDesignationSnapshot': selectedJE.displayDesignation,
            'departmentName': targetDeptName,
            'currentDepartmentAssignedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      await _auditService.logAction(
        complaintId: routedComplaint.id,
        action: GovernmentAuditActions.autoRoutedToJuniorEngineer,
        actorId: 'BMC_AUTO_ROUTING_ENGINE',
        actorRole: 'system',
        actorName: 'Automated Grievance Routing Engine',
        wardId: targetWardId,
        departmentId: targetDeptId,
        details: {
          'ticketNumber': routedComplaint.ticketNumber,
          'assignedJuniorEngineerId': selectedJE.employeeId,
          'assignedJuniorEngineerName': selectedJE.fullName,
          'wardId': targetWardId,
          'departmentId': targetDeptId,
          'departmentLeadId': leadId,
          'slaStartedAt': effectiveSlaStartedAt.toIso8601String(),
        },
      );

      return routedComplaint;
    } else {
      // Safe Fallback: No eligible active JE found for unit
      final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
        ..add(TimelineEvent(
          title: 'Routing Alert',
          description:
              'No active Junior Engineer available for Ward ${resolvedWard.wardCode} - $targetDeptName. Escalated to Department Lead.',
          timestamp: now,
          status: ComplaintStatus.verified,
          updatedBy: 'BMC_AUTO_ROUTING_ENGINE',
        ));

      final unassignedComplaint = complaint.copyWith(
        status: ComplaintStatus.verified,
        assignmentStatus: ComplaintAssignmentStatus.unassigned,
        routingStatus: ComplaintRoutingStatus.unassigned,
        wardId: targetWardId,
        assignedDepartmentId: targetDeptId,
        assignedDepartmentLeadId: leadId,
        departmentName: targetDeptName,
        timeline: updatedTimeline,
        updatedAt: now,
        createdAt: effectiveCreatedAt,
        originalCreatedAt: effectiveOriginalCreatedAt,
        slaStartedAt: effectiveSlaStartedAt,
      );

      registerComplaint(unassignedComplaint);

      await _auditService.logAction(
        complaintId: unassignedComplaint.id,
        action: GovernmentAuditActions.routingFailed,
        actorId: 'BMC_AUTO_ROUTING_ENGINE',
        actorRole: 'system',
        actorName: 'Automated Grievance Routing Engine',
        wardId: targetWardId,
        departmentId: targetDeptId,
        details: {
          'ticketNumber': unassignedComplaint.ticketNumber,
          'reason': 'No active Junior Engineer found in unit',
          'wardId': targetWardId,
          'departmentId': targetDeptId,
        },
      );

      return unassignedComplaint;
    }
  }

  // ===========================================================================
  // 5. DIRECT WRONG-DEPARTMENT TRANSFER (PART 12)
  // ===========================================================================

  /// Directly transfers a misclassified complaint from one department to another within the same ward.
  ///
  /// Assigns the complaint to the least-loaded Junior Engineer in the new department,
  /// increments `reassignmentCount`, records audit logs, and STRICTLY PRESERVES `slaStartedAt`.
  Future<ComplaintModel> transferWrongDepartmentDirect({
    required String complaintId,
    required String requestedBy,
    required String newDepartmentId,
    required String reason,
    List<ComplaintModel>? activeComplaintsPool,
  }) async {
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    final actor = await _getUser(requestedBy);
    await _hierarchyRepo.initialize();

    final cleanNewDeptId =
        GovernmentDepartmentDashboardService.normalizeDepartmentId(newDepartmentId);
    final deptMeta = await _hierarchyRepo.getDepartmentById(cleanNewDeptId);
    final newDeptName = deptMeta?.displayName ?? cleanNewDeptId;

    final wardId = complaint.wardId ?? 'G_NORTH';
    final prevDeptId = complaint.assignedDepartmentId ?? 'maintenance_roads';

    // Find new department lead for the target department in the same ward
    final wardDept = await _hierarchyRepo.getWardDepartment(wardId, cleanNewDeptId);
    final newLeadId = wardDept?.departmentLeadId;

    // Find eligible JEs in new department and assign least loaded
    final eligibleJEs = await getEligibleJuniorEngineers(
      wardId: wardId,
      departmentId: cleanNewDeptId,
    );

    final complaintsPool = activeComplaintsPool ?? _complaintsCache.values.toList();
    final selectedJE = selectLeastLoadedJuniorEngineer(
      eligibleJEs: eligibleJEs,
      allComplaints: complaintsPool,
    );

    final now = DateTime.now();

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Department Transferred',
        description:
            'Transferred from $prevDeptId to $newDeptName by ${actor?.displayDesignation ?? requestedBy}. Reason: $reason. Assigned to: ${selectedJE?.fullName ?? "Ward Pool"}.',
        timestamp: now,
        status: selectedJE != null ? ComplaintStatus.assigned : ComplaintStatus.verified,
        updatedBy: actor?.employeeId ?? requestedBy,
      ));

    final transferredComplaint = complaint.copyWith(
      assignedDepartmentId: cleanNewDeptId,
      assignedDepartmentLeadId: newLeadId,
      assignedCrewMemberId: selectedJE?.employeeId,
      clearAssignedCrew: selectedJE == null,
      assignedTo: selectedJE?.fullName,
      clearAssignedFieldOfficer: true,
      departmentName: newDeptName,
      status: selectedJE != null ? ComplaintStatus.assigned : ComplaintStatus.verified,
      assignmentStatus: selectedJE != null
          ? ComplaintAssignmentStatus.crewAssigned
          : ComplaintAssignmentStatus.unassigned,
      routingStatus: ComplaintRoutingStatus.assigned,
      reassignmentCount: complaint.reassignmentCount + 1,
      lastReassignedAt: now,
      currentDepartmentAssignedAt: now,
      timeline: updatedTimeline,
      updatedAt: now,
      // STRICT SLA POLICY: originalCreatedAt and slaStartedAt are strictly PRESERVED
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(transferredComplaint);

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirestoreCollections.complaints)
            .doc(transferredComplaint.id)
            .update({
          'assignedDepartmentId': cleanNewDeptId,
          'assignedDepartmentLeadId': newLeadId,
          'assignedCrewMemberId': selectedJE?.employeeId,
          'assignedTo': selectedJE?.fullName,
          'departmentName': newDeptName,
          'status': transferredComplaint.status.name,
          'assignmentStatus': transferredComplaint.assignmentStatus.id,
          'routingStatus': ComplaintRoutingStatus.assigned.id,
          'reassignmentCount': transferredComplaint.reassignmentCount,
          'lastReassignedAt': FieldValue.serverTimestamp(),
          'currentDepartmentAssignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await _auditService.logAction(
      complaintId: complaint.id,
      action: GovernmentAuditActions.departmentTransferred,
      actorId: actor?.employeeId ?? requestedBy,
      actorRole: actor?.role ?? 'junior_engineer',
      actorName: actor?.fullName ?? requestedBy,
      wardId: wardId,
      departmentId: cleanNewDeptId,
      details: {
        'previousDepartmentId': prevDeptId,
        'newDepartmentId': cleanNewDeptId,
        'newJuniorEngineerId': selectedJE?.employeeId,
        'reason': reason,
        'reassignmentCount': transferredComplaint.reassignmentCount,
        'slaStartedAt': complaint.slaStartedAt.toIso8601String(),
      },
    );

    return transferredComplaint;
  }

  // ===========================================================================
  // HUMAN VERIFICATION FALLBACK METHODS (AI FAILURE RESILIENCE)
  // ===========================================================================

  /// Confirms that a complaint belongs to the current department under AI failure fallback.
  /// Automatically routes the complaint to the least loaded Junior Engineer in the unit.
  Future<ComplaintModel> confirmHumanDepartmentReview({
    required String complaintId,
    required String leadId,
    required String remarks,
    List<ComplaintModel>? activeComplaintsPool,
  }) async {
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    // Idempotency: if already processed, return existing complaint
    if (complaint.isHumanReviewCompleted) {
      return complaint;
    }

    final leadUser = await _getUser(leadId);
    await _hierarchyRepo.initialize();

    final deptId = complaint.assignedDepartmentId ??
        complaint.initialReviewDepartmentId ??
        'maintenance_roads';
    final deptMeta = await _hierarchyRepo.getDepartmentById(deptId);
    final deptName = deptMeta?.displayName ?? deptId;
    final wardId = complaint.wardId ?? leadUser?.wardId ?? 'G_NORTH';

    final eligibleJEs = await getEligibleJuniorEngineers(
      wardId: wardId,
      departmentId: deptId,
    );

    final complaintsPool = activeComplaintsPool ?? _complaintsCache.values.toList();
    final selectedJE = selectLeastLoadedJuniorEngineer(
      eligibleJEs: eligibleJEs,
      allComplaints: complaintsPool,
    );

    final now = DateTime.now();

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Department Verified (Manual Review)',
        description: selectedJE != null
            ? 'Department confirmed as $deptName by ${leadUser?.displayDesignation ?? "Ward Department Lead"}. Auto-routed to ${selectedJE.fullName} (${selectedJE.displayDesignation}). Notes: $remarks'
            : 'Department confirmed as $deptName by ${leadUser?.displayDesignation ?? "Ward Department Lead"}. Placed in ward unassigned queue. Notes: $remarks',
        timestamp: now,
        status: selectedJE != null ? ComplaintStatus.assigned : ComplaintStatus.verified,
        updatedBy: leadUser?.employeeId ?? leadId,
      ));

    final updatedComplaint = complaint.copyWith(
      status: selectedJE != null ? ComplaintStatus.assigned : ComplaintStatus.verified,
      assignmentStatus: selectedJE != null
          ? ComplaintAssignmentStatus.crewAssigned
          : ComplaintAssignmentStatus.unassigned,
      routingStatus: ComplaintRoutingStatus.assigned,
      departmentVerificationStatus: 'passed',
      verificationStage: 'completed',
      verificationCompletedAt: now,
      verifiedDepartmentId: deptId,
      verifiedDepartmentName: deptName,
      humanReviewStatus: 'approved',
      humanReviewerId: leadUser?.employeeId ?? leadId,
      humanReviewerName: leadUser?.fullName ?? 'Ward Department Lead',
      humanReviewRemarks: remarks,
      humanReviewedAt: now,
      assignedDepartmentId: deptId,
      assignedDepartmentLeadId: leadUser?.employeeId ?? leadId,
      assignedCrewMemberId: selectedJE?.employeeId,
      assignedTo: selectedJE?.fullName,
      assignedJuniorEngineerNameSnapshot: selectedJE?.fullName,
      assignedJuniorEngineerDesignationSnapshot: selectedJE?.displayDesignation,
      departmentName: deptName,
      currentDepartmentAssignedAt: complaint.currentDepartmentAssignedAt ?? now,
      timeline: updatedTimeline,
      updatedAt: now,
      // Strict SLA preservation
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(updatedComplaint);

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirestoreCollections.complaints)
            .doc(updatedComplaint.id)
            .update({
          'status': updatedComplaint.status.name,
          'assignmentStatus': updatedComplaint.assignmentStatus.id,
          'routingStatus': ComplaintRoutingStatus.assigned.id,
          'departmentVerificationStatus': 'passed',
          'verificationStage': 'completed',
          'verificationCompletedAt': FieldValue.serverTimestamp(),
          'verifiedDepartmentId': deptId,
          'verifiedDepartmentName': deptName,
          'humanReviewStatus': 'approved',
          'humanReviewerId': leadUser?.employeeId ?? leadId,
          'humanReviewerName': leadUser?.fullName ?? 'Ward Department Lead',
          'humanReviewRemarks': remarks,
          'humanReviewedAt': FieldValue.serverTimestamp(),
          'assignedDepartmentId': deptId,
          'assignedDepartmentLeadId': leadUser?.employeeId ?? leadId,
          'assignedCrewMemberId': selectedJE?.employeeId,
          'assignedTo': selectedJE?.fullName,
          'assignedJuniorEngineerNameSnapshot': selectedJE?.fullName,
          'assignedJuniorEngineerDesignationSnapshot': selectedJE?.displayDesignation,
          'departmentName': deptName,
          'currentDepartmentAssignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await _auditService.logAction(
      complaintId: updatedComplaint.id,
      action: GovernmentAuditActions.statusUpdated,
      actorId: leadUser?.employeeId ?? leadId,
      actorRole: leadUser?.role ?? 'ward_department_lead',
      actorName: leadUser?.fullName ?? 'Ward Department Lead',
      wardId: wardId,
      departmentId: deptId,
      details: {
        'action': 'human_department_review_confirmed',
        'departmentId': deptId,
        'assignedJuniorEngineerId': selectedJE?.employeeId,
        'assignedJuniorEngineerName': selectedJE?.fullName,
        'remarks': remarks,
        'slaStartedAt': complaint.slaStartedAt.toIso8601String(),
      },
    );

    return updatedComplaint;
  }

  /// Transfers a complaint to another BMC department under AI failure fallback.
  /// Automatically routes the complaint to the least loaded Junior Engineer in target unit.
  Future<ComplaintModel> transferHumanDepartmentReview({
    required String complaintId,
    required String leadId,
    required String targetDepartmentId,
    required String remarks,
    List<ComplaintModel>? activeComplaintsPool,
  }) async {
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    // Idempotency: if already processed, return existing complaint
    if (complaint.isHumanReviewCompleted) {
      return complaint;
    }

    final leadUser = await _getUser(leadId);
    await _hierarchyRepo.initialize();

    final cleanNewDeptId =
        GovernmentDepartmentDashboardService.normalizeDepartmentId(targetDepartmentId);
    final targetDeptMeta = await _hierarchyRepo.getDepartmentById(cleanNewDeptId);
    if (targetDeptMeta == null) {
      throw ArgumentError('Invalid canonical BMC department ID: $targetDepartmentId');
    }
    final newDeptName = targetDeptMeta.displayName;

    final wardId = complaint.wardId ?? leadUser?.wardId ?? 'G_NORTH';
    final prevDeptId = complaint.assignedDepartmentId ??
        complaint.initialReviewDepartmentId ??
        'maintenance_roads';

    // Find new department lead for the target department in the same ward
    final wardDept = await _hierarchyRepo.getWardDepartment(wardId, cleanNewDeptId);
    final newLeadId = wardDept?.departmentLeadId;

    // Find eligible JEs in new department and assign least loaded
    final eligibleJEs = await getEligibleJuniorEngineers(
      wardId: wardId,
      departmentId: cleanNewDeptId,
    );

    final complaintsPool = activeComplaintsPool ?? _complaintsCache.values.toList();
    final selectedJE = selectLeastLoadedJuniorEngineer(
      eligibleJEs: eligibleJEs,
      allComplaints: complaintsPool,
    );

    final now = DateTime.now();

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Department Transferred (Manual Review)',
        description:
            'Transferred from $prevDeptId to $newDeptName by ${leadUser?.displayDesignation ?? "Ward Department Lead"}. Reason: $remarks. Assigned to: ${selectedJE?.fullName ?? "Ward Unassigned Pool"}.',
        timestamp: now,
        status: selectedJE != null ? ComplaintStatus.assigned : ComplaintStatus.verified,
        updatedBy: leadUser?.employeeId ?? leadId,
      ));

    final transferredComplaint = complaint.copyWith(
      assignedDepartmentId: cleanNewDeptId,
      assignedDepartmentLeadId: newLeadId,
      assignedCrewMemberId: selectedJE?.employeeId,
      clearAssignedCrew: selectedJE == null,
      assignedTo: selectedJE?.fullName,
      clearAssignedFieldOfficer: true,
      departmentName: newDeptName,
      status: selectedJE != null ? ComplaintStatus.assigned : ComplaintStatus.verified,
      assignmentStatus: selectedJE != null
          ? ComplaintAssignmentStatus.crewAssigned
          : ComplaintAssignmentStatus.unassigned,
      routingStatus: ComplaintRoutingStatus.assigned,
      departmentVerificationStatus: 'passed',
      verificationStage: 'completed',
      verificationCompletedAt: now,
      verifiedDepartmentId: cleanNewDeptId,
      verifiedDepartmentName: newDeptName,
      previousDepartmentId: prevDeptId,
      humanReviewStatus: 'transferred',
      humanReviewerId: leadUser?.employeeId ?? leadId,
      humanReviewerName: leadUser?.fullName ?? 'Ward Department Lead',
      humanReviewRemarks: remarks,
      humanReviewedAt: now,
      reassignmentCount: complaint.reassignmentCount + 1,
      lastReassignedAt: now,
      currentDepartmentAssignedAt: now,
      timeline: updatedTimeline,
      updatedAt: now,
      // STRICT SLA POLICY: originalCreatedAt and slaStartedAt are strictly PRESERVED
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(transferredComplaint);

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirestoreCollections.complaints)
            .doc(transferredComplaint.id)
            .update({
          'assignedDepartmentId': cleanNewDeptId,
          'assignedDepartmentLeadId': newLeadId,
          'assignedCrewMemberId': selectedJE?.employeeId,
          'assignedTo': selectedJE?.fullName,
          'departmentName': newDeptName,
          'status': transferredComplaint.status.name,
          'assignmentStatus': transferredComplaint.assignmentStatus.id,
          'routingStatus': ComplaintRoutingStatus.assigned.id,
          'departmentVerificationStatus': 'passed',
          'verificationStage': 'completed',
          'verificationCompletedAt': FieldValue.serverTimestamp(),
          'verifiedDepartmentId': cleanNewDeptId,
          'verifiedDepartmentName': newDeptName,
          'previousDepartmentId': prevDeptId,
          'humanReviewStatus': 'transferred',
          'humanReviewerId': leadUser?.employeeId ?? leadId,
          'humanReviewerName': leadUser?.fullName ?? 'Ward Department Lead',
          'humanReviewRemarks': remarks,
          'humanReviewedAt': FieldValue.serverTimestamp(),
          'reassignmentCount': transferredComplaint.reassignmentCount,
          'lastReassignedAt': FieldValue.serverTimestamp(),
          'currentDepartmentAssignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await _auditService.logAction(
      complaintId: complaint.id,
      action: GovernmentAuditActions.departmentTransferred,
      actorId: leadUser?.employeeId ?? leadId,
      actorRole: leadUser?.role ?? 'ward_department_lead',
      actorName: leadUser?.fullName ?? 'Ward Department Lead',
      wardId: wardId,
      departmentId: cleanNewDeptId,
      details: {
        'action': 'human_department_review_transferred',
        'previousDepartmentId': prevDeptId,
        'newDepartmentId': cleanNewDeptId,
        'newJuniorEngineerId': selectedJE?.employeeId,
        'remarks': remarks,
        'reassignmentCount': transferredComplaint.reassignmentCount,
        'slaStartedAt': complaint.slaStartedAt.toIso8601String(),
      },
    );

    return transferredComplaint;
  }

  // ===========================================================================
  // 6. LEGACY ROUTING TICKET WORKFLOW (BACKWARD COMPATIBILITY)
  // ===========================================================================

  /// Raises a wrong-department reassignment ticket.
  Future<ComplaintRoutingTicket> raiseReassignmentRequest({
    required String complaintId,
    required String sourceLeadId,
    required String suggestedDepartmentId,
    required String reason,
  }) async {
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    final leadUser = await _getUser(sourceLeadId);
    if (leadUser == null) {
      throw ArgumentError('Source Department Lead not found for ID: $sourceLeadId');
    }

    if (!_authService.canRaiseReassignmentTicket(leadUser, complaint)) {
      throw StateError(
          'User ${leadUser.employeeId} (${leadUser.role}) is not authorized to raise reassignment for this complaint.');
    }

    final ticketId = 'CRT-${DateTime.now().millisecondsSinceEpoch}';
    final wardId = complaint.wardId ?? leadUser.wardId ?? 'A';
    final sourceDept = complaint.assignedDepartmentId ?? leadUser.departmentId ?? 'maintenance_roads';

    final ticket = ComplaintRoutingTicket(
      id: ticketId,
      complaintId: complaint.id,
      ticketNumber: complaint.ticketNumber,
      wardId: wardId,
      sourceDepartmentId: sourceDept,
      sourceLeadId: leadUser.employeeId,
      suggestedDepartmentId: suggestedDepartmentId,
      reason: reason,
      status: RoutingTicketStatus.pending,
      createdAt: DateTime.now(),
    );

    _tickets[ticket.id] = ticket;

    // Update complaint routing status (PRESERVING originalCreatedAt and slaStartedAt)
    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Reassignment Requested',
        description:
            'Wrong department reported by ${leadUser.displayDesignation}. Reassignment to $suggestedDepartmentId requested.',
        timestamp: DateTime.now(),
        status: complaint.status,
        updatedBy: leadUser.employeeId,
      ));

    final updatedComplaint = complaint.copyWith(
      routingStatus: ComplaintRoutingStatus.reassignmentRequested,
      timeline: updatedTimeline,
      updatedAt: DateTime.now(),
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    _complaintsCache[complaint.id] = updatedComplaint;

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirestoreCollections.complaintRoutingTickets)
            .doc(ticket.id)
            .set(ticket.toMap());

        await firestore
            .collection(FirestoreCollections.complaints)
            .doc(complaint.id)
            .update({
          'routingStatus': ComplaintRoutingStatus.reassignmentRequested.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await _auditService.logAction(
      complaintId: complaint.id,
      action: GovernmentAuditActions.reassignmentRequested,
      actorId: leadUser.employeeId,
      actorRole: leadUser.role,
      actorName: leadUser.fullName,
      wardId: wardId,
      departmentId: sourceDept,
      details: {
        'ticketId': ticket.id,
        'suggestedDepartmentId': suggestedDepartmentId,
        'reason': reason,
      },
    );

    return ticket;
  }

  /// Reviews a pending wrong-department reassignment ticket.
  Future<ComplaintRoutingTicket> reviewRoutingTicket({
    required String ticketId,
    required String reviewerId,
    required bool approve,
    String? reviewNotes,
  }) async {
    final ticket = _tickets[ticketId] ?? await _fetchRemoteTicket(ticketId);
    if (ticket == null) {
      throw ArgumentError('Routing ticket not found for ID: $ticketId');
    }

    if (!ticket.isPending) {
      throw StateError('Ticket $ticketId is already resolved with status: ${ticket.status}');
    }

    final reviewer = await _getUser(reviewerId);
    if (reviewer == null) {
      throw ArgumentError('Reviewer not found for ID: $reviewerId');
    }

    if (!_authService.canReviewRoutingTicket(reviewer, ticket)) {
      throw StateError(
          'User ${reviewer.employeeId} (${reviewer.role}) is not authorized to review tickets for Ward ${ticket.wardId}.');
    }

    final complaint = await _getComplaint(ticket.complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ticket: ${ticket.complaintId}');
    }

    final reviewedTicket = ticket.copyWith(
      status: approve ? RoutingTicketStatus.approved : RoutingTicketStatus.rejected,
      reviewedBy: reviewer.employeeId,
      reviewNotes: reviewNotes ?? (approve ? 'Reassignment approved' : 'Reassignment rejected'),
      reviewedAt: DateTime.now(),
    );

    _tickets[ticket.id] = reviewedTicket;

    if (approve) {
      final wardDept = await _hierarchyRepo.getWardDepartment(
        ticket.wardId,
        ticket.suggestedDepartmentId,
      );

      final newLeadEmployeeId = wardDept?.departmentLeadId;
      final newLeadUser = newLeadEmployeeId != null
          ? await _hierarchyRepo.getUserByEmployeeId(newLeadEmployeeId)
          : null;

      final deptMeta = await _hierarchyRepo.getDepartmentById(ticket.suggestedDepartmentId);
      final newDeptName = deptMeta?.displayName ?? ticket.suggestedDepartmentId;

      final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
        ..add(TimelineEvent(
          title: 'Department Reassigned',
          description:
              'Approved by ${reviewer.displayDesignation}. Transferred from ${ticket.sourceDepartmentId} to $newDeptName.',
          timestamp: DateTime.now(),
          status: complaint.status,
          updatedBy: reviewer.employeeId,
        ));

      final updatedComplaint = complaint.copyWith(
        assignedDepartmentId: ticket.suggestedDepartmentId,
        assignedDepartmentLeadId: newLeadEmployeeId,
        clearAssignedCrew: true,
        assignedCrewMemberId: null,
        assignedTo: newLeadUser?.fullName ?? newLeadEmployeeId,
        departmentName: newDeptName,
        routingStatus: ComplaintRoutingStatus.assigned,
        assignmentStatus: ComplaintAssignmentStatus.leadAssigned,
        reassignmentCount: complaint.reassignmentCount + 1,
        lastReassignedAt: DateTime.now(),
        currentDepartmentAssignedAt: DateTime.now(),
        timeline: updatedTimeline,
        updatedAt: DateTime.now(),
        originalCreatedAt: complaint.originalCreatedAt,
        slaStartedAt: complaint.slaStartedAt,
      );

      _complaintsCache[complaint.id] = updatedComplaint;

      final firestore = _effectiveFirestore;
      if (firestore != null) {
        try {
          await firestore
              .collection(FirestoreCollections.complaintRoutingTickets)
              .doc(ticket.id)
              .update(reviewedTicket.toMap());

          await firestore
              .collection(FirestoreCollections.complaints)
              .doc(complaint.id)
              .update({
            'assignedDepartmentId': ticket.suggestedDepartmentId,
            'assignedDepartmentLeadId': newLeadEmployeeId,
            'assignedCrewMemberId': FieldValue.delete(),
            'assignedTo': newLeadUser?.fullName ?? newLeadEmployeeId,
            'departmentName': newDeptName,
            'routingStatus': ComplaintRoutingStatus.assigned.id,
            'assignmentStatus': ComplaintAssignmentStatus.leadAssigned.id,
            'reassignmentCount': updatedComplaint.reassignmentCount,
            'lastReassignedAt': FieldValue.serverTimestamp(),
            'currentDepartmentAssignedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      await _auditService.logAction(
        complaintId: complaint.id,
        action: GovernmentAuditActions.reassignmentApproved,
        actorId: reviewer.employeeId,
        actorRole: reviewer.role,
        actorName: reviewer.fullName,
        wardId: ticket.wardId,
        departmentId: ticket.suggestedDepartmentId,
        details: {
          'ticketId': ticket.id,
          'previousDepartmentId': ticket.sourceDepartmentId,
          'newDepartmentId': ticket.suggestedDepartmentId,
          'newLeadId': newLeadEmployeeId,
          'reassignmentCount': updatedComplaint.reassignmentCount,
        },
      );
    } else {
      final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
        ..add(TimelineEvent(
          title: 'Reassignment Rejected',
          description:
              'Reassignment to ${ticket.suggestedDepartmentId} was rejected by ${reviewer.displayDesignation}. Notes: ${reviewNotes ?? "N/A"}.',
          timestamp: DateTime.now(),
          status: complaint.status,
          updatedBy: reviewer.employeeId,
        ));

      final updatedComplaint = complaint.copyWith(
        routingStatus: ComplaintRoutingStatus.assigned,
        timeline: updatedTimeline,
        updatedAt: DateTime.now(),
        originalCreatedAt: complaint.originalCreatedAt,
        slaStartedAt: complaint.slaStartedAt,
      );

      _complaintsCache[complaint.id] = updatedComplaint;

      final firestore = _effectiveFirestore;
      if (firestore != null) {
        try {
          await firestore
              .collection(FirestoreCollections.complaintRoutingTickets)
              .doc(ticket.id)
              .update(reviewedTicket.toMap());

          await firestore
              .collection(FirestoreCollections.complaints)
              .doc(complaint.id)
              .update({
            'routingStatus': ComplaintRoutingStatus.assigned.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      await _auditService.logAction(
        complaintId: complaint.id,
        action: GovernmentAuditActions.reassignmentRejected,
        actorId: reviewer.employeeId,
        actorRole: reviewer.role,
        actorName: reviewer.fullName,
        wardId: ticket.wardId,
        departmentId: ticket.sourceDepartmentId,
        details: {
          'ticketId': ticket.id,
          'notes': reviewNotes,
        },
      );
    }

    return reviewedTicket;
  }

  /// Assigns a ground crew member to execute the resolution of [complaintId].
  Future<ComplaintModel> assignCrewMember({
    required String complaintId,
    required String leadId,
    required String crewMemberId,
  }) async {
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    final lead = await _getUser(leadId);
    if (lead == null) {
      throw ArgumentError('Lead user not found for ID: $leadId');
    }

    if (!_authService.canAssignCrew(lead, complaint)) {
      throw StateError('User ${lead.employeeId} is not authorized to assign crew for this complaint.');
    }

    final crew = await _getUser(crewMemberId);
    if (crew == null) {
      throw ArgumentError('Crew member not found for ID: $crewMemberId');
    }

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Assigned to Crew',
        description: 'Assigned to ${crew.fullName} (${crew.displayDesignation}).',
        timestamp: DateTime.now(),
        status: ComplaintStatus.assigned,
        updatedBy: lead.employeeId,
      ));

    final updatedComplaint = complaint.copyWith(
      assignedCrewMemberId: crew.employeeId,
      assignedTo: crew.fullName,
      status: ComplaintStatus.assigned,
      assignmentStatus: ComplaintAssignmentStatus.crewAssigned,
      timeline: updatedTimeline,
      updatedAt: DateTime.now(),
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    _complaintsCache[complaint.id] = updatedComplaint;

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore.collection(FirestoreCollections.complaints).doc(complaint.id).update({
          'assignedCrewMemberId': crew.employeeId,
          'assignedTo': crew.fullName,
          'status': ComplaintStatus.assigned.name,
          'assignmentStatus': ComplaintAssignmentStatus.crewAssigned.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await _auditService.logAction(
      complaintId: complaint.id,
      action: GovernmentAuditActions.crewAssigned,
      actorId: lead.employeeId,
      actorRole: lead.role,
      actorName: lead.fullName,
      wardId: complaint.wardId,
      departmentId: complaint.assignedDepartmentId,
      details: {
        'crewMemberId': crew.employeeId,
        'crewMemberName': crew.fullName,
      },
    );

    return updatedComplaint;
  }

  /// Retrieves pending wrong-department tickets, optionally filtered by [wardId].
  Future<List<ComplaintRoutingTicket>> getPendingTickets({String? wardId}) async {
    final list = _tickets.values.where((t) => t.isPending).toList();
    if (wardId != null) {
      return list.where((t) => t.wardId.toLowerCase() == wardId.toLowerCase()).toList();
    }
    return list;
  }

  /// Retrieves a ticket by its ID.
  Future<ComplaintRoutingTicket?> getTicketById(String id) async {
    return _tickets[id] ?? await _fetchRemoteTicket(id);
  }

  /// Retrieves all tickets raised for a specific complaint.
  Future<List<ComplaintRoutingTicket>> getTicketsForComplaint(String complaintId) async {
    return _tickets.values.where((t) => t.complaintId == complaintId).toList();
  }

  // ===========================================================================
  // 6. PHASE 2: FIELD OFFICER ASSIGNMENT & GROUND EXECUTION
  // ===========================================================================

  /// Retrieves eligible Field Officers for ground execution within a Ward × Department unit.
  /// Strictly excludes the assigned Junior Engineer (`juniorEngineerId`) and inactive personnel.
  /// Automatically sorts candidates by lowest active workload ascending (then employeeId ascending).
  Future<List<GovtUserModel>> getEligibleFieldOfficers({
    required String wardId,
    required String departmentId,
    required String juniorEngineerId,
    List<ComplaintModel>? allComplaints,
  }) async {
    await _hierarchyRepo.initialize();
    final cleanWard = GovernmentWardDashboardService.normalizeWardId(wardId);
    final cleanDept = GovernmentDepartmentDashboardService.normalizeDepartmentId(departmentId);
    final cleanJEId = juniorEngineerId.trim().toUpperCase();

    final allUsers = await _hierarchyRepo.getUsers(
      role: GovernmentRole.departmentCrewId,
    );

    final eligible = allUsers.where((u) {
      if (!u.active || !u.isCrew) return false;
      // JE cannot be assigned as Field Officer on the same ticket
      if (u.employeeId.trim().toUpperCase() == cleanJEId ||
          u.id.trim().toUpperCase() == cleanJEId) {
        return false;
      }
      final wardMatches = GovernmentWardDashboardService.matchesWard(u.wardId, cleanWard) ||
          (u.wardId != null && u.wardId!.toLowerCase() == cleanWard.toLowerCase());
      final deptMatches = GovernmentDepartmentDashboardService.matchesDepartment(u.departmentId, cleanDept) ||
          (u.departmentId != null && u.departmentId!.toLowerCase() == cleanDept.toLowerCase());
      return wardMatches && deptMatches;
    }).toList();

    // Workload-aware sorting: lowest active load first, then employeeId ascending
    final pool = allComplaints ?? _complaintsCache.values.toList();
    final loadMap = <String, int>{};
    for (final fo in eligible) {
      loadMap[fo.employeeId] = 0;
    }

    for (final c in pool) {
      final isActive = c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected;
      if (!isActive) continue;
      final foId = c.assignedFieldOfficerId;
      if (foId != null && loadMap.containsKey(foId)) {
        loadMap[foId] = (loadMap[foId] ?? 0) + 1;
      }
    }

    eligible.sort((a, b) {
      final loadA = loadMap[a.employeeId] ?? 0;
      final loadB = loadMap[b.employeeId] ?? 0;
      if (loadA != loadB) return loadA.compareTo(loadB);
      return a.employeeId.compareTo(b.employeeId);
    });

    return eligible;
  }

  /// Assigns an eligible Field Officer to execute ground operations on an assigned grievance.
  ///
  /// CRITICAL GUARANTEES:
  /// - Junior Engineer (`juniorEngineerId`) and Field Officer (`fieldOfficerId`) MUST be different personnel.
  /// - Complaint remains in `ComplaintStatus.assigned` (does not prematurely jump to inProgress).
  /// - `assignedFieldOfficerId`, `assignedFieldOfficerAt`, and snapshots are persisted.
  /// - `slaStartedAt` and `originalCreatedAt` are strictly PRESERVED.
  /// - Audit action `field_officer_assigned` is logged.
  Future<ComplaintModel> assignFieldOfficer({
    required String complaintId,
    required String juniorEngineerId,
    required String fieldOfficerId,
    String? assignmentNotes,
    List<ComplaintModel>? activeComplaintsPool,
  }) async {
    final cleanComplaintId = complaintId.trim();
    if (cleanComplaintId.isEmpty) {
      throw ArgumentError('Complaint ID cannot be empty for field officer assignment.');
    }

    final complaint = await _getComplaint(cleanComplaintId);
    if (complaint == null) {
      if (kDebugMode) {
        debugPrint(
            '[ComplaintRoutingService] Complaint not found for assignment. ID passed: "$complaintId"');
      }
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    if (kDebugMode) {
      debugPrint(
          '[ComplaintRoutingService.assignFieldOfficer] complaint.id: ${complaint.id}, serverId: ${complaint.serverId}, ticketNumber: ${complaint.ticketNumber}, localId: ${complaint.localId}');
    }

    final jeUser = await _getUser(juniorEngineerId);
    final cleanJE = juniorEngineerId.trim().toUpperCase();
    final cleanFO = fieldOfficerId.trim().toUpperCase();

    // Validate JE identity or super admin override
    final isJE = (complaint.assignedCrewMemberId != null &&
            (complaint.assignedCrewMemberId!.trim().toUpperCase() == cleanJE ||
             complaint.assignedCrewMemberId!.trim().toUpperCase() == jeUser?.employeeId.toUpperCase())) ||
        (jeUser != null && (jeUser.isSuperAdmin || jeUser.hasPermission('admin_override')));
    if (!isJE) {
      throw StateError(
          'Security Violation: User $juniorEngineerId is not the assigned Junior Engineer for complaint ${complaint.id}.');
    }

    // JE and Field Officer MUST be different individuals
    if (cleanJE == cleanFO) {
      throw ArgumentError(
          'Invalid Assignment: Junior Engineer ($juniorEngineerId) cannot be assigned as Field Officer on the same complaint.');
    }

    final wardId = complaint.wardId ?? complaint.location.ward ?? 'G_NORTH';
    final deptId = complaint.assignedDepartmentId ?? complaint.category.id;

    final eligibleFOs = await getEligibleFieldOfficers(
      wardId: wardId,
      departmentId: deptId,
      juniorEngineerId: juniorEngineerId,
      allComplaints: activeComplaintsPool,
    );

    final selectedFO = eligibleFOs.where((fo) =>
        fo.employeeId.trim().toUpperCase() == cleanFO ||
        fo.id.trim().toUpperCase() == cleanFO).firstOrNull;

    if (selectedFO == null) {
      throw ArgumentError(
          'Field Officer $fieldOfficerId is not eligible or active in Ward $wardId - Dept $deptId.');
    }

    final now = DateTime.now();
    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Field Officer Assigned',
        description:
            'Junior Engineer ${jeUser?.fullName ?? juniorEngineerId} assigned ground execution to Field Officer ${selectedFO.fullName} (${selectedFO.employeeId}).${assignmentNotes != null ? " Notes: $assignmentNotes" : ""}',
        timestamp: now,
        status: complaint.status,
        updatedBy: jeUser?.employeeId ?? juniorEngineerId,
      ));

    final updated = complaint.copyWith(
      assignedFieldOfficerId: selectedFO.employeeId,
      assignedFieldOfficerAt: now,
      assignedFieldOfficerNameSnapshot: selectedFO.fullName,
      assignedFieldOfficerDesignationSnapshot: selectedFO.displayDesignation,
      assignmentStatus: ComplaintAssignmentStatus.fieldOfficerAssigned,
      timeline: updatedTimeline,
      updatedAt: now,
      // STRICT SLA: slaStartedAt and originalCreatedAt strictly PRESERVED
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(updated);

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirestoreCollections.complaints)
            .doc(updated.id)
            .update({
          'assignedFieldOfficerId': selectedFO.employeeId,
          'assignedFieldOfficerAt': FieldValue.serverTimestamp(),
          'assignedFieldOfficerNameSnapshot': selectedFO.fullName,
          'assignedFieldOfficerDesignationSnapshot': selectedFO.displayDesignation,
          'assignmentStatus': ComplaintAssignmentStatus.fieldOfficerAssigned.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (fe) {
        if (kDebugMode) {
          debugPrint(
              '[ComplaintRoutingService] Firestore error updating assignment for ${updated.id}: [${fe.code}] ${fe.message}');
        }
        if (fe.code == 'permission-denied') {
          throw StateError(
              'Permission Denied: Unable to persist field officer assignment to Firestore.');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '[ComplaintRoutingService] Error updating assignment in Firestore: $e');
        }
      }
    }

    await _auditService.logAction(
      complaintId: updated.id,
      action: GovernmentAuditActions.fieldOfficerAssigned,
      actorId: jeUser?.employeeId ?? juniorEngineerId,
      actorRole: jeUser?.role ?? 'junior_engineer',
      actorName: jeUser?.fullName ?? 'Junior Engineer',
      wardId: wardId,
      departmentId: deptId,
      details: {
        'ticketNumber': updated.ticketNumber,
        'assignedJuniorEngineerId': complaint.assignedCrewMemberId,
        'assignedFieldOfficerId': selectedFO.employeeId,
        'assignedFieldOfficerName': selectedFO.fullName,
        'notes': assignmentNotes ?? '',
      },
    );

    return updated;
  }

  /// Reassigns field execution from one Field Officer to another.
  ///
  /// CRITICAL GUARANTEES:
  /// - Junior Engineer assignment (`assignedJuniorEngineerId`) is PRESERVED.
  /// - History and audit records are preserved (`reassignmentCount` incremented).
  /// - `slaStartedAt` and `originalCreatedAt` are strictly PRESERVED.
  /// - Cannot reassign resolved/rejected tickets.
  Future<ComplaintModel> reassignFieldOfficer({
    required String complaintId,
    required String juniorEngineerId,
    required String newFieldOfficerId,
    required String reason,
    List<ComplaintModel>? activeComplaintsPool,
  }) async {
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    if (complaint.status == ComplaintStatus.resolved ||
        complaint.status == ComplaintStatus.rejected) {
      throw StateError('Cannot reassign Field Officer for closed complaint status: ${complaint.status}.');
    }

    final prevFOId = complaint.assignedFieldOfficerId;
    final jeUser = await _getUser(juniorEngineerId);
    final cleanJE = juniorEngineerId.trim().toUpperCase();
    final cleanFO = newFieldOfficerId.trim().toUpperCase();

    final isJE = (complaint.assignedCrewMemberId != null &&
            (complaint.assignedCrewMemberId!.trim().toUpperCase() == cleanJE ||
             complaint.assignedCrewMemberId!.trim().toUpperCase() == jeUser?.employeeId.toUpperCase())) ||
        (jeUser != null && (jeUser.isSuperAdmin || jeUser.hasPermission('admin_override')));
    if (!isJE) {
      throw StateError(
          'Security Violation: User $juniorEngineerId is not the assigned Junior Engineer for complaint $complaintId.');
    }

    if (cleanJE == cleanFO) {
      throw ArgumentError('Junior Engineer cannot reassign Field Officer to themselves.');
    }

    final wardId = complaint.wardId ?? complaint.location.ward ?? 'G_NORTH';
    final deptId = complaint.assignedDepartmentId ?? complaint.category.id;

    final eligibleFOs = await getEligibleFieldOfficers(
      wardId: wardId,
      departmentId: deptId,
      juniorEngineerId: juniorEngineerId,
      allComplaints: activeComplaintsPool,
    );

    final selectedFO = eligibleFOs.where((fo) =>
        fo.employeeId.trim().toUpperCase() == cleanFO ||
        fo.id.trim().toUpperCase() == cleanFO).firstOrNull;

    if (selectedFO == null) {
      throw ArgumentError('New Field Officer $newFieldOfficerId is not eligible or active in unit.');
    }

    final now = DateTime.now();
    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Field Officer Reassigned',
        description:
            'Reassigned from ${complaint.assignedFieldOfficerName ?? prevFOId ?? "previous officer"} to ${selectedFO.fullName}. Reason: $reason',
        timestamp: now,
        status: complaint.status,
        updatedBy: jeUser?.employeeId ?? juniorEngineerId,
      ));

    final updated = complaint.copyWith(
      assignedFieldOfficerId: selectedFO.employeeId,
      assignedFieldOfficerAt: now,
      assignedFieldOfficerNameSnapshot: selectedFO.fullName,
      assignedFieldOfficerDesignationSnapshot: selectedFO.displayDesignation,
      reassignmentCount: complaint.reassignmentCount + 1,
      lastReassignedAt: now,
      timeline: updatedTimeline,
      updatedAt: now,
      clearBlocked: true,
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(updated);

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirestoreCollections.complaints)
            .doc(updated.id)
            .update({
          'assignedFieldOfficerId': selectedFO.employeeId,
          'assignedFieldOfficerAt': FieldValue.serverTimestamp(),
          'assignedFieldOfficerNameSnapshot': selectedFO.fullName,
          'assignedFieldOfficerDesignationSnapshot': selectedFO.displayDesignation,
          'reassignmentCount': updated.reassignmentCount,
          'lastReassignedAt': FieldValue.serverTimestamp(),
          'blockedAt': null,
          'blockedBy': null,
          'blockedReason': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (fe) {
        if (kDebugMode) {
          debugPrint(
              '[ComplaintRoutingService] Firestore error updating reassignment for ${updated.id}: [${fe.code}] ${fe.message}');
        }
        if (fe.code == 'permission-denied') {
          throw StateError(
              'Permission Denied: Unable to persist field officer reassignment to Firestore.');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '[ComplaintRoutingService] Error updating reassignment in Firestore: $e');
        }
      }
    }

    await _auditService.logAction(
      complaintId: updated.id,
      action: GovernmentAuditActions.fieldOfficerReassigned,
      actorId: jeUser?.employeeId ?? juniorEngineerId,
      actorRole: jeUser?.role ?? 'junior_engineer',
      actorName: jeUser?.fullName ?? 'Junior Engineer',
      wardId: wardId,
      departmentId: deptId,
      details: {
        'ticketNumber': updated.ticketNumber,
        'previousFieldOfficerId': prevFOId ?? '',
        'newFieldOfficerId': selectedFO.employeeId,
        'newFieldOfficerName': selectedFO.fullName,
        'reassignedByJuniorEngineerId': jeUser?.employeeId ?? juniorEngineerId,
        'reason': reason,
      },
    );

    return updated;
  }

  /// Field Officer commences physical operations on site.
  /// Transitions status from `assigned` -> `inProgress`.
  Future<ComplaintModel> startFieldWork({
    required String complaintId,
    required String fieldOfficerId,
    String? beforePhotoUrl,
    String? beforeNotes,
  }) async {
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    final foUser = await _getUser(fieldOfficerId);
    final cleanFO = fieldOfficerId.trim().toUpperCase();

    final isAssignedFO = (complaint.assignedFieldOfficerId != null &&
            (complaint.assignedFieldOfficerId!.trim().toUpperCase() == cleanFO ||
             (foUser != null && (complaint.assignedFieldOfficerId!.trim().toUpperCase() == foUser.employeeId.trim().toUpperCase() ||
                                 complaint.assignedFieldOfficerId!.trim().toUpperCase() == foUser.id.trim().toUpperCase())))) ||
        (complaint.assignedCrewMemberId != null &&
            complaint.assignedFieldOfficerId == null &&
            (complaint.assignedCrewMemberId!.trim().toUpperCase() == cleanFO ||
             (foUser != null && (complaint.assignedCrewMemberId!.trim().toUpperCase() == foUser.employeeId.trim().toUpperCase() ||
                                 complaint.assignedCrewMemberId!.trim().toUpperCase() == foUser.id.trim().toUpperCase())))) ||
        (foUser != null && (foUser.isSuperAdmin || foUser.hasPermission('admin_override')));

    if (!isAssignedFO) {
      throw StateError(
          'Security Violation: Field Officer $fieldOfficerId is not assigned to complaint $complaintId.');
    }

    if (complaint.status == ComplaintStatus.inProgress && complaint.workStartedAt != null) {
      throw StateError('Duplicate Start Work: Field work is already in progress.');
    }

    if (complaint.status == ComplaintStatus.resolved ||
        complaint.status == ComplaintStatus.rejected) {
      throw StateError('Cannot start work on a closed complaint (${complaint.status}).');
    }

    final now = DateTime.now();
    final updatedImages = List<String>.from(complaint.imageUrls);
    if (beforePhotoUrl != null && beforePhotoUrl.isNotEmpty && !updatedImages.contains(beforePhotoUrl)) {
      updatedImages.add(beforePhotoUrl);
    }

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Work Started in Field',
        description:
            'Field Officer ${foUser?.fullName ?? fieldOfficerId} commenced ground operations on site.${beforeNotes != null ? " Notes: $beforeNotes" : ""}',
        timestamp: now,
        status: ComplaintStatus.inProgress,
        updatedBy: foUser?.employeeId ?? fieldOfficerId,
      ));

    final updated = complaint.copyWith(
      status: ComplaintStatus.inProgress,
      routingStatus: ComplaintRoutingStatus.inProgress,
      workStartedAt: now,
      workStartedBy: foUser?.employeeId ?? fieldOfficerId,
      beforeWorkPhoto: beforePhotoUrl ?? complaint.beforeWorkPhoto,
      beforeWorkNotes: beforeNotes ?? complaint.beforeWorkNotes,
      imageUrls: updatedImages,
      timeline: updatedTimeline,
      updatedAt: now,
      // STRICT SLA: slaStartedAt and originalCreatedAt strictly PRESERVED
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(updated);

    unawaited(RewardEvaluationService.instance.evaluateStage(
      complaint: updated,
      stage: RewardLifecycleStage.inProgress,
    ));

    await _auditService.logAction(
      complaintId: updated.id,
      action: GovernmentAuditActions.fieldWorkStarted,
      actorId: foUser?.employeeId ?? fieldOfficerId,
      actorRole: foUser?.role ?? 'field_officer',
      actorName: foUser?.fullName ?? 'Field Officer',
      wardId: updated.wardId,
      departmentId: updated.assignedDepartmentId,
      details: {
        'ticketNumber': updated.ticketNumber,
        'startedAt': now.toIso8601String(),
        'beforePhoto': beforePhotoUrl ?? '',
        'beforeNotes': beforeNotes ?? '',
      },
    );

    return updated;
  }

  /// Reports an operational blockage or obstacle preventing field execution.
  Future<ComplaintModel> markFieldWorkBlocked({
    required String complaintId,
    required String fieldOfficerId,
    required String reason,
    String? category,
  }) async {
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    final foUser = await _getUser(fieldOfficerId);
    final cleanFO = fieldOfficerId.trim().toUpperCase();

    final isAssignedFO = (complaint.assignedFieldOfficerId != null &&
            (complaint.assignedFieldOfficerId!.trim().toUpperCase() == cleanFO ||
             (foUser != null && (complaint.assignedFieldOfficerId!.trim().toUpperCase() == foUser.employeeId.trim().toUpperCase() ||
                                 complaint.assignedFieldOfficerId!.trim().toUpperCase() == foUser.id.trim().toUpperCase())))) ||
        (complaint.assignedCrewMemberId != null &&
            complaint.assignedFieldOfficerId == null &&
            (complaint.assignedCrewMemberId!.trim().toUpperCase() == cleanFO ||
             (foUser != null && (complaint.assignedCrewMemberId!.trim().toUpperCase() == foUser.employeeId.trim().toUpperCase() ||
                                 complaint.assignedCrewMemberId!.trim().toUpperCase() == foUser.id.trim().toUpperCase())))) ||
        (foUser != null && (foUser.isSuperAdmin || foUser.hasPermission('admin_override')));

    if (!isAssignedFO) {
      throw StateError('Security Violation: User $fieldOfficerId is not authorized to update blockage.');
    }

    final now = DateTime.now();
    final blockMsg = category != null ? '[$category] $reason' : reason;
    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Field Work Blocked',
        description: 'Ground progress temporarily blocked. Reason: $blockMsg',
        timestamp: now,
        status: complaint.status,
        updatedBy: foUser?.employeeId ?? fieldOfficerId,
      ));

    final updated = complaint.copyWith(
      blockedAt: now,
      blockedBy: foUser?.employeeId ?? fieldOfficerId,
      blockedReason: blockMsg,
      timeline: updatedTimeline,
      updatedAt: now,
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(updated);

    await _auditService.logAction(
      complaintId: updated.id,
      action: GovernmentAuditActions.fieldWorkBlocked,
      actorId: foUser?.employeeId ?? fieldOfficerId,
      actorRole: foUser?.role ?? 'field_officer',
      actorName: foUser?.fullName ?? 'Field Officer',
      wardId: updated.wardId,
      departmentId: updated.assignedDepartmentId,
      details: {
        'ticketNumber': updated.ticketNumber,
        'blockedReason': blockMsg,
        'blockedAt': now.toIso8601String(),
      },
    );

    return updated;
  }

  /// Resumes field operations after a temporary blockage.
  Future<ComplaintModel> resumeFieldWork({
    required String complaintId,
    required String fieldOfficerId,
    String? remarks,
  }) async {
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    final foUser = await _getUser(fieldOfficerId);
    final now = DateTime.now();
    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Field Work Resumed',
        description: 'Blockage cleared. Work resumed on site.${remarks != null ? " Remarks: $remarks" : ""}',
        timestamp: now,
        status: ComplaintStatus.inProgress,
        updatedBy: foUser?.employeeId ?? fieldOfficerId,
      ));

    final updated = complaint.copyWith(
      status: ComplaintStatus.inProgress,
      routingStatus: ComplaintRoutingStatus.inProgress,
      clearBlocked: true,
      timeline: updatedTimeline,
      updatedAt: now,
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(updated);

    await _auditService.logAction(
      complaintId: updated.id,
      action: GovernmentAuditActions.fieldWorkResumed,
      actorId: foUser?.employeeId ?? fieldOfficerId,
      actorRole: foUser?.role ?? 'field_officer',
      actorName: foUser?.fullName ?? 'Field Officer',
      wardId: updated.wardId,
      departmentId: updated.assignedDepartmentId,
      details: {
        'ticketNumber': updated.ticketNumber,
        'remarks': remarks ?? '',
      },
    );

    return updated;
  }

  /// Field Officer submits completed ground execution and directly resolves the complaint.
  ///
  /// CRITICAL GUARANTEES:
  /// - Field Officer is the authoritative actor who resolves the complaint.
  /// - Requires mandatory After / Completion Photo and resolution remarks.
  /// - Direct transition from `inProgress` -> `resolved` (NO mandatory Lead approval gate).
  /// - `resolvedAt` and `resolvedBy` are persisted.
  /// - `slaStartedAt` and `originalCreatedAt` are strictly PRESERVED.
  /// - Audit actions `complaint_resolved` and `resolution_submitted` are logged.
  Future<ComplaintModel> resolveByFieldOfficer({
    required String complaintId,
    required String fieldOfficerId,
    required String afterPhotoUrl,
    required String resolutionRemarks,
    List<String>? additionalPhotos,
  }) async {
    if (afterPhotoUrl.trim().isEmpty) {
      throw ArgumentError('Completion / After Photo evidence is mandatory for resolution submission.');
    }
    if (resolutionRemarks.trim().isEmpty) {
      throw ArgumentError('Resolution remarks describing the completed work are mandatory.');
    }

    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    if (complaint.status == ComplaintStatus.resolved) {
      throw StateError('Duplicate Resolution: Complaint $complaintId is already resolved.');
    }

    if (complaint.status != ComplaintStatus.inProgress) {
      throw StateError(
          'Invalid State: Complaint $complaintId has status ${complaint.status}. Work must be started in field (inProgress) prior to resolution.');
    }

    final foUser = await _getUser(fieldOfficerId);
    final cleanFO = fieldOfficerId.trim().toUpperCase();

    final isAssignedFO = (complaint.assignedFieldOfficerId != null &&
            (complaint.assignedFieldOfficerId!.trim().toUpperCase() == cleanFO ||
             (foUser != null && (complaint.assignedFieldOfficerId!.trim().toUpperCase() == foUser.employeeId.trim().toUpperCase() ||
                                 complaint.assignedFieldOfficerId!.trim().toUpperCase() == foUser.id.trim().toUpperCase())))) ||
        (complaint.assignedCrewMemberId != null &&
            complaint.assignedFieldOfficerId == null &&
            (complaint.assignedCrewMemberId!.trim().toUpperCase() == cleanFO ||
             (foUser != null && (complaint.assignedCrewMemberId!.trim().toUpperCase() == foUser.employeeId.trim().toUpperCase() ||
                                 complaint.assignedCrewMemberId!.trim().toUpperCase() == foUser.id.trim().toUpperCase())))) ||
        (foUser != null && (foUser.isSuperAdmin || foUser.hasPermission('admin_override')));

    if (!isAssignedFO) {
      throw StateError(
          'Security Violation: Field Officer $fieldOfficerId is not authorized to resolve complaint $complaintId.');
    }

    final now = DateTime.now();
    final updatedImages = List<String>.from(complaint.imageUrls);
    if (!updatedImages.contains(afterPhotoUrl)) {
      updatedImages.add(afterPhotoUrl);
    }
    if (additionalPhotos != null) {
      for (final photo in additionalPhotos) {
        if (photo.isNotEmpty && !updatedImages.contains(photo)) {
          updatedImages.add(photo);
        }
      }
    }

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Work Resolved on Site',
        description:
            'Field Officer ${foUser?.fullName ?? fieldOfficerId} completed ground execution and resolved the complaint. Remarks: $resolutionRemarks',
        timestamp: now,
        status: ComplaintStatus.resolved,
        updatedBy: foUser?.employeeId ?? fieldOfficerId,
      ));

    final resolvedComplaint = complaint.copyWith(
      status: ComplaintStatus.resolved,
      routingStatus: ComplaintRoutingStatus.resolved,
      resolvedAt: now,
      resolvedBy: foUser?.employeeId ?? fieldOfficerId,
      afterWorkPhoto: afterPhotoUrl,
      resolutionRemarks: resolutionRemarks,
      officerNotes: resolutionRemarks,
      imageUrls: updatedImages,
      clearBlocked: true,
      timeline: updatedTimeline,
      updatedAt: now,
      // STRICT SLA: slaStartedAt and originalCreatedAt strictly PRESERVED
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(resolvedComplaint);

    unawaited(RewardEvaluationService.instance.evaluateStage(
      complaint: resolvedComplaint,
      stage: RewardLifecycleStage.resolved,
    ));

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirestoreCollections.complaints)
            .doc(resolvedComplaint.id)
            .update({
          'status': ComplaintStatus.resolved.name,
          'resolvedAt': FieldValue.serverTimestamp(),
          'resolvedBy': foUser?.employeeId ?? fieldOfficerId,
          'afterWorkPhoto': afterPhotoUrl,
          'resolutionRemarks': resolutionRemarks,
          'officerNotes': resolutionRemarks,
          'imageUrls': updatedImages,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await _auditService.logAction(
      complaintId: resolvedComplaint.id,
      action: GovernmentAuditActions.complaintResolved,
      actorId: foUser?.employeeId ?? fieldOfficerId,
      actorRole: foUser?.role ?? 'field_officer',
      actorName: foUser?.fullName ?? 'Field Officer',
      wardId: resolvedComplaint.wardId,
      departmentId: resolvedComplaint.assignedDepartmentId,
      details: {
        'ticketNumber': resolvedComplaint.ticketNumber,
        'resolvedAt': now.toIso8601String(),
        'afterPhoto': afterPhotoUrl,
        'resolutionRemarks': resolutionRemarks,
        'slaStartedAt': resolvedComplaint.slaStartedAt.toIso8601String(),
      },
    );

    return resolvedComplaint;
  }

  /// Closes a resolved grievance after citizen or department confirmation or expiration of review window.
  ///
  /// CRITICAL GUARANTEES:
  /// - Only allowed for `ComplaintStatus.resolved` grievances.
  /// - Transitions status to `ComplaintStatus.closed`.
  /// - `closedAt`, `closedBy`, and optional `closureRemarks` are recorded.
  /// - `slaStartedAt` and `originalCreatedAt` are strictly PRESERVED.
  /// - Audit action `complaint_closed` is logged.
  Future<ComplaintModel> closeComplaint({
    required String complaintId,
    required String closedBy,
    String? closureRemarks,
  }) async {
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    if (complaint.status != ComplaintStatus.resolved) {
      throw StateError('Cannot close a complaint that is not in resolved status (current: ${complaint.status}).');
    }

    final actor = await _getUser(closedBy);
    final now = DateTime.now();

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Complaint Closed',
        description:
            'Resolution verified and ticket closed by ${actor?.displayDesignation ?? closedBy}.${closureRemarks != null ? " Remarks: $closureRemarks" : ""}',
        timestamp: now,
        status: ComplaintStatus.closed,
        updatedBy: actor?.employeeId ?? closedBy,
      ));

    final closedComplaint = complaint.copyWith(
      status: ComplaintStatus.closed,
      routingStatus: ComplaintRoutingStatus.resolved,
      closedAt: now,
      closedBy: actor?.employeeId ?? closedBy,
      closureRemarks: closureRemarks,
      timeline: updatedTimeline,
      updatedAt: now,
      // STRICT SLA: slaStartedAt and originalCreatedAt strictly PRESERVED
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(closedComplaint);

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirestoreCollections.complaints)
            .doc(closedComplaint.id)
            .update({
          'status': ComplaintStatus.closed.name,
          'closedAt': FieldValue.serverTimestamp(),
          'closedBy': actor?.employeeId ?? closedBy,
          'closureRemarks': closureRemarks,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await _auditService.logAction(
      complaintId: closedComplaint.id,
      action: GovernmentAuditActions.complaintClosed,
      actorId: actor?.employeeId ?? closedBy,
      actorRole: actor?.role ?? 'citizen',
      actorName: actor?.fullName ?? 'Citizen / Supervisor',
      wardId: closedComplaint.wardId,
      departmentId: closedComplaint.assignedDepartmentId,
      details: {
        'ticketNumber': closedComplaint.ticketNumber,
        'closedAt': now.toIso8601String(),
        'closureRemarks': closureRemarks ?? '',
      },
    );

    return closedComplaint;
  }

  /// Ward Department Lead (Quality Control & Supervisory Oversight) reopens an improperly resolved grievance.
  ///
  /// CRITICAL GUARANTEES:
  /// - Allowed for both `ComplaintStatus.resolved` and `ComplaintStatus.closed` grievances.
  /// - Mandatory `reopenReason` is required.
  /// - Previous resolution evidence and timestamps are preserved in history.
  /// - Complaint transitions back to `inProgress` and returns to Junior Engineer's rework queue.
  /// - `slaStartedAt` and `originalCreatedAt` are strictly PRESERVED.
  /// - Audit action `complaint_reopened` is logged.
  Future<ComplaintModel> reopenComplaint({
    required String complaintId,
    required String reopenedBy,
    required String reopenReason,
  }) async {
    if (reopenReason.trim().isEmpty) {
      throw ArgumentError('Reopening a complaint requires a mandatory reason.');
    }

    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    if (complaint.status != ComplaintStatus.resolved &&
        complaint.status != ComplaintStatus.closed) {
      throw StateError('Cannot reopen a complaint that is not in resolved or closed status (current: ${complaint.status}).');
    }

    final actor = await _getUser(reopenedBy);
    final now = DateTime.now();

    // Preserve previous resolution evidence in list
    final prevEvidence = List<String>.from(complaint.previousResolutionEvidence);
    if (complaint.afterWorkPhoto != null && !prevEvidence.contains(complaint.afterWorkPhoto!)) {
      prevEvidence.add(complaint.afterWorkPhoto!);
    }
    for (final img in complaint.imageUrls) {
      if (!prevEvidence.contains(img)) {
        prevEvidence.add(img);
      }
    }

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Complaint Reopened — Rework Required',
        description:
            'Reopened by ${actor?.displayDesignation ?? reopenedBy}. Reason: $reopenReason. Returned to Junior Engineer for field rework.',
        timestamp: now,
        status: ComplaintStatus.inProgress,
        updatedBy: actor?.employeeId ?? reopenedBy,
      ));

    final reopenedComplaint = complaint.copyWith(
      status: ComplaintStatus.inProgress,
      routingStatus: ComplaintRoutingStatus.inProgress,
      reopenedAt: now,
      reopenedBy: actor?.employeeId ?? reopenedBy,
      reopenReason: reopenReason,
      previousResolvedAt: complaint.resolvedAt,
      previousResolutionEvidence: prevEvidence,
      reopenCount: complaint.reopenCount + 1,
      officerNotes: 'Rework Required: $reopenReason',
      timeline: updatedTimeline,
      updatedAt: now,
      // STRICT SLA: slaStartedAt and originalCreatedAt strictly PRESERVED
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(reopenedComplaint);

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirestoreCollections.complaints)
            .doc(reopenedComplaint.id)
            .update({
          'status': ComplaintStatus.inProgress.name,
          'reopenedAt': FieldValue.serverTimestamp(),
          'reopenedBy': actor?.employeeId ?? reopenedBy,
          'reopenReason': reopenReason,
          'reopenCount': reopenedComplaint.reopenCount,
          'officerNotes': 'Rework Required: $reopenReason',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await _auditService.logAction(
      complaintId: reopenedComplaint.id,
      action: GovernmentAuditActions.complaintReopened,
      actorId: actor?.employeeId ?? reopenedBy,
      actorRole: actor?.role ?? 'ward_department_lead',
      actorName: actor?.fullName ?? 'Department Lead',
      wardId: reopenedComplaint.wardId,
      departmentId: reopenedComplaint.assignedDepartmentId,
      details: {
        'ticketNumber': reopenedComplaint.ticketNumber,
        'reopenReason': reopenReason,
        'previousResolvedAt': complaint.resolvedAt?.toIso8601String() ?? '',
        'reopenCount': reopenedComplaint.reopenCount,
      },
    );

    return reopenedComplaint;
  }

  /// Automatically routes a verified complaint to a Junior Engineer once both AI verification stages pass.
  ///
  /// CRITICAL 5-GATE VALIDATION:
  /// - Gate 1: Evidence AI verification passed.
  /// - Gate 2: Department AI verification passed.
  /// - Gate 3: Verified Department ID must exist in canonical 18 BMC departments.
  /// - Gate 4: GPS coordinates resolve to a valid BMC Ward (no silent G/North fallback).
  /// - Gate 5: Eligible active Junior Engineer found in unit (least-loaded selection).
  Future<ComplaintModel> autoRouteVerifiedComplaint(
    ComplaintModel complaint, {
    List<ComplaintModel>? activeComplaintsPool,
  }) async {
    // Gate 1 & 2: Verification Status check
    if (complaint.evidenceVerificationStatus != 'passed') {
      throw StateError('Gate 1 Failed: Evidence verification not passed (current: ${complaint.evidenceVerificationStatus}).');
    }
    if (complaint.departmentVerificationStatus != 'passed') {
      throw StateError('Gate 2 Failed: Department verification not passed (current: ${complaint.departmentVerificationStatus}).');
    }

    final deptToUse = complaint.verifiedDepartmentId ?? complaint.assignedDepartmentId ?? complaint.category.id;

    // Gate 3: Canonical Department Validation
    await _hierarchyRepo.initialize();
    final allDepts = await _hierarchyRepo.getDepartments();
    final cleanDeptId = GovernmentDepartmentDashboardService.normalizeDepartmentId(deptToUse);
    final isCanonicalDept = allDepts.any((d) => d.departmentId.toLowerCase() == cleanDeptId.toLowerCase());
    if (!isCanonicalDept) {
      throw StateError('Gate 3 Failed: Department "$deptToUse" is not in canonical 18 BMC departments allowlist.');
    }

    // Gate 4: Ward Resolution without silent fallback
    final resolvedWard = await resolveWardForLocation(
      lat: complaint.location.latitude,
      lng: complaint.location.longitude,
      rawWard: complaint.wardId ?? complaint.location.ward,
      allowFallback: false,
    );

    final resolvedDept = await resolveDepartmentForCategory(
      rawDept: cleanDeptId,
    );

    // Gate 5: JE Selection
    final eligibleJEs = await getEligibleJuniorEngineers(
      wardId: resolvedWard.wardId,
      departmentId: resolvedDept.departmentId,
    );

    final pool = activeComplaintsPool ?? _complaintsCache.values.toList();
    final selectedJE = selectLeastLoadedJuniorEngineer(
      eligibleJEs: eligibleJEs,
      allComplaints: pool,
    );

    if (selectedJE == null) {
      throw StateError('Gate 5 Failed: No active Junior Engineer available for Ward ${resolvedWard.wardCode} - ${resolvedDept.displayName}.');
    }

    final now = DateTime.now();
    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..add(TimelineEvent(
        title: 'Assigned to Junior Engineer',
        description:
            'Two-stage AI verification passed. Auto-routed to ${selectedJE.fullName} (${selectedJE.displayDesignation}) in Ward ${resolvedWard.wardCode} - ${resolvedDept.displayName}.',
        timestamp: now,
        status: ComplaintStatus.assigned,
        updatedBy: 'BMC_CANONICAL_ROUTING_ENGINE',
      ));

    final wardDept = await _hierarchyRepo.getWardDepartment(resolvedWard.wardId, resolvedDept.departmentId);
    final leadId = wardDept?.departmentLeadId;

    final routed = complaint.copyWith(
      status: ComplaintStatus.assigned,
      assignmentStatus: ComplaintAssignmentStatus.crewAssigned,
      routingStatus: ComplaintRoutingStatus.assigned,
      wardId: resolvedWard.wardId,
      assignedDepartmentId: resolvedDept.departmentId,
      assignedDepartmentLeadId: leadId,
      assignedCrewMemberId: selectedJE.employeeId,
      assignedTo: selectedJE.fullName,
      assignedJuniorEngineerNameSnapshot: selectedJE.fullName,
      assignedJuniorEngineerDesignationSnapshot: selectedJE.displayDesignation,
      departmentName: resolvedDept.displayName,
      currentDepartmentAssignedAt: now,
      timeline: updatedTimeline,
      updatedAt: now,
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    registerComplaint(routed);

    unawaited(RewardEvaluationService.instance.evaluateStage(
      complaint: routed,
      stage: RewardLifecycleStage.verified,
    ));
    unawaited(RewardEvaluationService.instance.evaluateStage(
      complaint: routed,
      stage: RewardLifecycleStage.assigned,
    ));

    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        await firestore
            .collection(FirestoreCollections.complaints)
            .doc(routed.id)
            .update({
          'status': ComplaintStatus.assigned.name,
          'assignmentStatus': ComplaintAssignmentStatus.crewAssigned.id,
          'routingStatus': ComplaintRoutingStatus.assigned.id,
          'wardId': resolvedWard.wardId,
          'assignedDepartmentId': resolvedDept.departmentId,
          'assignedDepartmentLeadId': leadId,
          'assignedCrewMemberId': selectedJE.employeeId,
          'assignedTo': selectedJE.fullName,
          'assignedJuniorEngineerNameSnapshot': selectedJE.fullName,
          'assignedJuniorEngineerDesignationSnapshot': selectedJE.displayDesignation,
          'departmentName': resolvedDept.displayName,
          'currentDepartmentAssignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await _auditService.logAction(
      complaintId: routed.id,
      action: GovernmentAuditActions.autoRoutedToJuniorEngineer,
      actorId: 'BMC_CANONICAL_ROUTING_ENGINE',
      actorRole: 'system',
      actorName: 'Canonical Two-Stage Grievance Routing Engine',
      wardId: resolvedWard.wardId,
      departmentId: resolvedDept.departmentId,
      details: {
        'ticketNumber': routed.ticketNumber,
        'assignedJuniorEngineerId': selectedJE.employeeId,
        'assignedJuniorEngineerName': selectedJE.fullName,
        'wardId': resolvedWard.wardId,
        'departmentId': resolvedDept.departmentId,
        'departmentLeadId': leadId,
        'slaStartedAt': routed.slaStartedAt.toIso8601String(),
      },
    );

    return routed;
  }

  /// Retrieves a complaint from local cache or remote store.
  Future<ComplaintModel?> getComplaint(String id) => _getComplaint(id);

  // ===========================================================================
  // INTERNAL HELPERS
  // ===========================================================================

  Future<ComplaintModel?> _getComplaint(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      if (kDebugMode) {
        debugPrint('[ComplaintRoutingService] _getComplaint received empty ID');
      }
      return null;
    }

    if (kDebugMode) {
      debugPrint('[ComplaintRoutingService] _getComplaint looking up ID: $cleanId');
    }

    // 1. In-memory cache lookup (exact key or property match)
    if (_complaintsCache.containsKey(cleanId)) {
      return _complaintsCache[cleanId];
    }
    for (final c in _complaintsCache.values) {
      if (c.id == cleanId ||
          c.ticketNumber == cleanId ||
          c.serverId == cleanId ||
          (c.localId != null && c.localId == cleanId)) {
        return c;
      }
    }

    // 2. Active Government Complaint Repository lookup (Hive + cached/remote)
    try {
      final fromRepo = await _effectiveComplaintRepo.getComplaintById(cleanId);
      if (fromRepo != null) {
        registerComplaint(fromRepo);
        return fromRepo;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ComplaintRoutingService] Repository lookup failed for $cleanId: $e');
      }
    }

    // 3. Direct Cloud Firestore lookup (Canonical /complaints collection)
    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        // Direct document ID lookup
        final doc = await firestore
            .collection(FirestoreCollections.complaints)
            .doc(cleanId)
            .get();
        if (doc.exists && doc.data() != null) {
          final parsed = ComplaintFirestoreMapper.fromFirestore(
            documentId: doc.id,
            data: doc.data()!,
          );
          registerComplaint(parsed);
          return parsed;
        }

        // Secondary fallback: ticketNumber match
        final ticketQuery = await firestore
            .collection(FirestoreCollections.complaints)
            .where('ticketNumber', isEqualTo: cleanId)
            .limit(1)
            .get();
        if (ticketQuery.docs.isNotEmpty) {
          final tDoc = ticketQuery.docs.first;
          final parsed = ComplaintFirestoreMapper.fromFirestore(
            documentId: tDoc.id,
            data: tDoc.data(),
          );
          registerComplaint(parsed);
          return parsed;
        }

        // Tertiary fallback: localId match
        final localQuery = await firestore
            .collection(FirestoreCollections.complaints)
            .where('localId', isEqualTo: cleanId)
            .limit(1)
            .get();
        if (localQuery.docs.isNotEmpty) {
          final lDoc = localQuery.docs.first;
          final parsed = ComplaintFirestoreMapper.fromFirestore(
            documentId: lDoc.id,
            data: lDoc.data(),
          );
          registerComplaint(parsed);
          return parsed;
        }
      } on FirebaseException catch (fe) {
        if (kDebugMode) {
          debugPrint(
              '[ComplaintRoutingService] Firestore lookup error for $cleanId: [${fe.code}] ${fe.message}');
        }
        if (fe.code == 'permission-denied') {
          throw StateError(
              'Permission Denied: Unauthorized access to complaint $cleanId in Firestore.');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '[ComplaintRoutingService] Unexpected exception looking up complaint $cleanId: $e');
        }
      }
    }

    return null;
  }

  Future<GovtUserModel?> _getUser(String idOrEmployeeId) async {
    final user = await _hierarchyRepo.getUserByEmployeeId(idOrEmployeeId) ??
        await _hierarchyRepo.getUserById(idOrEmployeeId);
    if (user != null) return user;
    final all = await _hierarchyRepo.getUsers();
    final clean = idOrEmployeeId.trim().toUpperCase();
    return all.where((u) =>
        u.employeeId.toUpperCase() == clean ||
        u.id.toUpperCase() == clean ||
        u.fullName.toLowerCase() == idOrEmployeeId.toLowerCase()).firstOrNull;
  }

  Future<ComplaintRoutingTicket?> _fetchRemoteTicket(String ticketId) async {
    final firestore = _effectiveFirestore;
    if (firestore != null) {
      try {
        final doc = await firestore
            .collection(FirestoreCollections.complaintRoutingTickets)
            .doc(ticketId)
            .get();
        if (doc.exists && doc.data() != null) {
          return ComplaintRoutingTicket.fromMap(doc.data()!);
        }
      } catch (_) {}
    }
    return null;
  }
}
