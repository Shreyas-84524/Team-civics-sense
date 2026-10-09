export const STAGE_POINTS = { submitted: 10, verified: 20, assigned: 15, inProgress: 20, resolved: 35 } as const;
export type Stage = keyof typeof STAGE_POINTS;
export const STAGE_LABELS: Record<Stage, string> = { submitted: "Complaint submitted", verified: "Complaint verified", assigned: "Complaint assigned", inProgress: "Work in progress", resolved: "Complaint resolved" };
export function eligible(data: Record<string, unknown>) {
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

export function statusToRank(status: string): number {
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

export function reachedStages(data: Record<string, unknown>, history: string[]): Stage[] {
  if (!eligible(data)) return [];
  const allStatuses = [String(data.status || ""), ...history.map(String)];
  const maxRank = Math.max(0, ...allStatuses.map(statusToRank));
  const stages: Stage[] = ["submitted", "verified", "assigned", "inProgress", "resolved"];
  return stages.slice(0, Math.min(maxRank + 1, 5));
}
export function levelFor(points: number) {
  const levels = [
    { level: 1, title: "Civic Starter", minimum: 0, next: 100 },
    { level: 2, title: "Civic Contributor", minimum: 100, next: 250 },
    { level: 3, title: "Civic Champion", minimum: 250, next: 500 },
    { level: 4, title: "Civic Leader", minimum: 500, next: 1000 },
    { level: 5, title: "Civic Hero", minimum: 1000, next: null },
  ];
  return levels.find(l => l.next === null || points < l.next)!;
}
export const ACHIEVEMENTS = [
  { id: "evidence_expert", title: "Evidence Expert", metric: "evidenceReports", target: 5, howToUnlock: "Provide useful images on 5 verified complaints." },
  { id: "ground_reporter", title: "Ground Reporter", metric: "locationReports", target: 5, howToUnlock: "Provide coordinates matching the assigned ward on 5 verified complaints." },
  { id: "community_voice", title: "Community Voice", metric: "communityUpvotes", target: 10, howToUnlock: "Receive support from 10 different citizens on verified complaints." },
  { id: "community_helper", title: "Community Helper", metric: "supportedComplaints", target: 10, howToUnlock: "Support 10 different verified complaints from other citizens. Earn a one-time 10-point bonus." },
  { id: "resolution_champion", title: "Resolution Champion", metric: "reportsResolved", target: 5, howToUnlock: "Have 5 eligible complaints reach resolution." },
] as const;
