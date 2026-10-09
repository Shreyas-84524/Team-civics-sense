import crypto from 'node:crypto';
import assert from 'node:assert/strict';

// Reward policy constants
const STAGE_POINTS = { submitted: 10, verified: 20, assigned: 15, inProgress: 20, resolved: 35 };
const STAGE_LABELS = {
  submitted: "Complaint submitted",
  verified: "Complaint verified",
  assigned: "Complaint assigned",
  inProgress: "Work in progress",
  resolved: "Complaint resolved"
};

const ACHIEVEMENTS = [
  { id: "evidence_expert", title: "Evidence Expert", metric: "evidenceReports", target: 5, bonusPoints: 0 },
  { id: "ground_reporter", title: "Ground Reporter", metric: "locationReports", target: 5, bonusPoints: 0 },
  { id: "community_voice", title: "Community Voice", metric: "communityUpvotes", target: 10, bonusPoints: 0 },
  { id: "community_helper", title: "Community Helper", metric: "supportedComplaints", target: 10, bonusPoints: 10 },
  { id: "resolution_champion", title: "Resolution Champion", metric: "reportsResolved", target: 5, bonusPoints: 0 }
];

function eligible(data) {
  return (
    data.status !== "rejected" &&
    data.isDuplicate !== true &&
    !data.duplicateOf &&
    !data.duplicateOfComplaintId &&
    data.rewardEligible !== false &&
    data.isFraudulent !== true &&
    data.isEvidenceRejected !== true &&
    data.isAiGeneratedEvidenceRejected !== true &&
    data.evidenceVerificationStatus !== "failed" &&
    data.aiAnalysisStatus !== "failed"
  );
}

function statusToRank(status) {
  switch (status) {
    case "underVerification":
    case "reported":
      return 0;
    case "verified":
      return 1;
    case "assigned":
      return 2;
    case "inProgress":
      return 3;
    case "resolved":
    case "closed":
      return 4;
    default:
      return -1;
  }
}

function reachedStages(data, history) {
  if (!eligible(data)) return [];
  const allStatuses = [String(data.status || ""), ...history.map(String)];
  const maxRank = Math.max(0, ...allStatuses.map(statusToRank));
  const stages = ["submitted", "verified", "assigned", "inProgress", "resolved"];
  return stages.slice(0, Math.min(maxRank + 1, 5));
}

function levelFor(points) {
  const levels = [
    { level: 1, title: "Civic Starter", minimum: 0, next: 100 },
    { level: 2, title: "Civic Contributor", minimum: 100, next: 250 },
    { level: 3, title: "Civic Champion", minimum: 250, next: 500 },
    { level: 4, title: "Civic Leader", minimum: 500, next: 1000 },
    { level: 5, title: "Civic Hero", minimum: 1000, next: null },
  ];
  return levels.find(l => l.next === null || points < l.next);
}

function stableId(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

// In-memory mock Firestore database
class MockFirestore {
  constructor() {
    this.docs = new Map();
  }

  get(path) {
    const doc = this.docs.get(path);
    if (!doc) return null;
    return { name: path, data: JSON.parse(JSON.stringify(doc.data)), updateTime: doc.updateTime };
  }

  set(path, data) {
    this.docs.set(path, { data: JSON.parse(JSON.stringify(data)), updateTime: new Date().toISOString() });
    return true;
  }

  list(prefix) {
    const results = [];
    for (const [key, val] of this.docs.entries()) {
      if (key.startsWith(prefix + '/')) {
        results.push({ name: key, data: JSON.parse(JSON.stringify(val.data)) });
      }
    }
    return results;
  }

  async commitRewards(summaryPath, summary, previous, events, userPath, pointsToGrant) {
    // Atomic commit simulation
    this.set(summaryPath, summary);
    for (const ev of events) {
      this.set(`${summaryPath}/events/${ev.id}`, ev.data);
    }
    if (userPath && pointsToGrant > 0) {
      const user = this.get(userPath);
      if (user) {
        const currentPts = Number(user.data.civicPoints || 0);
        user.data.civicPoints = currentPts + pointsToGrant;
        this.set(userPath, user.data);
      }
    }
    return true;
  }
}

// Process complaint action simulator
async function processAction(db, callerUid, complaintId, action) {
  const validActions = ["submitted", "verified", "assigned", "inProgress", "resolved", "upvote"];
  if (!validActions.includes(action)) {
    return { status: "failed", pointsAwarded: 0, reason: `Invalid action: ${action}` };
  }

  const complaint = db.get(`complaints/${complaintId}`);
  if (!complaint) {
    return { status: "failed", pointsAwarded: 0, reason: "NOT_FOUND" };
  }

  const data = complaint.data;
  const citizenId = String(data.citizenId || "");
  const identity = String(data.localId || data.ticketNumber || complaintId);

  // Community upvote
  if (action === "upvote") {
    if (callerUid === citizenId) {
      return { status: "failed", pointsAwarded: 0, reason: "SELF_UPVOTE_NOT_REWARDED" };
    }
    if (!eligible(data)) {
      return { status: "already_awarded", pointsAwarded: 0, reason: "COMPLAINT_NOT_ELIGIBLE" };
    }

    // Count supported complaints
    const upvotes = db.list(`upvotes/${callerUid}`) || [];
    const supported = new Set();
    for (const v of upvotes) {
      const c = db.get(`complaints/${v.data.complaintId}`);
      if (c && c.data.citizenId !== callerUid && eligible(c.data) && reachedStages(c.data, []).includes("verified")) {
        supported.add(v.data.complaintId);
      }
    }

    const summaryPath = `rewards/${callerUid}`;
    const previous = db.get(summaryPath);
    const user = db.get(`users/${callerUid}`);
    if (!user) return { status: "failed", pointsAwarded: 0, reason: "USER_NOT_FOUND" };

    const oldPoints = Number(previous?.data.points ?? user.data.civicPoints ?? 0);
    const existingBonus = db.get(`${summaryPath}/events/achievement_community_helper`);

    if (supported.size >= 10 && !existingBonus) {
      const newPoints = oldPoints + 10;
      const level = levelFor(newPoints);
      const bonusEvent = {
        id: "achievement_community_helper",
        data: {
          citizenId: callerUid,
          complaintId: null,
          rewardType: "community_helper",
          points: 10,
          description: "Community Helper achievement bonus",
          createdAt: new Date().toISOString()
        }
      };

      const summary = {
        userId: callerUid,
        points: newPoints,
        supportedComplaints: supported.size,
        level: level.level,
        levelTitle: level.title,
        updatedAt: new Date().toISOString()
      };

      await db.commitRewards(summaryPath, summary, previous, [bonusEvent], `users/${callerUid}`, 10);
      return { status: "committed", pointsAwarded: 10, achievement: "community_helper", newTotalPoints: newPoints };
    }

    return { status: "already_awarded", pointsAwarded: 0, supportedCount: supported.size };
  }

  // Lifecycle stage actions
  const stage = action;
  if (stage === "submitted") {
    if (callerUid !== citizenId) {
      return { status: "failed", pointsAwarded: 0, reason: "FORBIDDEN: Caller is not the complaint author" };
    }
  } else {
    const officer = db.get(`government_users/${callerUid}`);
    if (!officer || officer.data.active !== true) {
      return { status: "failed", pointsAwarded: 0, reason: "FORBIDDEN: Only active municipal personnel may certify this stage" };
    }
  }

  if (!eligible(data)) {
    return { status: "failed", pointsAwarded: 0, reason: "COMPLAINT_NOT_ELIGIBLE" };
  }

  const reached = reachedStages(data, []);
  if (!reached.includes(stage)) {
    return { status: "failed", pointsAwarded: 0, reason: `Complaint has not reached stage: ${stage}` };
  }

  const key = stableId(`${citizenId}:${identity}`);
  const eventId = `${key}_${stage}`;
  const summaryPath = `rewards/${citizenId}`;

  const existingEvent = db.get(`${summaryPath}/events/${eventId}`);
  if (existingEvent) {
    return { status: "already_awarded", pointsAwarded: 0, stage, citizenId };
  }

  // Grievance Point Ceiling Check (Max 100 points)
  const existingEvents = db.list(`${summaryPath}/events`);
  const complaintEvents = existingEvents.filter(e => e.data.complaintId === complaintId || e.name.includes(key));
  const existingPoints = complaintEvents.reduce((sum, e) => sum + Number(e.data.points || 0), 0);
  const stagePoints = STAGE_POINTS[stage];
  const pointsToGrant = Math.min(stagePoints, Math.max(0, 100 - existingPoints));

  if (pointsToGrant <= 0) {
    return { status: "already_awarded", pointsAwarded: 0, stage, citizenId, reason: "MAX_POINTS_REACHED" };
  }

  const previous = db.get(summaryPath);
  const user = db.get(`users/${citizenId}`);
  if (!user) return { status: "failed", pointsAwarded: 0, reason: "CITIZEN_PROFILE_NOT_FOUND" };

  const oldPoints = Number(previous?.data.points ?? user.data.civicPoints ?? 0);
  const newPoints = oldPoints + pointsToGrant;
  const level = levelFor(newPoints);

  const eventData = {
    citizenId,
    complaintId,
    complaintTitle: data.title || "Civic complaint",
    rewardType: stage,
    points: pointsToGrant,
    description: STAGE_LABELS[stage],
    createdAt: new Date().toISOString()
  };

  const summary = {
    userId: citizenId,
    points: newPoints,
    level: level.level,
    levelTitle: level.title,
    updatedAt: new Date().toISOString()
  };

  await db.commitRewards(summaryPath, summary, previous, [{ id: eventId, data: eventData }], `users/${citizenId}`, pointsToGrant);
  return { status: "committed", pointsAwarded: pointsToGrant, stage, citizenId, newTotalPoints: newPoints };
}

// -------------------------------------------------------------
// RUN THE COMPREHENSIVE VERIFICATION SUITE
// -------------------------------------------------------------
async function runTests() {
  console.log("==================================================================");
  console.log("CIVICFIX GAMIFICATION REPAIR — BACKEND ENGINE & POLICY TEST SUITE");
  console.log("==================================================================\n");

  const db = new MockFirestore();
  const citizenId = "citizen_test_123";
  const officerId = "officer_lead_456";
  const complaintId = "complaint_abc_789";

  // Setup initial state
  db.set(`users/${citizenId}`, { id: citizenId, fullName: "Test Citizen", civicPoints: 0, reportsSubmitted: 0, reportsResolved: 0 });
  db.set(`government_users/${officerId}`, { id: officerId, fullName: "Eng. Deshmukh", role: "department_crew", active: true, wardId: "ward_k_west" });
  db.set(`complaints/${complaintId}`, {
    id: complaintId,
    citizenId,
    title: "Large Pothole on Link Road",
    status: "reported",
    isDuplicate: false,
    rewardEligible: true,
    wardId: "ward_k_west"
  });

  // TEST 1: Full complaint lifecycle grants exactly 100 points
  console.log("[Test 1] Full complaint lifecycle: 10 + 20 + 15 + 20 + 35 = 100 pts");
  
  // Stage 1: Submitted (+10)
  let res = await processAction(db, citizenId, complaintId, "submitted");
  assert.equal(res.status, "committed");
  assert.equal(res.pointsAwarded, 10);
  assert.equal(res.newTotalPoints, 10);

  // Stage 2: Verified (+20)
  db.set(`complaints/${complaintId}`, { ...db.get(`complaints/${complaintId}`).data, status: "verified" });
  res = await processAction(db, officerId, complaintId, "verified");
  assert.equal(res.status, "committed");
  assert.equal(res.pointsAwarded, 20);
  assert.equal(res.newTotalPoints, 30);

  // Stage 3: Assigned (+15)
  db.set(`complaints/${complaintId}`, { ...db.get(`complaints/${complaintId}`).data, status: "assigned" });
  res = await processAction(db, officerId, complaintId, "assigned");
  assert.equal(res.status, "committed");
  assert.equal(res.pointsAwarded, 15);
  assert.equal(res.newTotalPoints, 45);

  // Stage 4: In Progress (+20)
  db.set(`complaints/${complaintId}`, { ...db.get(`complaints/${complaintId}`).data, status: "inProgress" });
  res = await processAction(db, officerId, complaintId, "inProgress");
  assert.equal(res.status, "committed");
  assert.equal(res.pointsAwarded, 20);
  assert.equal(res.newTotalPoints, 65);

  // Stage 5: Resolved (+35)
  db.set(`complaints/${complaintId}`, { ...db.get(`complaints/${complaintId}`).data, status: "resolved" });
  res = await processAction(db, officerId, complaintId, "resolved");
  assert.equal(res.status, "committed");
  assert.equal(res.pointsAwarded, 35);
  assert.equal(res.newTotalPoints, 100);

  // Check persisted balances
  assert.equal(db.get(`users/${citizenId}`).data.civicPoints, 100, "users.civicPoints must equal 100");
  assert.equal(db.get(`rewards/${citizenId}`).data.points, 100, "rewards.points must equal 100");
  assert.equal(db.list(`rewards/${citizenId}/events`).length, 5, "5 event records must exist");
  console.log("  ✓ Passed: 100 points awarded across 5 lifecycle stages.");

  // TEST 2: Idempotent Retries & Duplicate Protection
  console.log("[Test 2] Idempotency: Retrying completed stage returns already_awarded + 0 pts");
  res = await processAction(db, officerId, complaintId, "resolved");
  assert.equal(res.status, "already_awarded");
  assert.equal(res.pointsAwarded, 0);
  assert.equal(db.get(`users/${citizenId}`).data.civicPoints, 100);
  console.log("  ✓ Passed: Duplicate action returned already_awarded without altering balance.");

  // TEST 3: Reopened Complaint Rework
  console.log("[Test 3] Reopened complaint: Re-entering inProgress does NOT re-award points");
  db.set(`complaints/${complaintId}`, { ...db.get(`complaints/${complaintId}`).data, status: "inProgress", reopenCount: 1 });
  res = await processAction(db, officerId, complaintId, "inProgress");
  assert.equal(res.status, "already_awarded");
  assert.equal(res.pointsAwarded, 0);
  assert.equal(db.get(`users/${citizenId}`).data.civicPoints, 100);
  console.log("  ✓ Passed: Reopened complaint did not duplicate points.");

  // TEST 4: Fraud / AI Rejection Protection
  console.log("[Test 4] Fraud & AI Rejection: Blocked complaints receive 0 points");
  const fraudId = "fraud_complaint_999";
  db.set(`complaints/${fraudId}`, {
    id: fraudId,
    citizenId,
    title: "Fake pothole image from internet",
    status: "rejected",
    isFraudulent: true,
    evidenceVerificationStatus: "failed"
  });
  res = await processAction(db, citizenId, fraudId, "submitted");
  assert.equal(res.status, "failed");
  assert.equal(res.pointsAwarded, 0);
  assert.equal(db.get(`users/${citizenId}`).data.civicPoints, 100);
  console.log("  ✓ Passed: Fraudulent complaint rejected without reward.");

  // TEST 5: Security / Permission Enforcement
  console.log("[Test 5] Security: Non-author submitted and non-officer verification are blocked");
  const unauthId = "complaint_other_citizen";
  db.set(`complaints/${unauthId}`, { id: unauthId, citizenId: "other_user", title: "Water Leak", status: "reported" });
  res = await processAction(db, citizenId, unauthId, "submitted");
  assert.equal(res.status, "failed");
  assert.match(res.reason, /FORBIDDEN/);

  res = await processAction(db, citizenId, complaintId, "verified");
  assert.equal(res.status, "failed");
  assert.match(res.reason, /FORBIDDEN/);
  console.log("  ✓ Passed: Unauthorized calls rejected.");

  // TEST 6: Community Helper Achievement Milestone & One-Time +10 Bonus
  console.log("[Test 6] Community Helper: 10 verified upvotes unlock badge + one-time +10 bonus");
  for (let i = 1; i <= 10; i++) {
    const cid = `community_complaint_${i}`;
    db.set(`complaints/${cid}`, { id: cid, citizenId: `other_author_${i}`, title: `Issue ${i}`, status: "verified", rewardEligible: true });
    db.set(`upvotes/${citizenId}/vote_${i}`, { complaintId: cid, userId: citizenId });
  }

  // Trigger upvote action on the 10th complaint
  res = await processAction(db, citizenId, "community_complaint_10", "upvote");
  assert.equal(res.status, "committed");
  assert.equal(res.pointsAwarded, 10);
  assert.equal(res.achievement, "community_helper");
  assert.equal(res.newTotalPoints, 110);
  assert.equal(db.get(`users/${citizenId}`).data.civicPoints, 110);
  console.log("  ✓ Passed: Community Helper granted +10 bonus (total: 110 pts).");

  // Subsequent upvotes must not re-award the +10 bonus
  const cid11 = "community_complaint_11";
  db.set(`complaints/${cid11}`, { id: cid11, citizenId: "other_author_11", title: "Issue 11", status: "verified", rewardEligible: true });
  db.set(`upvotes/${citizenId}/vote_11`, { complaintId: cid11, userId: citizenId });
  res = await processAction(db, citizenId, cid11, "upvote");
  assert.equal(res.status, "already_awarded");
  assert.equal(res.pointsAwarded, 0);
  assert.equal(db.get(`users/${citizenId}`).data.civicPoints, 110);
  console.log("  ✓ Passed: Subsequent upvotes beyond 10 do not re-award bonus.");

  // TEST 7: Recognition-Only Badges Grant 0 Points
  console.log("[Test 7] Other 4 Badges: Recognition-only with 0 point bonus");
  for (const ach of ACHIEVEMENTS) {
    if (ach.id !== "community_helper") {
      assert.equal(ach.bonusPoints, 0, `${ach.title} must have 0 bonus points`);
    }
  }
  console.log("  ✓ Passed: Evidence Expert, Ground Reporter, Community Voice, and Resolution Champion are recognition-only (0 pts).");

  console.log("\n==================================================================");
  console.log("ALL 7 BACKEND REWARD ENGINE INTEGRATION TESTS PASSED CLEANLY!");
  console.log("==================================================================");
}

runTests().catch(err => {
  console.error("Test failure:", err);
  process.exit(1);
});
