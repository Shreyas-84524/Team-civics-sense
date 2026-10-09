import * as admin from 'firebase-admin';
import {
  getDepartmentById,
  isValidDepartmentId,
  resolveWardForLocation,
} from './departments';

export interface GovtUserRecord {
  id: string;
  employeeId: string;
  fullName: string;
  role: string;
  displayDesignation?: string;
  wardId?: string;
  departmentId?: string;
  active: boolean;
}

export interface RoutingResult {
  success: boolean;
  assignedJuniorEngineer?: GovtUserRecord;
  wardId: string;
  departmentId: string;
  departmentName: string;
  message: string;
}

/**
 * Executes Automated Ward + Junior Engineer Routing adhering strictly to the 5 Canonical Gating Rules:
 * Gate 1: Evidence AI verification passed.
 * Gate 2: Department AI verification passed.
 * Gate 3: Verified Department ID is strictly within canonical 18 BMC allowlist.
 * Gate 4: GPS coordinates resolve to a valid BMC Ward (no silent G/North fallback).
 * Gate 5: Selects least-loaded Junior Engineer in unit with deterministic tie-breaking.
 */
export async function autoRouteVerifiedComplaint(
  db: admin.firestore.Firestore,
  complaintId: string,
  complaintData: Record<string, any>,
  verifiedDeptId: string,
  verifiedDeptName: string
): Promise<RoutingResult> {
  // Gate 1: Evidence Verification Check
  if (complaintData.evidenceVerificationStatus !== 'passed') {
    throw new Error(
      `Gate 1 Failed: Evidence verification not passed (${complaintData.evidenceVerificationStatus}).`
    );
  }

  // Gate 2: Department Verification Check
  if (complaintData.departmentVerificationStatus !== 'passed') {
    throw new Error(
      `Gate 2 Failed: Department verification not passed (${complaintData.departmentVerificationStatus}).`
    );
  }

  // Gate 3: Canonical 18 BMC Department Allowlist Check
  if (!isValidDepartmentId(verifiedDeptId)) {
    throw new Error(
      `Gate 3 Failed: Department "${verifiedDeptId}" is not in the canonical 18 BMC departments allowlist.`
    );
  }

  const deptMeta = getDepartmentById(verifiedDeptId);
  const deptDisplayName = deptMeta?.displayName || verifiedDeptName;

  // Gate 4: Ward Resolution without silent fallback
  const location = complaintData.location || {};
  const lat = typeof location.latitude === 'number' ? location.latitude : undefined;
  const lng = typeof location.longitude === 'number' ? location.longitude : undefined;
  const rawWard = (complaintData.wardId || location.ward || '') as string;

  const resolvedWard = resolveWardForLocation(lat, lng, rawWard);
  if (!resolvedWard) {
    throw new Error(
      `Gate 4 Failed: Cannot resolve valid BMC Ward for coordinates (${lat}, ${lng}). Geofence boundary exceeded.`
    );
  }

  // Gate 5: Query Eligible Junior Engineers in Ward x Department
  const usersSnapshot = await db
    .collection('government_users')
    .where('active', '==', true)
    .where('role', 'in', ['department_crew', 'junior_engineer', 'ward_department_crew'])
    .get();

  const eligibleJEs: GovtUserRecord[] = [];
  usersSnapshot.forEach((doc) => {
    const data = doc.data();
    const matchesWard =
      (data.wardId && data.wardId.toUpperCase() === resolvedWard.wardId.toUpperCase()) ||
      (data.wardId && data.wardId.toUpperCase() === resolvedWard.wardCode.toUpperCase());
    const matchesDept =
      data.departmentId && data.departmentId.toLowerCase() === verifiedDeptId.toLowerCase();

    if (matchesWard && matchesDept) {
      eligibleJEs.push({
        id: doc.id,
        employeeId: data.employeeId || doc.id,
        fullName: data.fullName || 'Junior Engineer',
        role: data.role || 'department_crew',
        displayDesignation: data.displayDesignation || data.designation || 'Junior Engineer',
        wardId: data.wardId,
        departmentId: data.departmentId,
        active: data.active !== false,
      });
    }
  });

  // Sort deterministically by employeeId ascending
  eligibleJEs.sort((a, b) => a.employeeId.localeCompare(b.employeeId));

  let selectedJE: GovtUserRecord | undefined;

  if (eligibleJEs.length === 1) {
    selectedJE = eligibleJEs[0];
  } else if (eligibleJEs.length > 1) {
    // Workload-aware least loaded selection
    const loadMap = new Map<string, number>();
    for (const je of eligibleJEs) {
      loadMap.set(je.employeeId, 0);
    }

    const activeComplaintsSnapshot = await db
      .collection('complaints')
      .where('assignedDepartmentId', '==', verifiedDeptId)
      .where('status', 'in', ['assigned', 'inProgress'])
      .get();

    activeComplaintsSnapshot.forEach((doc) => {
      const cData = doc.data();
      const assignedId = cData.assignedCrewMemberId || cData.assignedJuniorEngineerId;
      if (assignedId && loadMap.has(assignedId)) {
        loadMap.set(assignedId, (loadMap.get(assignedId) || 0) + 1);
      }
    });

    let minLoad = Infinity;
    for (const count of loadMap.values()) {
      if (count < minLoad) minLoad = count;
    }

    const leastLoadedCandidates = eligibleJEs.filter(
      (je) => (loadMap.get(je.employeeId) || 0) === minLoad
    );
    leastLoadedCandidates.sort((a, b) => a.employeeId.localeCompare(b.employeeId));
    selectedJE = leastLoadedCandidates[0];
  }

  const now = new Date();
  const ticketNumber = complaintData.ticketNumber || `CF-${complaintId.substring(0, 6).toUpperCase()}`;

  if (selectedJE) {
    // Atomically assign to Junior Engineer and transition status to 'assigned'
    const batch = db.batch();
    const complaintRef = db.collection('complaints').doc(complaintId);

    const timelineEntry = {
      title: 'Assigned to Junior Engineer',
      description: `Two-stage AI verification passed. Auto-routed to ${selectedJE.fullName} (${selectedJE.displayDesignation}) in Ward ${resolvedWard.wardCode} - ${deptDisplayName}.`,
      timestamp: admin.firestore.Timestamp.fromDate(now),
      status: 'assigned',
      updatedBy: 'BMC_AUTO_ROUTING_ENGINE',
    };

    const currentTimeline = Array.isArray(complaintData.timeline) ? [...complaintData.timeline] : [];
    currentTimeline.push(timelineEntry);

    batch.update(complaintRef, {
      status: 'assigned',
      assignmentStatus: 'crewAssigned',
      routingStatus: 'assigned',
      wardId: resolvedWard.wardId,
      assignedDepartmentId: verifiedDeptId,
      departmentName: deptDisplayName,
      assignedCrewMemberId: selectedJE.employeeId,
      assignedJuniorEngineerId: selectedJE.employeeId,
      assignedTo: selectedJE.fullName,
      assignedJuniorEngineerNameSnapshot: selectedJE.fullName,
      assignedJuniorEngineerDesignationSnapshot: selectedJE.displayDesignation,
      currentDepartmentAssignedAt: admin.firestore.FieldValue.serverTimestamp(),
      timeline: currentTimeline,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Write timeline audit record to subcollection
    const updateRef = complaintRef.collection('complaint_updates').doc();
    batch.set(updateRef, {
      id: updateRef.id,
      title: timelineEntry.title,
      description: timelineEntry.description,
      status: 'assigned',
      timestamp: admin.firestore.Timestamp.fromDate(now),
      updatedBy: 'BMC_AUTO_ROUTING_ENGINE',
    });

    // Write government audit log
    const auditRef = db.collection('government_audit_logs').doc();
    batch.set(auditRef, {
      id: auditRef.id,
      complaintId,
      action: 'auto_routed_to_junior_engineer',
      actorId: 'BMC_AUTO_ROUTING_ENGINE',
      actorRole: 'system',
      actorName: 'Automated Grievance Routing Engine',
      wardId: resolvedWard.wardId,
      departmentId: verifiedDeptId,
      details: {
        ticketNumber,
        assignedJuniorEngineerId: selectedJE.employeeId,
        assignedJuniorEngineerName: selectedJE.fullName,
        wardId: resolvedWard.wardId,
        departmentId: verifiedDeptId,
        slaStartedAt: complaintData.slaStartedAt || now.toISOString(),
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return {
      success: true,
      assignedJuniorEngineer: selectedJE,
      wardId: resolvedWard.wardId,
      departmentId: verifiedDeptId,
      departmentName: deptDisplayName,
      message: `Auto-routed to ${selectedJE.fullName} in Ward ${resolvedWard.wardCode} - ${deptDisplayName}.`,
    };
  } else {
    // Safe Fallback: No eligible active JE found for unit. Update metadata and flag alert.
    const complaintRef = db.collection('complaints').doc(complaintId);
    await complaintRef.update({
      wardId: resolvedWard.wardId,
      assignedDepartmentId: verifiedDeptId,
      departmentName: deptDisplayName,
      routingStatus: 'unassigned',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: false,
      wardId: resolvedWard.wardId,
      departmentId: verifiedDeptId,
      departmentName: deptDisplayName,
      message: `No active Junior Engineer found for Ward ${resolvedWard.wardCode} - ${deptDisplayName}. Escalated to lead queue.`,
    };
  }
}
