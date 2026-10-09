import { verifyFirebaseIdToken } from "../_shared/firebase-auth.ts";
import { createComplaintFirestore } from "../_shared/complaint-firestore.ts";
import { processComplaintAction, reconcileRewards } from "../_shared/civic-rewards.ts";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const reply = (status: number, data: unknown) =>
  new Response(JSON.stringify(data), { status, headers });

Deno.serve(async request => {
  if (request.method === "OPTIONS") return reply(200, {});
  if (request.method !== "POST") return reply(405, { error: "METHOD_NOT_ALLOWED" });

  try {
    const token = request.headers.get("authorization") || "";
    if (!token.startsWith("Bearer ")) return reply(401, { error: "UNAUTHORIZED" });
    const auth = await verifyFirebaseIdToken(token.slice(7));
    if (!auth.valid || !auth.uid) return reply(401, { error: "UNAUTHORIZED", message: auth.error });

    const body = await request.json().catch(() => ({}));
    const db = await createComplaintFirestore();

    const action = body.action || body.stage;
    if (action && body.complaintId) {
      if (typeof body.complaintId !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(body.complaintId)) {
        return reply(400, { error: "INVALID_COMPLAINT_ID" });
      }
      const result = await processComplaintAction(db, auth.uid, body.complaintId, String(action));
      return reply(200, result);
    }

    if (body.mode === "reconcile") {
      // Historical reconciliation only triggered on explicit request
      const targetUid = (body.citizenId && auth.uid === body.citizenId) ? String(body.citizenId) : auth.uid;
      await reconcileRewards(db, targetUid);
      return reply(200, { status: "synchronized", citizenId: targetUid });
    }

    return reply(400, {
      error: "INVALID_REQUEST",
      message: "Must specify complaintId with action ('submitted'|'verified'|'assigned'|'inProgress'|'resolved'|'upvote') or mode: 'reconcile'",
    });
  } catch (error) {
    console.error("Reward processing failed:", error instanceof Error ? error.message : "Unknown error");
    return reply(500, { error: "REWARDS_PROCESSING_FAILED", message: error instanceof Error ? error.message : "Unknown error" });
  }
});

