import { createComplaintFirestore } from "./complaint-firestore.ts";
import { ACHIEVEMENTS, eligible, levelFor, reachedStages, STAGE_LABELS, STAGE_POINTS, Stage } from "./reward-policy.ts";
import { resolveWardForLocation } from "./departments.ts";

type Db = Awaited<ReturnType<typeof createComplaintFirestore>>;

export async function stableId(value: string) {
  const hash = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(hash)].map(b => b.toString(16).padStart(2, "0")).join("");
}

export interface ProcessActionResult {
  status: "committed" | "already_awarded" | "failed";
  pointsAwarded: number;
  stage?: string;
  citizenId?: string;
  reason?: string;
  newTotalPoints?: number;
  achievement?: string;
  supportedCount?: number;
}

/**
 * Authoritatively processes a single complaint action (lifecycle stage or upvote).
 * Ensures:
 * 1. Caller authentication, ownership & jurisdiction validation.
 * 2. Strict eligibility & anti-abuse enforcement (no rejected, duplicate, or AI-failed awards).
 * 3. Deterministic idempotency keys preventing replay and duplicate writes.
 * 4. Maximum 100 lifecycle points ceiling per complaint.
 * 5. Atomic batch commit of event + summary + users.civicPoints.
 * 6. Explicit status return (committed, already_awarded, failed).
 */
export async function processComplaintAction(
  db: Db,
  callerUid: string,
  complaintId: string,
  action: string,
): Promise<ProcessActionResult> {
  const validActions = ["submitted", "verified", "assigned", "inProgress", "resolved", "upvote"];
  if (!validActions.includes(action)) {
    return { status: "failed", pointsAwarded: 0, reason: `Invalid action: ${action}` };
  }

  const complaint = await db.get(`complaints/${complaintId}`);
  if (!complaint) {
    return { status: "failed", pointsAwarded: 0, reason: "NOT_FOUND" };
  }

  const data = complaint.data;
  const citizenId = String(data.citizenId || "");
  const identity = String(data.localId || data.ticketNumber || complaintId);

  // 1. COMMUNITY UPVOTE ACTION (Community Helper milestone)
  if (action === "upvote") {
    if (callerUid === citizenId) {
      return { status: "failed", pointsAwarded: 0, reason: "SELF_UPVOTE_NOT_REWARDED" };
    }
    const vote = await db.get(`complaints/${complaintId}/upvotes/${callerUid}`);
    if (!vote) {
      return { status: "failed", pointsAwarded: 0, reason: "UPVOTE_NOT_FOUND" };
    }
    if (!eligible(data)) {
      return { status: "already_awarded", pointsAwarded: 0, reason: "COMPLAINT_NOT_ELIGIBLE" };
    }

    const support = await db.query("upvotes", "userId", callerUid, true);
    const supported = new Set<string>();
    for (const v of support) {
      const match = v.name.match(/\/complaints\/([^/]+)\/upvotes\/([^/]+)$/);
      if (!match || match[2] !== callerUid) continue;
      const c = await db.get(`complaints/${match[1]}`);
      if (!c || c.data.citizenId === callerUid || !eligible(c.data)) continue;
      if (reachedStages(c.data, []).includes("verified")) {
        supported.add(String(c.data.localId || c.data.ticketNumber || match[1]));
      }
    }

    const summaryPath = `rewards/${callerUid}`;
    const previous = await db.get(summaryPath);
    const user = await db.get(`users/${callerUid}`);
    if (!user) return { status: "failed", pointsAwarded: 0, reason: "USER_NOT_FOUND" };

    const oldPoints = Number(previous?.data.points ?? user.data.civicPoints ?? 0);
    const existingBonus = await db.get(`${summaryPath}/events/achievement_community_helper`);

    if (supported.size >= 10 && !existingBonus) {
      const newPoints = oldPoints + 10;
      const level = levelFor(newPoints);
      const bonusEvent = {
        id: "achievement_community_helper",
        data: {
          citizenId: callerUid,
          complaintId: null,
          complaintTitle: "Community participation",
          rewardType: "community_helper",
          points: 10,
          description: "Community Helper achievement bonus",
          createdAt: new Date(),
        },
      };

      const oldAchievements = (previous?.data.achievements || []) as Record<string, unknown>[];
      const achievements = ACHIEVEMENTS.map(a => {
        const old = oldAchievements.find(x => x.id === a.id);
        const isCurrent = a.id === "community_helper" || old?.isUnlocked === true;
        return {
          ...a,
          description: a.howToUnlock,
          progress: a.id === "community_helper" ? supported.size : (old?.progress ?? 0),
          isUnlocked: isCurrent,
          unlockedAt: isCurrent ? (old?.unlockedAt || new Date()) : null,
        };
      });

      const recentActivity = [
        { id: bonusEvent.id, ...bonusEvent.data },
        ...((previous?.data.recentActivity || []) as Record<string, unknown>[]),
      ].slice(0, 30);

      const summary = {
        userId: callerUid,
        points: newPoints,
        lifetimePoints: newPoints,
        openingBalance: previous?.data.openingBalance ?? oldPoints,
        reportsSubmitted: Number(previous?.data.reportsSubmitted ?? user.data.reportsSubmitted ?? 0),
        reportsVerified: Number(previous?.data.reportsVerified ?? 0),
        reportsResolved: Number(previous?.data.reportsResolved ?? user.data.reportsResolved ?? 0),
        evidenceReports: Number(previous?.data.evidenceReports ?? 0),
        locationReports: Number(previous?.data.locationReports ?? 0),
        communityUpvotes: Number(previous?.data.communityUpvotes ?? 0),
        supportedComplaints: supported.size,
        level: level.level,
        levelTitle: level.title,
        nextMilestoneTarget: level.next ?? 1000,
        achievements,
        recentActivity,
        updatedAt: new Date(),
        policyVersion: 1,
      };

      const committed = await db.commitRewards(summaryPath, summary, previous, [bonusEvent], `users/${callerUid}`, 10);
      if (committed) {
        return {
          status: "committed",
          pointsAwarded: 10,
          achievement: "community_helper",
          citizenId: callerUid,
          newTotalPoints: newPoints,
          supportedCount: supported.size,
        };
      }
      return { status: "already_awarded", pointsAwarded: 0, achievement: "community_helper", citizenId: callerUid, supportedCount: supported.size };
    }

    if (previous) {
      const summary = {
        ...previous.data,
        supportedComplaints: supported.size,
        updatedAt: new Date(),
      };
      await db.patch(summaryPath, summary, previous.updateTime);
    }
    return {
      status: "already_awarded",
      pointsAwarded: 0,
      supportedCount: supported.size,
      reason: supported.size >= 10 ? "BONUS_ALREADY_AWARDED" : `Supported complaints: ${supported.size} / 10`,
    };
  }

  // 2. COMPLAINT LIFECYCLE STAGE ACTIONS
  const stage = action as Stage;

  // Caller Authorization Check
  if (stage === "submitted") {
    if (callerUid !== citizenId) {
      return { status: "failed", pointsAwarded: 0, reason: "FORBIDDEN: Caller is not the complaint author" };
    }
  } else {
    // Government officer verification
    const officer = await db.get(`government_users/${callerUid}`);
    if (!officer || officer.data.active !== true) {
      return { status: "failed", pointsAwarded: 0, reason: "FORBIDDEN: Only active municipal personnel may certify this stage" };
    }
    const officerRole = String(officer.data.role || "");
    if (officerRole !== "government_super_admin") {
      const officerWard = officer.data.wardId ? String(officer.data.wardId) : null;
      const complaintWard = data.wardId ? String(data.wardId) : null;
      const isAssigned = (
        data.assignedCrewMemberId === callerUid ||
        data.assignedFieldOfficerId === callerUid ||
        data.assignedJuniorEngineerId === callerUid ||
        data.assignedDepartmentLeadId === callerUid
      );
      if (officerWard && complaintWard && officerWard !== complaintWard && !isAssigned) {
        return { status: "failed", pointsAwarded: 0, reason: "FORBIDDEN: Outside officer jurisdiction" };
      }
    }
  }

  // Complaint Eligibility Check
  if (stage === "submitted") {
    if (data.status === "rejected" || data.isDuplicate === true || data.isFraudulent === true) {
      return { status: "failed", pointsAwarded: 0, reason: "COMPLAINT_NOT_ELIGIBLE" };
    }
  } else {
    if (!eligible(data)) {
      return { status: "failed", pointsAwarded: 0, reason: "COMPLAINT_NOT_ELIGIBLE" };
    }
  }

  // Stage Attainment Check
  const history = await db.list(`complaints/${complaintId}/complaint_updates`);
  const reached = reachedStages(data, history.map(h => String(h.data.status)));
  if (!reached.includes(stage)) {
    return { status: "failed", pointsAwarded: 0, reason: `Complaint has not reached stage: ${stage}` };
  }

  // Deterministic Idempotency Key
  const key = await stableId(`${citizenId}:${identity}`);
  const eventId = `${key}_${stage}`;
  const summaryPath = `rewards/${citizenId}`;

  // Check if this specific stage event already exists
  const existingEvent = await db.get(`${summaryPath}/events/${eventId}`);
  if (existingEvent) {
    return { status: "already_awarded", pointsAwarded: 0, stage, citizenId };
  }

  // Grievance Point Ceiling Check (Max 100 points lifecycle cap per complaint)
  const existingEvents = await db.list(`${summaryPath}/events`, 50000);
  const complaintEvents = existingEvents.filter(e => e.data.complaintId === complaintId || (e.name && e.name.includes(key)));
  const existingPoints = complaintEvents.reduce((sum, e) => sum + Number(e.data.points || 0), 0);
  const stagePoints = STAGE_POINTS[stage];
  const pointsToGrant = Math.min(stagePoints, Math.max(0, 100 - existingPoints));

  if (pointsToGrant <= 0) {
    return { status: "already_awarded", pointsAwarded: 0, stage, citizenId, reason: "MAX_POINTS_REACHED" };
  }

  // Fetch previous summary and user profile
  const previous = await db.get(summaryPath);
  const user = await db.get(`users/${citizenId}`);
  if (!user) {
    return { status: "failed", pointsAwarded: 0, reason: "CITIZEN_PROFILE_NOT_FOUND" };
  }

  const oldPoints = Number(previous?.data.points ?? user.data.civicPoints ?? 0);
  const newPoints = oldPoints + pointsToGrant;
  const level = levelFor(newPoints);

  const prevSubmitted = Number(previous?.data.reportsSubmitted ?? user.data.reportsSubmitted ?? 0);
  const prevVerified = Number(previous?.data.reportsVerified ?? 0);
  const prevResolved = Number(previous?.data.reportsResolved ?? user.data.reportsResolved ?? 0);

  const reportsSubmitted = stage === "submitted" ? prevSubmitted + 1 : prevSubmitted;
  const reportsVerified = stage === "verified" ? prevVerified + 1 : prevVerified;
  const reportsResolved = stage === "resolved" ? prevResolved + 1 : prevResolved;

  const eventData = {
    citizenId,
    complaintId,
    complaintTitle: String(data.title || "Civic complaint").slice(0, 200),
    rewardType: stage,
    points: pointsToGrant,
    description: STAGE_LABELS[stage],
    createdAt: new Date(),
    metadata: {
      ticketNumber: data.ticketNumber || null,
      category: typeof data.category === "object" ? ((data.category as Record<string, unknown>)?.id || (data.category as Record<string, unknown>)?.name || null) : (data.category || null),
      status: data.status || null,
    },
  };

  const oldRecent = (previous?.data.recentActivity || []) as Record<string, unknown>[];
  const recentActivity = [{ id: eventId, ...eventData }, ...oldRecent].slice(0, 30);

  const summary = {
    userId: citizenId,
    points: newPoints,
    lifetimePoints: newPoints,
    openingBalance: previous?.data.openingBalance ?? oldPoints,
    reportsSubmitted,
    reportsVerified,
    reportsResolved,
    evidenceReports: Number(previous?.data.evidenceReports ?? 0),
    locationReports: Number(previous?.data.locationReports ?? 0),
    communityUpvotes: Number(previous?.data.communityUpvotes ?? 0),
    supportedComplaints: Number(previous?.data.supportedComplaints ?? 0),
    level: level.level,
    levelTitle: level.title,
    nextMilestoneTarget: level.next ?? 1000,
    achievements: previous?.data.achievements || ACHIEVEMENTS.map(a => ({
      ...a,
      description: a.howToUnlock,
      progress: 0,
      isUnlocked: false,
      unlockedAt: null,
    })),
    recentActivity,
    updatedAt: new Date(),
    policyVersion: 1,
  };

  const committed = await db.commitRewards(
    summaryPath,
    summary,
    previous,
    [{ id: eventId, data: eventData }],
    `users/${citizenId}`,
    pointsToGrant,
  );

  if (committed) {
    return {
      status: "committed",
      pointsAwarded: pointsToGrant,
      stage,
      citizenId,
      newTotalPoints: newPoints,
    };
  }

  return { status: "already_awarded", pointsAwarded: 0, stage, citizenId };
}

/**
 * Historical reconciliation across all past complaints and upvotes.
 * Only invoked upon explicit administrative request or explicit migration mode.
 */
export async function reconcileRewards(db: Db, citizenId: string) {
  const user = await db.get(`users/${citizenId}`);
  if (!user || user.data.role !== "citizen") return;
  const owned = await db.query("complaints", "citizenId", citizenId);
  const support = await db.query("upvotes", "userId", citizenId, true);
  const metrics: Record<string, number> = { reportsSubmitted: 0, reportsVerified: 0, reportsResolved: 0, evidenceReports: 0, locationReports: 0, communityUpvotes: 0, supportedComplaints: 0 };
  const candidates: { id: string; data: Record<string, unknown> }[] = [];
  const seen = new Set<string>();
  const supporters = new Set<string>();

  owned.sort((a,b) => String(a.data.createdAt).localeCompare(String(b.data.createdAt)) || a.name.localeCompare(b.name));
  for (const complaint of owned) {
    const data = complaint.data;
    const id = complaint.name.split("/").pop()!;
    const identity = String(data.localId || data.ticketNumber || id);
    if (seen.has(identity)) continue;
    seen.add(identity);
    metrics.reportsSubmitted++;
    if (!eligible(data)) continue;
    const history = await db.list(`complaints/${id}/complaint_updates`);
    const stages = reachedStages(data, history.map(h => String(h.data.status)));
    const key = await stableId(`${citizenId}:${identity}`);
    for (const stage of stages) {
      candidates.push({
        id: `${key}_${stage}`,
        data: {
          citizenId,
          complaintId: id,
          complaintTitle: String(data.title || "Civic complaint").slice(0, 200),
          rewardType: stage,
          points: STAGE_POINTS[stage],
          description: STAGE_LABELS[stage],
          createdAt: new Date(),
        },
      });
    }
    if (stages.includes("resolved")) metrics.reportsResolved++;
    if (!stages.includes("verified")) continue;
    metrics.reportsVerified++;
    if (data.evidenceVerificationStatus === "passed" && Array.isArray(data.imageUrls) && data.imageUrls.length) metrics.evidenceReports++;
    const location = data.location as { latitude?: number; longitude?: number } | undefined;
    if (typeof location?.latitude === "number" && typeof location.longitude === "number") {
      const ward = resolveWardForLocation(location.latitude, location.longitude, "");
      if (ward && [ward.wardId, ward.wardCode].includes(String(data.wardId))) metrics.locationReports++;
    }
    for (const vote of await db.list(`complaints/${id}/upvotes`)) {
      const voter = String(vote.data.userId || "");
      if (voter && voter !== citizenId && vote.name.endsWith(`/${voter}`)) {
        const voterProfile = await db.get(`users/${voter}`);
        if (voterProfile?.data.role === "citizen") supporters.add(voter);
      }
    }
  }
  metrics.communityUpvotes = supporters.size;
  const supported = new Set<string>();
  for (const vote of support) {
    const match = vote.name.match(/\/complaints\/([^/]+)\/upvotes\/([^/]+)$/);
    if (!match || match[2] !== citizenId) continue;
    const complaint = await db.get(`complaints/${match[1]}`);
    if (!complaint || complaint.data.citizenId === citizenId || !eligible(complaint.data)) continue;
    if (reachedStages(complaint.data, []).includes("verified")) supported.add(String(complaint.data.localId || complaint.data.ticketNumber || match[1]));
  }
  metrics.supportedComplaints = supported.size;
  if (supported.size >= 10) {
    candidates.push({
      id: "achievement_community_helper",
      data: {
        citizenId,
        complaintId: null,
        complaintTitle: "Community participation",
        rewardType: "community_helper",
        points: 10,
        description: "Community Helper achievement bonus",
        createdAt: new Date(),
      },
    });
  }
  const summaryPath = `rewards/${citizenId}`;
  for (let attempt = 0; attempt < 12; attempt++) {
    const previous = await db.get(summaryPath);
    const existing = await db.list(`${summaryPath}/events`, 50000);
    const ids = new Set(existing.map(e => e.name.split("/").pop()));
    const missing = candidates.filter(e => !ids.has(e.id));
    const batch = missing.slice(0, 350);
    const oldPoints = Number(previous?.data.points ?? user.data.civicPoints ?? 0);
    const delta = batch.reduce((sum,e) => sum + Number(e.data.points), 0);
    const points = oldPoints + delta;
    const oldAchievements = (previous?.data.achievements || []) as Record<string, unknown>[];
    const achievements = ACHIEVEMENTS.map(a => {
      const old = oldAchievements.find(x => x.id === a.id);
      const unlocked = old?.isUnlocked === true || metrics[a.metric] >= a.target;
      return {
        ...a,
        description: a.howToUnlock,
        progress: metrics[a.metric],
        isUnlocked: unlocked,
        unlockedAt: unlocked ? (old?.unlockedAt || new Date()) : null,
      };
    });
    const level = levelFor(points);
    const recentActivity = [
      ...existing.map(e => ({ id: e.name.split("/").pop(), ...e.data })),
      ...batch.map(e => ({ id: e.id, ...e.data })),
    ].sort((a,b) => new Date(String((b as Record<string,unknown>).createdAt)).getTime() - new Date(String((a as Record<string,unknown>).createdAt)).getTime()).slice(0,30);

    const summary = {
      userId: citizenId,
      points,
      lifetimePoints: points,
      openingBalance: previous?.data.openingBalance ?? oldPoints,
      ...metrics,
      level: level.level,
      levelTitle: level.title,
      nextMilestoneTarget: level.next ?? 1000,
      achievements,
      recentActivity,
      updatedAt: new Date(),
      policyVersion: 1,
    };
    if (await db.commitRewards(summaryPath, summary, previous, batch, `users/${citizenId}`, delta)) {
      if (missing.length <= batch.length) return;
    }
  }
  throw new Error("Rewards are still synchronizing; retry shortly");
}
