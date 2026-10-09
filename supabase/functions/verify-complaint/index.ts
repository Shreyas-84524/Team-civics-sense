import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { verifyFirebaseIdToken } from "../_shared/firebase-auth.ts";
import { createComplaintFirestore } from "../_shared/complaint-firestore.ts";
import { verifyDepartment, verifyEvidence } from "../_shared/complaint-gemini.ts";
import { resolveWardForLocation } from "../_shared/departments.ts";

declare const EdgeRuntime: { waitUntil(promise: Promise<unknown>): void };

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function reply(status: number, data: Record<string, unknown>) {
  return new Response(JSON.stringify(data), { status, headers: cors });
}

function object(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

function text(value: unknown): string {
  return typeof value === "string" ? value : "";
}

async function writeUpdate(
  db: Awaited<ReturnType<typeof createComplaintFirestore>>,
  complaintId: string,
  step: string,
  title: string,
  description: string,
  status = "underVerification",
) {
  const path = `complaints/${complaintId}/complaint_updates/ai_${step}`;
  await db.patch(path, {
    id: `ai_${step}`,
    complaintId,
    title,
    description,
    status,
    timestamp: new Date(),
    updatedBy: "system_ai_verifier",
  });
}

async function routeComplaint(
  db: Awaited<ReturnType<typeof createComplaintFirestore>>,
  complaintId: string,
  complaint: Record<string, unknown>,
  departmentId: string,
  departmentName: string,
) {
  const location = object(complaint.location);
  const ward = resolveWardForLocation(
    typeof location.latitude === "number" ? location.latitude : undefined,
    typeof location.longitude === "number" ? location.longitude : undefined,
    text(complaint.wardId || location.ward),
  );
  if (!ward) {
    await db.patch(`complaints/${complaintId}`, {
      status: "verified",
      routingStatus: "unassigned",
      citizenSafeVerificationMessage: "Verification passed. Location needs manual assignment.",
      updatedAt: new Date(),
    });
    return;
  }

  const users = await db.list("government_users");
  const engineers = users.filter((doc) => {
    const user = doc.data;
    const wardId = text(user.wardId).toUpperCase();
    return user.active === true &&
      ["department_crew", "junior_engineer", "ward_department_crew"].includes(text(user.role)) &&
      (wardId === ward.wardId.toUpperCase() || wardId === ward.wardCode.toUpperCase()) &&
      text(user.departmentId).toLowerCase() === departmentId;
  });

  if (!engineers.length) {
    await db.patch(`complaints/${complaintId}`, {
      status: "verified",
      wardId: ward.wardId,
      assignedDepartmentId: departmentId,
      departmentName,
      routingStatus: "unassigned",
      citizenSafeVerificationMessage: "Verification passed. Waiting for a department officer to be assigned.",
      updatedAt: new Date(),
    });
    await writeUpdate(db, complaintId, "routing_pending", "Awaiting Officer Assignment", "Verification passed; no eligible Junior Engineer is currently available.", "verified");
    return;
  }

  const complaints = await db.list("complaints");
  const workload = new Map<string, number>();
  for (const engineer of engineers) {
    workload.set(text(engineer.data.employeeId) || engineer.name.split("/").pop()!, 0);
  }
  for (const item of complaints) {
    const data = item.data;
    if (data.assignedDepartmentId !== departmentId ||
        !["assigned", "inProgress"].includes(text(data.status))) continue;
    const assigned = text(data.assignedCrewMemberId || data.assignedJuniorEngineerId);
    if (workload.has(assigned)) workload.set(assigned, workload.get(assigned)! + 1);
  }
  engineers.sort((a, b) => {
    const idA = text(a.data.employeeId) || a.name.split("/").pop()!;
    const idB = text(b.data.employeeId) || b.name.split("/").pop()!;
    return workload.get(idA)! - workload.get(idB)! || idA.localeCompare(idB);
  });
  const selected = engineers[0].data;
  const employeeId = text(selected.employeeId) || engineers[0].name.split("/").pop()!;
  const name = text(selected.fullName) || "Junior Engineer";
  const designation = text(selected.displayDesignation || selected.designation) || "Junior Engineer";
  await db.patch(`complaints/${complaintId}`, {
    status: "assigned",
    assignmentStatus: "crewAssigned",
    routingStatus: "assigned",
    wardId: ward.wardId,
    assignedDepartmentId: departmentId,
    departmentName,
    assignedCrewMemberId: employeeId,
    assignedJuniorEngineerId: employeeId,
    assignedTo: name,
    assignedJuniorEngineerNameSnapshot: name,
    assignedJuniorEngineerDesignationSnapshot: designation,
    currentDepartmentAssignedAt: new Date(),
    citizenSafeVerificationMessage: "Verification passed and a Junior Engineer was assigned.",
    updatedAt: new Date(),
  });
  await writeUpdate(
    db,
    complaintId,
    "assigned",
    "Assigned to Junior Engineer",
    `Verified and assigned to ${name} (${designation}) in Ward ${ward.wardCode} - ${departmentName}.`,
    "assigned",
  );
}

async function processComplaint(
  db: Awaited<ReturnType<typeof createComplaintFirestore>>,
  complaintId: string,
  complaint: Record<string, unknown>,
) {
  const path = `complaints/${complaintId}`;
  const input = {
    title: text(complaint.title),
    description: text(complaint.description),
    category: complaint.category as { id?: string; name?: string } | string | undefined,
    imageUrls: Array.isArray(complaint.imageUrls)
      ? complaint.imageUrls.filter((url): url is string => typeof url === "string")
      : [],
  };
  try {
    const evidence = await verifyEvidence(input);
    await db.patch(path, {
      evidenceVerificationStatus: evidence.passed ? "passed" : "failed",
      evidenceVerificationAt: new Date(),
      evidenceVerificationCompletedAt: new Date(),
      evidenceVerificationScore: evidence.confidence,
      evidenceVerificationNotes: evidence.reason,
      verificationStage: evidence.passed ? "department_verification" : "evidence_failed",
      updatedAt: new Date(),
    });
    if (!evidence.passed) {
      await db.patch(path, {
        aiAnalysisStatus: "failed",
        verificationFailureReason: evidence.reason,
        citizenSafeVerificationMessage: "Evidence could not be confirmed. Please contact the municipal helpdesk for review.",
        updatedAt: new Date(),
      });
      await writeUpdate(db, complaintId, "evidence_failed", "Evidence Review Needed", "Automated evidence verification could not confirm this submission.");
      return;
    }
    await writeUpdate(db, complaintId, "evidence_passed", "Evidence Verified", "Automated evidence verification passed.");
    await db.patch(path, {
      departmentVerificationStatus: "processing",
      verificationStage: "department_verification",
      departmentVerificationStartedAt: new Date(),
      updatedAt: new Date(),
    });
    const department = await verifyDepartment(input, evidence);
    if (!department.passed || !department.departmentId || !department.departmentName) {
      await db.patch(path, {
        departmentVerificationStatus: "failed",
        departmentVerificationAt: new Date(),
        departmentVerificationCompletedAt: new Date(),
        departmentVerificationScore: department.confidence,
        departmentVerificationNotes: department.rationale,
        verificationStage: "department_failed",
        aiAnalysisStatus: "failed",
        verificationFailureReason: department.rationale,
        citizenSafeVerificationMessage: "Department could not be confirmed. Please contact the municipal helpdesk for review.",
        updatedAt: new Date(),
      });
      await writeUpdate(db, complaintId, "department_failed", "Department Review Needed", "Automated department verification could not classify this issue.");
      return;
    }
    await db.patch(path, {
      departmentVerificationStatus: "passed",
      departmentVerificationAt: new Date(),
      departmentVerificationCompletedAt: new Date(),
      departmentVerificationScore: department.confidence,
      departmentVerificationNotes: department.rationale,
      verifiedDepartmentId: department.departmentId,
      verifiedDepartmentName: department.departmentName,
      verificationStage: "verification_completed",
      verificationCompletedAt: new Date(),
      aiAnalysisStatus: "completed",
      verificationFailureReason: null,
      updatedAt: new Date(),
    });
    await writeUpdate(db, complaintId, "department_passed", "Department Verified", `Issue routed to ${department.departmentName}.`, "verified");
    await routeComplaint(db, complaintId, complaint, department.departmentId, department.departmentName);
  } catch (error) {
    console.error("Complaint verification failed", complaintId, error);
    try {
      const latest = await db.get(path);
      if (latest?.data.status === "assigned") {
        console.error("Assignment succeeded, but a later verification update failed", complaintId);
        return;
      }
      const evidencePassed = latest?.data.evidenceVerificationStatus === "passed";
      await db.patch(path, {
        aiAnalysisStatus: "error",
        [evidencePassed ? "departmentVerificationStatus" : "evidenceVerificationStatus"]: "temporarily_unavailable",
        verificationStage: "verification_error",
        verificationFailureReason: error instanceof Error ? error.message.slice(0, 500) : "Unknown error",
        citizenSafeVerificationMessage: "Automated verification is delayed. Please retry or contact the municipal helpdesk.",
        updatedAt: new Date(),
      });
      await writeUpdate(db, complaintId, "verification_error", "Verification Delayed", "Automated verification could not finish. The submission remains available for review.");
    } catch (writeError) {
      console.error("Could not record complaint verification failure", complaintId, writeError);
    }
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (request.method !== "POST") return reply(405, { error: "METHOD_NOT_ALLOWED" });
  const authorization = request.headers.get("authorization") || "";
  if (!authorization.startsWith("Bearer ")) return reply(401, { error: "UNAUTHORIZED" });
  let auth;
  try {
    auth = await verifyFirebaseIdToken(authorization.slice(7));
  } catch {
    return reply(503, { error: "AUTH_VERIFICATION_UNAVAILABLE" });
  }
  if (!auth.valid || !auth.uid) return reply(401, { error: "UNAUTHORIZED" });
  let complaintId: string;
  try {
    const body = await request.json();
    complaintId = text(body.complaintId);
  } catch {
    return reply(400, { error: "INVALID_JSON" });
  }
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(complaintId)) {
    return reply(400, { error: "INVALID_COMPLAINT_ID" });
  }
  if (!Deno.env.get("GEMINI_API_KEY") || !Deno.env.get("GEMINI_DEPARTMENT_API_KEY")) {
    return reply(503, { error: "VERIFICATION_NOT_CONFIGURED" });
  }
  try {
    const db = await createComplaintFirestore();
    const document = await db.get(`complaints/${complaintId}`);
    if (!document) return reply(404, { error: "COMPLAINT_NOT_FOUND" });
    if (document.data.citizenId !== auth.uid) return reply(403, { error: "FORBIDDEN" });
    if (document.data.status !== "underVerification") {
      return reply(200, { status: "already_processed" });
    }
    const stage = text(document.data.verificationStage);
    const activeStartedAt = stage === "department_verification"
      ? Date.parse(text(document.data.departmentVerificationStartedAt))
      : Date.parse(text(document.data.evidenceVerificationStartedAt));
    if (document.data.aiAnalysisStatus === "processing" &&
        Number.isFinite(activeStartedAt) && Date.now() - activeStartedAt < 120000) {
      return reply(202, { status: "processing" });
    }
    if (document.data.aiAnalysisStatus === "error" &&
        Number.isFinite(activeStartedAt) && Date.now() - activeStartedAt < 60000) {
      return reply(202, { status: "retry_later" });
    }
    if (["evidence_failed", "department_failed", "verification_completed"].includes(stage)) {
      return reply(200, { status: "already_processed" });
    }
    await db.patch(`complaints/${complaintId}`, {
      aiAnalysisStatus: "processing",
      evidenceVerificationStatus: "processing",
      evidenceVerificationStartedAt: new Date(),
      verificationStage: "evidence",
      updatedAt: new Date(),
    }, document.updateTime);
    EdgeRuntime.waitUntil(processComplaint(db, complaintId, document.data));
    return reply(202, { status: "processing" });
  } catch (error) {
    console.error("Could not start verification", error);
    return reply(503, { error: "VERIFICATION_UNAVAILABLE" });
  }
});
