# Complaint Gamification Audit

User symptom: complaint lifecycle points and achievement points are not appearing in the user profile.

Scope: local Flutter reward, complaint, profile and achievement code; Supabase reward reconciliation source; checked-in Firestore rules; existing targeted tests. No application code changed. Deployed rules, deployed Edge Functions, authenticated server responses and live account documents were not inspected; deployment parity remains unverified.

## Main finding: award execution and persistence are disconnected

1. Online complaint submission calls RewardEvaluationService.evaluateStage without awaiting it (`offline_first_complaint_repository.dart:372`); routing also calls that client-side evaluator.
2. The evaluator attempts one client Firestore transaction writing reward_events, users.civicPoints and rewards (`reward_evaluation_service.dart:688`).
3. The checked-in rules forbid client rewards writes (`firestore.rules:718`) and updates to civicPoints (`firestore.rules:337`). There is no matching read/write rule for reward_events. Under these rules the transaction cannot succeed. Keeping these fields server-authoritative is correct; weakening rules is not the fix.
4. The service catches the transaction failure at line 741. Its local fallback only persists when the repository itself is HiveUserRepository (line 760). RepositoryLocator selects OfflineFirstUserRepository in the actual offline-first app, so this condition fails and no profile-cache update occurs.
5. The evaluator nevertheless caches the event and returns granted: true (lines 226-239), making failure look successful and blocking a same-session retry as already awarded.

This is a concrete code path explaining the reported missing profile points, assuming deployed rules match the repository.

## Additional confirmed integration defects

### P1: server sync is not connected to lifecycle actions

CivicRewardsSyncService calls the Supabase sync-civic-rewards function. Its only app caller is FirebaseRewardsDataSource.getRewardData. Complaint submission and routing still call the old client evaluator. Server reconciliation exists, but automatic complaint lifecycle processing does not invoke this path in the inspected source. Awards can therefore depend on opening rewards and successful synchronization instead of the complaint action itself.

### P1: fresh server points are replaced with stale profile points

RewardsScreen._loadData reads getCurrentUser before getRewardData (lines 84-85). The latter triggers server reconciliation. Afterward, the screen overrides the fetched reward points with the earlier user.civicPoints (line 133); its widget builder also displays the user repository's cached civicPoints (line 200). OfflineFirstUserRepository.getUserListenable only exposes the local cache, not a Firestore snapshot subscription. Thus a successful reconciliation can still leave the visible profile/rewards balance stale until another profile fetch.

### P1: reward history reads a different collection from the server writer

The server stores events at rewards/{citizenId}/events and recentActivity in the summary (`supabase/functions/_shared/civic-rewards.ts:62-83`). FirebaseRewardsDataSource.getRewardEvents instead queries the top-level reward_events collection. Checked-in rules grant owner reads on the summary only; they do not grant reads to either events path. Errors are swallowed into local fallback. OfflineFirstRewardsRepository also reconstructs RewardDataModel without forwarding server recentActivity, supportedComplaints, reportsVerified, communityUpvotes, or syncPending. This loses the new server contract and hides synchronization failure from the UI.

### P2: achievement progress is discarded/recomputed using incomplete inputs

The server writes achievement progress and target. RewardFirestoreMapper.achievementFromMap does not map those fields to currentProgress/targetProgress. RewardsScreen recomputes achievements from owned complaints without passing supportedComplaints or supportedComplaintsCount. Community Helper therefore falls back to the user's badges or zero instead of the server's supported count. Previously unlocked flags may survive, but progress is not reliably represented. Client evidence/location/upvote criteria also differ from the stricter server policy.

### Achievement points policy clarification

The current policy awards complaint stages 10 + 20 + 15 + 20 + 35 = 100 points. Of the five canonical achievements, only Community Helper explicitly grants a one-time 10-point bonus. Other badges do not currently define separate bonus points. If every achievement is intended to award points, that behavior is missing from the product policy and implementation rather than merely hidden by the UI. The client evaluateCommunityHelperBonus has no application call sites; server reconciliation contains the bonus candidate.

## Tests and coverage gap

Ran:

`flutter test --no-pub test/core/services/reward_evaluation_service_test.dart test/core/services/achievement_evaluator_test.dart test/core/services/community_rewards_anti_abuse_test.dart test/user_ui/rewards_dashboard_phase2_test.dart`

Result: 25 passed. These tests use fake repositories/in-memory award results and do not exercise the real client against Firestore rules, the Supabase sync endpoint, or persistent profile updates. Passing stage-award tests do not establish that points reached the user's stored profile. The evaluator tests check returned awards and cached event totals, which can pass even when persistence is absent.

## Recommended repair order

1. Use one server-authoritative award path for saved complaint lifecycle transitions and community support; stop the client from writing protected reward fields.
2. Return explicit pending/failure versus committed award status. Never mark a failed persistence attempt as awarded.
3. After successful reconciliation, refresh/cache the authoritative user and reward summary together, or subscribe to the appropriate authoritative profile updates.
4. Align event paths and preserve summary recentActivity and all counters/sync flags. Add owner-only reads if the client needs the server event subcollection; retain server-only writes.
5. Map authoritative achievement progress consistently and wire supported-complaint metrics into the UI. Clarify whether additional achievement bonuses are wanted.
6. Add emulator/integration coverage for denied writes, successful server grants, repeated grants, profile refresh after sync, and history/achievement rendering. Verify a real account's before/after persisted balance and confirm Edge Function deployment/auth configuration before claiming a live fix.

## Scoped rules audit (business-logic compatibility)

This score concerns the rewards integration only, not a full security score for the project. Checked owner identity and protected fields: owner-only summary reads; client writes denied; user creates restrict initial points and updates protect counters. Since rewards client writes are entirely denied, field/type/size validation cannot make those writes succeed. No recommendation to loosen protected counters.

```json
{
  "score": 2,
  "summary": "Major rewards business-logic mismatch: the app attempts client award writes that the checked-in server-authoritative rules correctly reject.",
  "findings": [
    {
      "check": "Business Logic vs. Rules",
      "severity": "major",
      "issue": "Client reward transaction writes protected users/rewards fields and an unmatched reward_events collection; failure is reported as an award.",
      "recommendation": "Execute awards through the trusted backend and expose only authorized reads; propagate persistence failures."
    },
    {
      "check": "Field-Level vs. Identity-Level Security",
      "severity": "moderate",
      "issue": "Server events are stored beneath rewards/{userId}/events, but no matching owner-read rule exists and the client queries a different collection.",
      "recommendation": "Align the event contract; use the readable summary or an explicit owner-only subcollection read rule while keeping writes server-only."
    }
  ]
}
```
