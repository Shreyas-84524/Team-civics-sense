# CivicFix Gamification Repair — Phase 1: Audit & Authoritative Reward Contract

**Document Version:** 1.0.0  
**Date:** 09 October 2026  
**Status:** Approved / Investigation & Contract Defined  
**Scope:** Grievance Lifecycle Points, Community Achievements, Security Rules Parity, Live Firestore State & Backend Ownership

---

## 1. Executive Summary

A comprehensive investigation into the CivicFix gamification failure was conducted across client source code, local tests, checked-in Firestore rules, active cloud infrastructure (`civicfix-38d53`), and deployed Supabase endpoints (`hkgwsqasmboadvpjckbj`).

### Core Failure Finding
**Complaint lifecycle points and achievement bonus points are never added to citizen profiles in production.**

The failure is caused by a complete architectural disconnection between client-side reward evaluation, security rules enforcement, and missing backend infrastructure:
1. **Security Rules Rejection:** Complaint lifecycle actions trigger `RewardEvaluationService`, which attempts client-side Firestore transactions directly modifying protected fields (`users.civicPoints`, `rewards/{userId}`, and root `reward_events`). Deployed Firestore Security Rules strictly prohibit client writes to these collections (`allow write: if false` on rewards; updates affecting `civicPoints` denied on users; no matching rules on `reward_events`).
2. **Error Swallowing & Fake Success:** `RewardEvaluationService` catches the resulting `permission-denied` transaction exception, swallows it via `debugPrint`, caches the event ID in-memory, and returns `granted: true`. This masks the failure from the calling repository and permanently blocks retry attempts in the same application session.
3. **Broken Local Cache Fallback:** The service's local cache fallback checks `if (userRepo is HiveUserRepository)`. In production, `RepositoryLocator` supplies `OfflineFirstUserRepository`, causing the type check to evaluate to `false`. As a result, not even local Hive caches receive point updates.
4. **Offline / Missing Server Infrastructure:** The server-authoritative reconciler `sync-civic-rewards` in Supabase is **not deployed** (HTTP 404 `NOT_FOUND`), and Firebase Cloud Functions have **0 functions deployed** in `civicfix-38d53`. Furthermore, the local source of `sync-civic-rewards` contains critical runtime scope errors (`db.query` and `db.commitRewards` misplaced inside `parseDocument`).
5. **Live Verification Evidence:** A live inspection of citizen `pfZM...lbg1` (who filed 5 complaints, including complaint `KaYLHbQD2HKd5Eu7Pxco` which progressed through `submitted` $\rightarrow$ `verified` $\rightarrow$ `assigned` $\rightarrow$ `inProgress`) proved that:
   - Eligible Lifecycle Points: **65 points**.
   - Persisted `users.civicPoints`: **20 points** (the initial signup grant only; 0 lifecycle points added).
   - `rewards/{userId}` document: **Does not exist (404)**.
   - `rewards/{userId}/events` & `reward_events`: **Completely empty (0 documents)**.
6. **False-Positive Tests:** All 32 existing unit, anti-abuse, and widget tests pass because they execute in-memory with `db: null` or mock repositories, never exercising real Firestore transactions, security rules, or network synchronization.

---

## 2. Complete Reward Pipeline Trace

The end-to-end reward pipeline was traced across complaint submission, status updates, evaluation services, database rules, and UI components.

```
+----------------------------------------------------------------------------------------------------+
| 1. COMPLAINT ACTION TRIGGER                                                                        |
| - Online Submission: OfflineFirstComplaintRepository.createComplaint (line 372)                  |
| - Offline Submission: OfflineFirstComplaintRepository.saveOfflineComplaint (line 459)            |
| - Junior Engineer Routing: ComplaintRoutingService.routeComplaintAutomatically (lines 2330, 2334)  |
| - Crew Field Work: ComplaintRoutingService.startFieldWork (line 1756)                              |
| - Crew Resolution: ComplaintRoutingService.resolveComplaint (line 2000)                           |
+----------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
+----------------------------------------------------------------------------------------------------+
| 2. CLIENT EVALUATOR EXECUTION                                                                      |
| - RewardEvaluationService.instance.evaluateStage(complaint, stage) (reward_evaluation_service.dart) |
| - Abuse & Integrity Checks: rejected, AI fake evidence, duplicate quarantine (lines 140-168)      |
| - Grievance point ceiling verification (<= 100 max per complaint) (lines 192-204)                  |
| - Creates RewardEvent with id: rwe_${complaint.id}_${stage.stageKey} (lines 207-223)               |
+----------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
+----------------------------------------------------------------------------------------------------+
| 3. TRANSACTIONAL PERSISTENCE ATTEMPT (_recordAwardTransaction, lines 688-743)                      |
| - Executes db.runTransaction:                                                                      |
|     a) Set doc in collection 'reward_events/{eventId}'                                             |
|     b) Increment 'users/{citizenId}.civicPoints'                                                   |
|     c) Merge updates into 'rewards/{citizenId}'                                                    |
+----------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
+----------------------------------------------------------------------------------------------------+
| 4. FIRESTORE SECURITY RULES ENFORCEMENT                                                            |
| - 'reward_events': No rule exists -> Client writes strictly REJECTED [PERMISSION-DENIED]           |
| - 'users/{citizenId}': Rule 334-348 forbids modifying 'civicPoints' -> REJECTED [PERMISSION-DENIED]|
| - 'rewards/{citizenId}': Rule 718 specifies 'allow write: if false' -> REJECTED [PERMISSION-DENIED] |
| Result: Entire transaction throws FirebaseException (permission-denied).                          |
+----------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
+----------------------------------------------------------------------------------------------------+
| 5. ERROR HANDLING & FAKE AWARD STATE                                                               |
| - Catch block at line 741 catches and swallows permission exception with debugPrint.               |
| - Fallback checks: if (userRepo is HiveUserRepository) (line 760).                                 |
|   In production, userRepo is OfflineFirstUserRepository -> CONDITION FAILS -> No cache update.   |
| - Line 229: _awardedEventIds.add(eventId) -> Cached as awarded in-memory.                          |
| - Line 236: Returns RewardEvaluationResult(granted: true, pointsAwarded: X). Fake success!         |
+----------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
+----------------------------------------------------------------------------------------------------+
| 6. REWARDS DASHBOARD & PROFILE DISPLAY                                                             |
| - User opens RewardsScreen (_loadData, rewards_screen.dart:84-158):                                |
|     1. Calls userRepo.getCurrentUser() -> Reads stale Firestore/Hive profile (20 points).          |
|     2. Calls rewardsRepo.getRewardData() -> Calls CivicRewardsSyncService.sync().                  |
|     3. SyncService sends HTTP POST to Supabase sync-civic-rewards.                                 |
|        Endpoint returns 404 NOT FOUND (function not deployed) -> sync returns false.               |
|     4. RewardsDataSource returns default RewardDataModel(points: 0, syncPending: true).            |
|     5. Line 133: Screen OVERWRITES data.currentPoints with user.civicPoints (stale 20 points).     |
|     6. Widget tree (line 196) binds to OfflineFirstUserRepository.getUserListenable(), which      |
|        listens only to local Hive box without Firestore sync -> Displays stale 20 points forever.  |
+----------------------------------------------------------------------------------------------------+
```

### Detailed Stage Trace & Metrics

| Lifecycle Stage | Award Points | Trigger File & Line | Evaluator Call | Persisted Collection Attempt | Deployed Rule Result |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **Submitted** | +10 | `offline_first_complaint_repository.dart:372` (online)<br>`offline_first_complaint_repository.dart:459` (offline) | `RewardEvaluationService.evaluateStage(..., submitted)` | `reward_events`<br>`users.civicPoints`<br>`rewards` | **DENIED** (Rules 334, 718) |
| **Verified** | +20 | `complaint_routing_service.dart:2330` | `RewardEvaluationService.evaluateStage(..., verified)` | Same client tx | **DENIED** (Rules 334, 718) |
| **Assigned** | +15 | `complaint_routing_service.dart:2334` | `RewardEvaluationService.evaluateStage(..., assigned)` | Same client tx | **DENIED** (Rules 334, 718) |
| **In Progress** | +20 | `complaint_routing_service.dart:1756` | `RewardEvaluationService.evaluateStage(..., inProgress)` | Same client tx | **DENIED** (Rules 334, 718) |
| **Resolved** | +35 | `complaint_routing_service.dart:2000` | `RewardEvaluationService.evaluateStage(..., resolved)` | Same client tx | **DENIED** (Rules 334, 718) |
| **Community Helper** | +10 (one-time) | **Zero application call sites.** Client method `evaluateCommunityHelperBonus` exists at `reward_evaluation_service.dart:455` but is never called. | `RewardEvaluationService.evaluateCommunityHelperBonus` | Same client tx | **NEVER INVOKED** |

**Does reward awarding depend on opening the rewards screen?**  
- **Currently:** In theory, complaint lifecycle triggers attempt client evaluation immediately, but fail due to security rules. The only backend reconciliation attempt in the entire codebase exists inside `FirebaseRewardsDataSource.getRewardData` (triggered exclusively when `RewardsScreen` loads). However, because the Supabase function is not deployed (HTTP 404), opening the screen also fails to award points.

---

## 3. Verification of Previous Audit Findings

Every finding documented in `COMPLAINT_GAMIFICATION_AUDIT.md` was investigated against the active codebase and production environment:

| Audit Finding | Verification Status | Exact File & Line Reference | Notes & Technical Evidence |
| :--- | :---: | :--- | :--- |
| **1. Complaint actions call RewardEvaluationService** | **CONFIRMED** | `offline_first_complaint_repository.dart:372, 459`<br>`complaint_routing_service.dart:1756, 2000, 2330, 2334` | `unawaited(RewardEvaluationService.instance.evaluateStage(...))` is invoked directly across complaint creation, routing, work start, and resolution. |
| **2. Evaluator attempts client writes to protected fields** | **CONFIRMED** | `reward_evaluation_service.dart:697-738`<br>`firestore.rules:334-348, 718` | `_recordAwardTransaction` calls `db.runTransaction` targeting `reward_events`, `users.civicPoints`, and `rewards`. All three paths are protected by security rules. |
| **3. Firestore transaction errors are swallowed** | **CONFIRMED** | `reward_evaluation_service.dart:740-742` | `catch (e) { debugPrint('[RewardEvaluationService] Firestore award transaction note (fallback to local): $e'); }` catches and suppresses exceptions. |
| **4. Failed transactions return granted: true / mark awarded** | **CONFIRMED** | `reward_evaluation_service.dart:226-243` | Line 229 adds `eventId` to `_awardedEventIds`; line 236 returns `RewardEvaluationResult(granted: true, ...)`. Subsequent calls hit line 125 and return already awarded. |
| **5. Local fallback only handles HiveUserRepository** | **CONFIRMED** | `reward_evaluation_service.dart:760`<br>`repository_locator.dart:146-154` | Line 760: `if (userRepo is HiveUserRepository)`. In app runtime, `userRepo` is `OfflineFirstUserRepository`, so cache write is skipped. |
| **6. CivicRewardsSyncService only connected to reward loading** | **CONFIRMED** | `firebase_rewards_data_source.dart:23`<br>`civic_rewards_sync_service.dart:6-18` | Only single call site in `getRewardData`. Complaint creation and status transitions never call `CivicRewardsSyncService.sync()`. |
| **7. RewardsScreen displays stale profile points** | **CONFIRMED** | `rewards_screen.dart:84-85, 133, 196-201` | Screen reads `getCurrentUser()` before sync, then overwrites `data.currentPoints` with `user.civicPoints`. UI builder binds to `userRepository.getUserListenable()` which lacks Firestore stream. |
| **8. Server and client use different reward-event paths** | **CONFIRMED** | `civic-rewards.ts:62-72` vs `firebase_rewards_data_source.dart:55-59` | Server writes to `rewards/{citizenId}/events/{eventId}`. Client queries root `reward_events` where `citizenId == userId`. Neither collection permits client operations. |
| **9. Repository mapping drops counters & syncPending** | **CONFIRMED** | `offline_first_rewards_repository.dart:36-52` | Reconstructs `RewardDataModel` discarding `reportsVerified`, `communityUpvotes`, `supportedComplaints`, `recentActivity`, and `syncPending`. |
| **10. Achievement mapping drops progress/target fields** | **CONFIRMED** | `reward_firestore_mapper.dart:90-112` | `achievementFromMap` parses title, description, unlock status, but completely omits `currentProgress` and `targetProgress` parsing. |
| **11. Community Helper lacks authoritative count** | **CONFIRMED** | `rewards_screen.dart:120-124`<br>`achievement_evaluator.dart:114-120` | `RewardsScreen` does not provide `supportedComplaintsCount` to `AchievementEvaluator`; evaluator falls back to binary `user.badges.contains('community_helper') ? 10 : 0`. |

---

## 4. Deployed Configuration & Infrastructure Parity

Authorized diagnostic access was used to evaluate deployed cloud configurations:

### Firebase Project: `civicfix-38d53`
- **Status:** Active (Project Number: `594524642298`, Region: `asia-south1`).
- **Deployed Firestore Security Rules:**
  - `users/{userId}`: Client update strictly prohibits modifying `civicPoints`, `reportsSubmitted`, `reportsResolved`, `badges`.
  - `rewards/{userId}`: Client write strictly prohibited (`allow write: if false;`).
  - `rewards/{userId}/events/{eventId}`: Subcollection has no rule defined (denied by default).
  - `reward_events`: Root collection has no rule defined (denied by default).
  - **Parity Result:** Deployed rules match checked-in `firestore.rules` 100%. Security rules correctly protect database integrity.
- **Deployed Firebase Cloud Functions:**
  - Output of `functions_list_functions`: **`functions: []` (0 functions deployed)**.
  - No background Firestore triggers are active in the project.

### Supabase Project: `hkgwsqasmboadvpjckbj`
- **Region:** `ap-south-1` (AWS Mumbai).
- **Endpoint:** `https://hkgwsqasmboadvpjckbj.supabase.co/functions/v1/sync-civic-rewards`.
- **Diagnostic Request:** HTTP `OPTIONS` / probe request.
- **Diagnostic Response:**  
  `HTTP/1.1 404 Not Found`  
  `{"code":"NOT_FOUND","message":"Requested function was not found"}`
- **Parity Result:** The reconciliation function is **completely undeployed**.

### Critical Local Source Defect in `sync-civic-rewards`
Inspection of `supabase/functions/_shared/complaint-firestore.ts` revealed that even if deployed, the function would crash immediately at runtime:
```typescript
// complaint-firestore.ts lines 55-84:
function parseDocument(raw: ...) {
  return {
    async query(...) { ... fetch(`${root}:runQuery` ... token) ... }, // ERROR: root & token are undefined in this scope!
    async commitRewards(...) { ... fetch(`${root}:commit` ... token) ... }, // ERROR: root & token undefined!
    name: raw.name,
    updateTime: raw.updateTime,
    data: ...
  };
}

export async function createComplaintFirestore() {
  // root & token declared here (lines 92-93)
  return {
    async get(path: string) { ... },
    async patch(...) { ... },
    async list(...) { ... },
    // ERROR: query and commitRewards are NOT returned on db!
  };
}
```
In `civic-rewards.ts:13, 83`:
`await db.query(...)` and `await db.commitRewards(...)` will throw `TypeError: db.query is not a function`.

---

## 5. Live Affected Complaint Evidence

To confirm the user-reported issue without modifying production data, read-only diagnostic inspections were performed on existing complaint and user documents in `civicfix-38d53`.

*(Personal Identifiable Information redacted pursuant to security standards)*

### Affected Citizen Record
- **User Document:** `projects/civicfix-38d53/databases/(default)/documents/users/pfZMsRAkKCQvUBpd8KWPowEMlbg1`
- **Citizen UID:** `pfZMsRAkKCQvUBpd8KWPowEMlbg1` (Redacted: `pfZM...lbg1`)
- **Citizen Name:** S*** S***
- **Phone:** `+919869****60` (Verified: `true`)
- **Ward:** Ward R/North (Dahisar)
- **Account Created:** `2026-09-28T17:39:41.840Z`
- **Stored `reportsSubmitted`:** `5`
- **Stored `reportsResolved`:** `0`
- **Authoritative `users.civicPoints`:** **`20`** (Initial citizen signup allowance only).

### Affected Complaint Record
- **Document Path:** `projects/civicfix-38d53/databases/(default)/documents/complaints/KaYLHbQD2HKd5Eu7Pxco`
- **Document ID:** `KaYLHbQD2HKd5Eu7Pxco`
- **Ticket Number:** `CF-2026-1791090369943000-64ce47c897cc`
- **Citizen ID:** `pfZMsRAkKCQvUBpd8KWPowEMlbg1`
- **Title:** "Garbage Spotted on road"
- **Category:** Waste Management (`solid_waste_management`)
- **Status:** **`inProgress`**
- **Creation Timestamp:** `2026-10-04T05:06:11.378Z`
- **Verification Details:** Completed `2026-10-04T05:06:19.704Z` (`departmentVerificationScore: 1`, `aiAnalysisStatus: completed`)
- **Assignment Details:** Assigned to crew `GOV-CREW-R_NORTH-SOLID_WASTE_MANAGEMENT-01` (`2026-10-04T05:06:22.173Z`)

### Reward Persistence Audit for Citizen `pfZM...lbg1`
1. **Eligible Lifecycle Stages & Points:**
   - `submitted`: +10 pts
   - `verified`: +20 pts
   - `assigned`: +15 pts
   - `inProgress`: +20 pts
   - **Total Earned for Complaint `KaYLHbQD2HKd5Eu7Pxco`:** **65 points**.
   - Combined with 4 other submitted complaints (+40 pts): **Eligible Total = 125 points**.
2. **Actual Firestore State:**
   - `users/pfZMsRAkKCQvUBpd8KWPowEMlbg1.civicPoints`: **`20`** (Expected: at least 85, up to 125).
   - Document `rewards/pfZMsRAkKCQvUBpd8KWPowEMlbg1`: **NOT FOUND (404)**.
   - Subcollection `rewards/pfZMsRAkKCQvUBpd8KWPowEMlbg1/events`: **0 documents (Empty)**.
   - Collection `reward_events`: **0 documents (Empty)**.
   - Collection `rewards`: **0 documents (Empty across all citizens)**.

### Root Cause Conclusion
The live failure is **CONFIRMED WITH DEFINITIVE EVIDENCE**. The failure is **NOT** a UI rendering glitch or cache lag; **no gamification points or events have ever been written to Cloud Firestore in production** due to client write rejections and missing backend services.

---

## 6. Confirmed Defects Ranked by Impact

| Rank | Severity | Defect | Impact |
| :---: | :---: | :--- | :--- |
| **1** | **P0 (Critical)** | **Client attempts direct writes to protected Firestore reward fields** | 100% of reward transactions fail with `permission-denied`. Points can never reach Firestore. |
| **2** | **P0 (Critical)** | **Supabase reconciler function is not deployed & Firebase Cloud Functions has 0 deployed triggers** | No backend authority exists in production to credit points or reconcile balances. |
| **3** | **P1 (High)** | **Swallowed transaction errors report fake success (`granted: true`)** | Calling repositories believe points were awarded and block future retries. |
| **4** | **P1 (High)** | **Broken local cache fallback (`userRepo is HiveUserRepository`)** | OfflineFirstUserRepository prevents updating even the local offline profile cache. |
| **5** | **P1 (High)** | **RewardsScreen overwrites fresh reward data with stale profile points** | Overrides `data.currentPoints` with pre-sync `user.civicPoints` (20 points). |
| **6** | **P1 (High)** | **Mismatched reward-event collection paths & missing subcollection rules** | Server writes `rewards/{uid}/events`, client reads `reward_events`. No read rule on either. |
| **7** | **P2 (Medium)** | **`OfflineFirstRewardsRepository` drops metrics, recentActivity, and syncPending** | Reconstructed model loses server telemetry and hides synchronization state from UI. |
| **8** | **P2 (Medium)** | **`RewardFirestoreMapper` drops achievement progress and target fields** | Badges cannot display numeric progression bars from server data. |
| **9** | **P2 (Medium)** | **`Community Helper` receives zero or fallback progress instead of authoritative count** | Citizen cannot track progress toward the 10-upvote community bonus. |
| **10** | **P2 (Medium)** | **Runtime scope errors in `complaint-firestore.ts`** | Undeclared variables `root` and `token` crash the TypeScript function if deployed. |

---

## 7. Authoritative Reward Contract

To establish an unbreachable architecture for Phase 2 implementation, the following contract defines the single source of truth for all gamification operations.

### 7.1 Single Trusted Backend Owner
- **Principle:** Direct client writes to `rewards`, `users.civicPoints`, or `reward_events` are strictly prohibited.
- **Backend Authority:** A single, trusted backend worker running with Google Service Account / Firebase Admin credentials will own all reward writes.
- **Execution Mechanism:**
  1. **Primary Backend Reconciler:** A dedicated backend service endpoint (`sync-civic-rewards`) authenticated via Firebase ID tokens (`Bearer <idToken>`).
  2. **Automated Triggers:** Background Firestore triggers in Cloud Functions (`onComplaintCreated`, `onComplaintStatusChanged`) or transactional calls from server routes that invoke the reconciliation logic upon lifecycle state transitions.

### 7.2 Point Allocation Policy (Immutable)

```
Complaint Lifecycle Progression:
  +10 pts  - Submitted
  +20 pts  - Verified
  +15 pts  - Assigned
  +20 pts  - Work in Progress
  +35 pts  - Resolved
  -------------------------------------------------------------
  100 pts  - Maximum Lifecycle Total per Grievance

Community Badges:
  +10 pts  - Community Helper (One-time bonus upon supporting >= 10 verified complaints)
    0 pts  - Other 4 badges (Milestone recognitions; no direct points)
```

### 7.3 Data Models & Paths

#### Authoritative Profile Balance
- **Path:** `users/{citizenId}`
- **Field:** `civicPoints` (integer, non-negative).
- **Rule:** Write denied to clients; incremented strictly by backend using atomic field transforms (`FieldValue.increment`).

#### Authoritative Reward Summary
- **Path:** `rewards/{citizenId}`
- **Schema:**
  ```json
  {
    "userId": "string (Firebase UID)",
    "points": 125,
    "lifetimePoints": 125,
    "openingBalance": 20,
    "reportsSubmitted": 5,
    "reportsVerified": 1,
    "reportsResolved": 0,
    "evidenceReports": 1,
    "locationReports": 1,
    "communityUpvotes": 0,
    "supportedComplaints": 0,
    "level": 2,
    "levelTitle": "Civic Contributor",
    "nextMilestoneTarget": 250,
    "achievements": [
      {
        "id": "community_helper",
        "title": "Community Helper",
        "progress": 0,
        "target": 10,
        "isUnlocked": false,
        "unlockedAt": null
      }
    ],
    "recentActivity": [ /* up to 30 latest RewardEvent records */ ],
    "updatedAt": "2026-10-09T16:50:00.000Z",
    "policyVersion": 1
  }
  ```

#### Authoritative Reward Events
- **Path:** `rewards/{citizenId}/events/{eventId}` (Subcollection)
- **Schema:**
  ```json
  {
    "id": "rwe_<complaintKey>_<stage>",
    "citizenId": "string (Firebase UID)",
    "complaintId": "string (Complaint doc ID)",
    "complaintTitle": "string (Max 200 chars)",
    "rewardType": "submitted | verified | assigned | inProgress | resolved | community_helper",
    "points": 20,
    "description": "Complaint verified",
    "createdAt": "2026-10-09T16:50:00.000Z",
    "metadata": {
      "ticketNumber": "string",
      "category": "string",
      "status": "string"
    }
  }
  ```

### 7.4 Deterministic Idempotency Keys
To prevent duplicate awards during offline replay, network retries, or concurrent re-evaluations:
- **Complaint Stage Key:**  
  `eventId = SHA256("${citizenId}:${localId || ticketNumber || complaintId}")_${stage}`
- **Community Helper Achievement Key:**  
  `eventId = "achievement_community_helper_${citizenId}"`
- **Atomic Precondition:** When writing events, the backend includes `currentDocument: { exists: false }` for each event document in the batch commit.

### 7.5 Atomic Write Boundary
All reward mutations must commit inside a single atomic Firestore transaction or batch write:
1. `CREATE` all missing `rewards/{citizenId}/events/{eventId}` documents.
2. `SET/MERGE` updated metrics, levels, and achievements on `rewards/{citizenId}` with `currentDocument.updateTime` concurrency check.
3. `TRANSFORM` `users/{citizenId}.civicPoints` with `increment(delta)`.

### 7.6 Lifecycle & Anti-Abuse Rules
- **Multi-Stage Catch-Up:** If a complaint jumps directly to `assigned` or `resolved`, all eligible prior stages are backfilled in order up to the ceiling of 100 points.
- **Reopen & Rework Safety:** A reopened complaint (`inProgress`, `reopenCount > 0`) does NOT forfeit previously awarded points, and cannot re-earn points when moving back to `inProgress` or `resolved`.
- **Abuse Quarantine:** Any complaint with `status == 'rejected'`, `isDuplicate == true`, `evidenceVerificationStatus == 'failed'`, or `isAiGeneratedEvidenceRejected == true` is quarantined: no stages beyond `submitted` can earn points.
- **Self-Upvote Quarantine:** Upvotes where `vote.userId == complaint.citizenId` are excluded from community counts.

### 7.7 Response Status Semantics
Any reward reconciliation endpoint must return explicit, unambiguous response status codes:
- `committed`: New reward events were created; points incremented.
- `already_awarded`: All eligible events already exist; balance is up to date.
- `pending`: Operation queued for processing.
- `failed`: An error occurred; no points were granted; retry permitted.

---

## 8. Test Coverage Analysis

### Current Test Execution Summary
Ran 6 targeted reward and achievement test suites:
- `test/core/services/achievement_evaluator_test.dart` (6 tests) $\rightarrow$ **PASS**
- `test/core/services/reward_evaluation_service_test.dart` (7 tests) $\rightarrow$ **PASS**
- `test/core/services/community_rewards_anti_abuse_test.dart` (8 tests) $\rightarrow$ **PASS**
- `test/user_ui/rewards_phase5_production_qa_test.dart` (4 tests) $\rightarrow$ **PASS**
- `test/user_ui/rewards_dashboard_phase2_test.dart` (4 tests) $\rightarrow$ **PASS**
- `test/user_ui/achievement_card_test.dart` (3 tests) $\rightarrow$ **PASS**
- **Total:** **32 / 32 Passed (100%)**.

### Why Existing Tests Pass While Live Balances Fail
1. **Mock Repositories:** Tests inject `MockUserRepository` and `MockComplaintRepository`, which never invoke network calls or check Firestore security rules.
2. **`db: null` Injection:** Unit tests initialize `RewardEvaluationService(db: null)`. As a result, the entire Firestore transaction write (`if (db != null)`) is skipped during testing.
3. **In-Memory Cache Assertions:** Tests assert that the service's returned `RewardEvaluationResult.granted` is `true` and that in-memory collections hold events.
4. **No Security Rules Testing:** None of the tests run against the Firebase Local Emulator with live `firestore.rules`.
5. **No Network / HTTP Testing:** Tests do not invoke `CivicRewardsSyncService` or attempt to connect to the Supabase endpoint.

### Integration Tests Required for Phase 5
1. **Rules Denied Test:** Verify that unprivileged client writes to `rewards/{uid}` or `users/{uid}.civicPoints` are rejected with `PERMISSION_DENIED`.
2. **Backend Admin Write Test:** Verify that the backend service account successfully writes events and increments `users.civicPoints`.
3. **Idempotency Test:** Execute reconciliation twice on the same complaint and verify `delta == 0` on the second run.
4. **Offline Replay Test:** Verify that an offline submission followed by online sync creates exactly 1 submission event.
5. **Profile Cache Stream Test:** Verify that when `users.civicPoints` updates in Firestore, `OfflineFirstUserRepository.getUserListenable()` updates the UI without manual page reloads.

---

## 9. Existing-Data and Migration Risks

1. **Backfill Drift for Existing Accounts:**
   - Existing citizens (like `pfZM...lbg1`) have completed historical complaint milestones that were never awarded.
   - *Mitigation:* The authoritative reconciliation engine must process all past complaints for a citizen on first run, backfilling missing lifecycle points up to the 100 pt cap per complaint.
2. **Signup Bonus Consistency:**
   - Registration rules permit initial points of 0 or 20 (`request.resource.data.civicPoints in [0, 20]`).
   - *Mitigation:* Backend reconciler respects `user.civicPoints` as the opening balance baseline; it only adds new lifecycle deltas.
3. **Collection Fragmentation:**
   - Some code references top-level `reward_events`, while server reconciler uses subcollection `rewards/{userId}/events`.
   - *Mitigation:* Standardize exclusively on subcollection `rewards/{userId}/events/{eventId}` with owner-read security rules. Do not write to top-level `reward_events`.

---

## 10. Concrete Implementation Tasks for Phases 2–5

### Phase 2: Authoritative Backend Deployment & Infrastructure Repair
- [ ] Fix syntax/scope defects in `supabase/functions/_shared/complaint-firestore.ts` (export `query` and `commitRewards` on `db` object; ensure `root` and `token` are properly scoped).
- [ ] Deploy `sync-civic-rewards` to the Supabase Edge Runtime or implement native Firebase Cloud Functions triggers.
- [ ] Update `firestore.rules` to allow owner read on `rewards/{userId}/events/{eventId}`:
  ```rules
  match /rewards/{userId} {
    allow read: if isOwner(userId);
    allow write: if false;

    match /events/{eventId} {
      allow read: if isOwner(userId);
      allow write: if false;
    }
  }
  ```
- [ ] Deploy updated Firestore security rules.

### Phase 3: Client Decoupling & Error Remediation
- [ ] Deprecate client-side Firestore transaction writes in `RewardEvaluationService`.
- [ ] Refactor `RewardEvaluationService` to return `pending` or delegate to `CivicRewardsSyncService.sync(complaintId)`.
- [ ] Wire `CivicRewardsSyncService.sync()` into complaint submission and status update handlers.
- [ ] Fix `OfflineFirstRewardsRepository` mapping: preserve `reportsVerified`, `communityUpvotes`, `supportedComplaints`, `recentActivity`, and `syncPending`.
- [ ] Fix `RewardFirestoreMapper`: map `progress` and `target` to `CivicAchievement.currentProgress` and `targetProgress`.

### Phase 4: UI & Profile State Synchronization
- [ ] Update `RewardsScreen._loadData`: do not overwrite server points with stale pre-sync profile points.
- [ ] Bind `RewardsScreen` to `RewardDataModel.currentPoints` or ensure `OfflineFirstUserRepository` refreshes Hive from Firestore after sync.
- [ ] Wire `supportedComplaints` count into `AchievementEvaluator.evaluateAchievements` in `RewardsScreen`.

### Phase 5: Verification, Backfill & Integration QA
- [ ] Trigger server reconciliation for affected citizen `pfZM...lbg1` and verify balance increases from 20 to 85+ points.
- [ ] Verify that `rewards/{uid}` summary and `rewards/{uid}/events` subcollections are populated.
- [ ] Verify that `RewardsScreen` displays the updated level, progress bar, and recent reward events.
- [ ] Add and execute integration test suites covering emulator rules enforcement and idempotency.

---

## 11. Unresolved Product Decisions

1. **Point Bonuses for Other Badges:**
   - Currently, only `Community Helper` defines an explicit +10 point bonus. Badges `Evidence Expert`, `Ground Reporter`, `Community Voice`, and `Resolution Champion` grant visual badges only.
   - *Recommendation:* Maintain the current policy (no additional points) to avoid point inflation.
2. **Backend Hosting Strategy:**
   - Both Supabase Edge Functions (`sync-civic-rewards`) and Firebase Cloud Functions (`civic_app/functions`) exist in the project, but neither is deployed for rewards.
   - *Recommendation:* Deploy `sync-civic-rewards` on Supabase Edge Functions as the primary reconciliation worker, authenticated via Firebase ID tokens.
