# CivicFix Gamification Repair — Phases 3 & 4 Report
**Profile Synchronization, Reward History, and Achievement Display**

---

## 1. Executive Summary

Phases 3 and 4 of the CivicFix Gamification Repair resolve all client-side synchronization defects, profile balance inconsistencies, reward history misalignments, and achievement calculation anomalies identified in the Phase 1 audit and supported by the Phase 2 backend engine.

### Key Outcomes:
- **Profile & Rewards Balance Parity:** `ProfileScreen` and `RewardsScreen` now strictly resolve points from the authoritative server balance (`data.currentPoints` / `user.civicPoints`). When authoritative points are fetched, local user caches are updated synchronously without dropping fields.
- **Stale Overwrite Elimination:** Removed legacy client overwrites in `RewardsScreen` and `HiveRewardsRepository` where client-calculated values or static initial user points would clobber fresh server totals.
- **Canonical History Subcollection:** Reward history is read directly from the canonical subcollection `rewards/{userId}/events` (secured with owner-only read rules), falling back cleanly to cached events during offline modes.
- **Complete Field Preservation:** `OfflineFirstRewardsRepository`, `OfflineFirstUserRepository`, and Firestore mappers preserve all counters: `reportsVerified`, `communityUpvotes`, `supportedComplaints`, `recentActivity`, and `syncPending`.
- **Account Switching Isolation:** `OfflineFirstUserRepository` detects UID transitions and purges stale local cache, preventing cross-account data and points leakage.
- **Authoritative Achievement Model:** Standardized targets (`evidence_expert`: 5, `ground_reporter`: 5, `community_voice`: 10, `community_helper`: 10, `resolution_champion`: 5) across models, mappers, and `AchievementEvaluator`.
- **Community Helper & Bonus Integrity:** Community Helper relies on authoritative `supportedComplaints` from server metrics. The one-time +10 bonus is reflected exclusively through committed backend events without client-side point mutations. The remaining four badges remain recognition-only (0 pts).

---

## 2. Phase 3: Profile, Points, and History Synchronization

### 2.1 Authoritative Point Synchronization
- **Problem:** `RewardsScreen` previously overwrote the fresh server reward balance with `user.civicPoints` from the un-synchronized local user profile, resetting displayed balances back to baseline values.
- **Resolution:** 
  - `RewardsScreen._loadData()` now computes `authoritativePoints = data.currentPoints > 0 ? data.currentPoints : user.civicPoints`.
  - When `user.civicPoints != authoritativePoints`, the active user profile cache in `HiveUserRepository` / `OfflineFirstUserRepository` is updated automatically.
  - `ProfileScreen` hydrates `_userRepository.getCurrentUser()` upon load and supports pull-to-refresh (`RefreshIndicator`), guaranteeing that navigating between Profile and Rewards displays identical point balances.

### 2.2 Canonical Reward Event History
- **Path:** `rewards/{userId}/events/{eventId}`
- **Security Rule:** Owner-only read (`allow read: if isOwner(userId); allow write: if false;`).
- **Client Read Logic:** `FirebaseRewardsDataSource.getRewardEvents(userId)` queries `_rewardsRef.doc(userId).collection('events').orderBy('awardedAt', descending: true).get()`.
- **UI Integration:** `RewardsScreen` loads events through `_rewardsRepository.getRewardEvents(user.id)`, falling back to `RewardEvaluationService.instance.getRewardHistory(user.id)` and cached `data.recentActivity` when offline.

### 2.3 Repository Field Mapping & Integrity
- **Mappers:** `RewardFirestoreMapper` and `UserFirestoreMapper` safely handle `num?` values (converting integers, doubles, and string numbers) without dropping data.
- **Preserved Fields:**
  - `reportsVerified`: Count of verified complaints.
  - `communityUpvotes`: Total upvotes received across citizen complaints.
  - `supportedComplaints`: Verified complaints by other citizens supported by this user (authoritative metric for Community Helper).
  - `recentActivity`: List of canonical `RewardEvent` items.
  - `syncPending`: Boolean flag tracking offline pending synchronization status.

### 2.4 Account Switching & Multi-User Isolation
- **Mechanism:** In `OfflineFirstUserRepository.getCurrentUser()`:
  ```dart
  if (local.id.isNotEmpty && uid.isNotEmpty && local.id != uid) {
    await _localRepo.clearUserCache();
  }
  ```
- **Result:** When an officer or citizen signs out and a new user signs in on the same device, previous reward caches and user profile points are purged immediately.

---

## 3. Phase 4: Achievement Display & Target Synchronization

### 3.1 Canonical 5 MVP Achievements & Standard Targets
All 5 badges are defined with explicit targets and requirements:
| Achievement ID | Title | Target Progress | Requirement | Reward Policy |
| :--- | :--- | :---: | :--- | :--- |
| `evidence_expert` | Evidence Expert | 5 | Provide useful photos on 5 verified complaints | Badge only (0 pts) |
| `ground_reporter` | Ground Reporter | 5 | Provide coordinates in assigned ward on 5 verified complaints | Badge only (0 pts) |
| `community_voice` | Community Voice | 10 | Receive upvotes from 10 different citizens on verified complaints | Badge only (0 pts) |
| `community_helper` | Community Helper | 10 | Support 10 verified complaints by others | **One-time +10 bonus** |
| `resolution_champion` | Resolution Champion | 5 | Have 5 eligible complaints reach resolution | Badge only (0 pts) |

### 3.2 Target Progress Mapping & Persistence
- **Model:** `CivicAchievement` includes `targetProgress` field with `progressRatio = (currentProgress / targetProgress).clamp(0.0, 1.0)`.
- **Firestore Mapper:** `achievementFromMap` and `achievementToMap` serialize `targetProgress`, `currentProgress`, `isUnlocked`, and `unlockedAt`.
- **Immutable Timestamps:** `AchievementEvaluator` preserves the existing `unlockedAt` date when an achievement is already unlocked or evaluates to unlocked, preventing timestamp resetting across app restarts.

### 3.3 Elimination of Conflicting Client Calculations
- `HiveRewardsRepository.getRewardData()` had legacy points-based unlock recalculations that mutated achievement states locally based on total points. These have been removed.
- `AchievementEvaluator.evaluateAchievements()` accepts authoritative server counts (`supportedComplaintsCount: data.supportedComplaints`), ensuring that Community Helper accurately tracks backend-verified support actions.

---

## 4. Code Modifications

| File | Component | Changes Made |
| :--- | :--- | :--- |
| [reward_model.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/models/reward_model.dart) | Domain Models | Added `targetProgress` to `CivicAchievement`, configured default targets (5, 5, 10, 10, 5), updated `copyWith` and `defaultAchievements`. |
| [reward_firestore_mapper.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/firebase/mappers/reward_firestore_mapper.dart) | Firestore Mapper | Added serialization/deserialization for `targetProgress`, `currentProgress`, `unlockedAt`, `supportedComplaints`, and `communityUpvotes`. |
| [user_firestore_mapper.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/firebase/mappers/user_firestore_mapper.dart) | Firestore Mapper | Added robust `num?` conversion for `civicPoints`, `reportsSubmitted`, and `reportsResolved`. |
| [offline_first_user_repository.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/repositories/offline_first_user_repository.dart) | Repository | Added UID mismatch detection to purge local cache on account switch; ensured server `civicPoints` remain authoritative. |
| [offline_first_rewards_repository.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/repositories/offline_first_rewards_repository.dart) | Repository | Mapped all server metrics and history without dropping fields; added offline caching and error fallback. |
| [hive_rewards_repository.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/repositories/hive_rewards_repository.dart) | Local Repository | Removed legacy points-based achievement recalculations; preserved stored achievement states and progress. |
| [achievement_evaluator.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/services/achievement_evaluator.dart) | Evaluator | Updated evaluation logic to use canonical targets and authoritative `supportedComplaintsCount`; preserved immutable `unlockedAt` timestamps. |
| [rewards_screen.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/User%20UI/screens/rewards_screen.dart) | Citizen UI | Synchronized `authoritativePoints` with user profile; read history from canonical subcollection; passed live complaints and supported complaints to evaluator. |
| [profile_screen.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/User%20UI/screens/profile_screen.dart) | Citizen UI | Added pull-to-refresh (`RefreshIndicator`) and initial user profile reload on load. |
| [civic_rewards_sync_service.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/services/civic_rewards_sync_service.dart) | Network Client | Clean null-aware element formatting for reconciliation payloads. |
| [firebase_rewards_data_source.dart](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/firebase/firestore/firebase_rewards_data_source.dart) | Data Source | Cleaned unused imports; reads from `rewards/{userId}/events`. |

---

## 5. Verification and Test Results

### 5.1 Static Analysis (`flutter analyze`)
- **Command:** `flutter analyze`
- **Result:** `No issues found! (ran in 34.3s)` — 0 errors, 0 warnings, 0 lints.

### 5.2 Gamification & Rewards Test Suites
All relevant reward, service, mapper, repository, and UI test suites executed and passed:

```
00:04 +36: All tests passed!
- test/core/services/reward_evaluation_service_test.dart (Full lifecycle 100 pts, reopens, fraud rejection, deduplication)
- test/core/services/community_rewards_anti_abuse_test.dart (Community Helper unlock at 10, Community Voice progress)
- test/core/firebase/firestore_mappers_test.dart (Reward and user mapper serialization)
- test/user_ui/rewards_dashboard_phase2_test.dart (Dashboard rendering, Level progression, dynamic points update)
- test/user_ui/rewards_phase5_production_qa_test.dart (4 required sections, offline banner, lifecycle QA)
```

```
00:01 +15: All tests passed!
- test/core/repositories/hive_rewards_repository_test.dart (Cache retrieval, points aggregation)
- test/core/repositories/hive_user_repository_test.dart (User profile caching, ValueListenable updates)
- test/core/services/achievement_evaluator_test.dart (Evidence Expert unlock at 5 verified complaints)
- test/user_ui/achievement_card_test.dart (Locked/unlocked rendering with progress and dates)
```

```
00:00 +16: All tests passed!
- test/core/local/local_models_and_adapters_test.dart (Hive model and adapter binary conversions)
```

> [!NOTE]
> **Mock vs. Live Verification Distinction:**
> - The passing Flutter unit and widget tests verify client-side logic, mappers, local Hive storage, caching, and UI bindings using mocked dependencies.
> - Full end-to-end cloud persistence requires deployment of the Supabase edge function `sync-civic-rewards` and Firebase rules, which will be validated during Phase 5 live staging verification.

---

## 6. Remaining Limitations & Phase 5 Verification Handoff

### Current State:
1. **Frontend (Flutter):** Fully implemented, lint-clean, and passing all automated test suites for profile synchronization, event history reading, and achievement target display.
2. **Backend Code (TypeScript):** Scope/runtime errors resolved, atomic commit transactions implemented, and action routing separated from reconciliation.
3. **Firestore Rules:** Owner-only read rule on `rewards/{userId}/events/{eventId}` configured with client write prohibitions intact.

### Phase 5 Handoff Checklist:
- [ ] **Deploy Supabase Edge Function:** Deploy `sync-civic-rewards` with Google Service Account credentials.
- [ ] **Deploy Firestore Rules:** Deploy updated `firestore.rules` containing subcollection owner-read access.
- [ ] **Live Staging Verification:** Submit test complaints and verify:
  1. Points appear on `users/{userId}.civicPoints` and `rewards/{userId}` in Firestore.
  2. Reward events appear in `rewards/{userId}/events`.
  3. `ProfileScreen` and `RewardsScreen` display identical points in the running app.
  4. Community Helper unlocks at 10 supported complaints with a single +10 bonus.
