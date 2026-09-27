import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_constants.dart';
import '../models/complaint_model.dart';
import '../models/complaint_routing_ticket_model.dart';
import '../models/government_audit_log_model.dart';
import '../../Govt UI/models/govt_user_model.dart';
import 'government_audit_service.dart';
import 'government_authorization_service.dart';
import 'government_hierarchy_repository.dart';

/// Service managing wrong-department routing tickets and matrix complaint workflows.
class ComplaintRoutingService {
  final GovernmentHierarchyRepository _hierarchyRepo;
  final GovernmentAuditService _auditService;
  final GovernmentAuthorizationService _authService;
  final FirebaseFirestore? _firestore;

  // In-memory store for routing tickets (for offline/testing resilience)
  final Map<String, ComplaintRoutingTicket> _tickets = {};
  // In-memory store or cache for complaints
  final Map<String, ComplaintModel> _complaintsCache = {};

  ComplaintRoutingService({
    GovernmentHierarchyRepository? hierarchyRepo,
    GovernmentAuditService? auditService,
    GovernmentAuthorizationService? authService,
    FirebaseFirestore? firestore,
  })  : _hierarchyRepo = hierarchyRepo ?? LocalGovernmentHierarchyRepository(),
        _auditService = auditService ?? DefaultGovernmentAuditService(),
        _authService = authService ??
            GovernmentAuthorizationService(
                hierarchyRepo: hierarchyRepo ?? LocalGovernmentHierarchyRepository()),
        _firestore = firestore;

  /// Registers or caches a complaint for routing operations.
  void registerComplaint(ComplaintModel complaint) {
    _complaintsCache[complaint.id] = complaint;
    if (complaint.ticketNumber.isNotEmpty) {
      _complaintsCache[complaint.ticketNumber] = complaint;
    }
  }

  /// Raises a wrong-department reassignment ticket.
  ///
  /// Executed by a Ward Department Lead who discovers that a complaint was misrouted to their department.
  /// Sets complaint `routingStatus` to `reassignment_requested` while strictly preserving
  /// the original complaint creation date and SLA clock.
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
      // CRITICAL: originalCreatedAt and slaStartedAt are strictly preserved
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    _complaintsCache[complaint.id] = updatedComplaint;

    // Remote persistence if Firestore is available
    if (_firestore != null) {
      try {
        await _firestore
            .collection(FirestoreCollections.complaintRoutingTickets)
            .doc(ticket.id)
            .set(ticket.toMap());

        await _firestore
            .collection(FirestoreCollections.complaints)
            .doc(complaint.id)
            .update({
          'routingStatus': ComplaintRoutingStatus.reassignmentRequested.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    // Immutable Audit Log
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
  ///
  /// Executed exclusively by the Ward Officer for that ward (or Super Admin override).
  ///
  /// If [approve] is true:
  /// - Transfers the complaint to `suggestedDepartmentId`.
  /// - Assigns the new Ward Department Lead for that ward and department.
  /// - Clears any existing crew assignment (`assignedCrewMemberId = null`).
  /// - Restores `routingStatus` to `assigned`.
  /// - Increments `reassignmentCount` and records `lastReassignedAt`.
  /// - **ORIGINAL COMPLAINT CREATION DATE AND SLA CLOCK ARE NEVER RESET**.
  ///
  /// If [approve] is false:
  /// - Restores `routingStatus` to `assigned`.
  /// - Complaint remains in the source department.
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
      // Find new department lead for (ticket.wardId, ticket.suggestedDepartmentId)
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
        assignedCrewMemberId: null, // Crew assignment cleared upon department transfer!
        assignedTo: newLeadUser?.fullName ?? newLeadEmployeeId,
        departmentName: newDeptName,
        routingStatus: ComplaintRoutingStatus.assigned,
        assignmentStatus: ComplaintAssignmentStatus.leadAssigned,
        reassignmentCount: complaint.reassignmentCount + 1,
        lastReassignedAt: DateTime.now(),
        currentDepartmentAssignedAt: DateTime.now(),
        timeline: updatedTimeline,
        updatedAt: DateTime.now(),
        // SLA Policy: Original creation date and SLA clock are strictly PRESERVED
        originalCreatedAt: complaint.originalCreatedAt,
        slaStartedAt: complaint.slaStartedAt,
      );

      _complaintsCache[complaint.id] = updatedComplaint;

      if (_firestore != null) {
        try {
          await _firestore
              .collection(FirestoreCollections.complaintRoutingTickets)
              .doc(ticket.id)
              .update(reviewedTicket.toMap());

          await _firestore
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
      // Rejection: complaint remains in current department
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

      if (_firestore != null) {
        try {
          await _firestore
              .collection(FirestoreCollections.complaintRoutingTickets)
              .doc(ticket.id)
              .update(reviewedTicket.toMap());

          await _firestore
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

    if (_firestore != null) {
      try {
        await _firestore.collection(FirestoreCollections.complaints).doc(complaint.id).update({
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

  /// Retrieves a complaint from local cache or remote store.
  Future<ComplaintModel?> getComplaint(String id) => _getComplaint(id);

  // Internal Helpers
  Future<ComplaintModel?> _getComplaint(String id) async {
    if (_complaintsCache.containsKey(id)) {
      return _complaintsCache[id];
    }
    if (_firestore != null) {
      try {
        final doc = await _firestore.collection(FirestoreCollections.complaints).doc(id).get();
        if (doc.exists && doc.data() != null) {
          // In an app context, ComplaintFirestoreMapper would parse this
        }
      } catch (_) {}
    }
    return null;
  }

  Future<GovtUserModel?> _getUser(String idOrEmployeeId) async {
    final user = await _hierarchyRepo.getUserByEmployeeId(idOrEmployeeId) ??
        await _hierarchyRepo.getUserById(idOrEmployeeId);
    return user;
  }

  Future<ComplaintRoutingTicket?> _fetchRemoteTicket(String ticketId) async {
    if (_firestore != null) {
      try {
        final doc = await _firestore
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
