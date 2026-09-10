# CivicFix — Cloud Firestore Remote Data Sources & Repository Layer

> **Version**: 1.0  
> **Status**: Prompt 3 Complete  
> **Target Project**: `civicfix-38d53` (CivicFix)

---

## 1. Remote Data-Source Architecture

The Remote Data Source layer acts as the bridge between CivicFix's domain model and Cloud Firestore. It is designed to be completely decoupled from the UI and from authentication implementations:

```text
Domain / UI Layer
       ↓
Abstract Repositories (ComplaintRepository, UserRepository, etc.)
  ├── Hive Local Repositories (Local Cache & Offline Drafts)
  └── Firebase Remote Repositories (Cloud Firestore Backend)
            ↓
     Remote Data Sources (FirebaseComplaintDataSource, etc.)
            ↓
     Firestore Mappers & Error Handlers
            ↓
       Cloud Firestore
```

---

## 2. Collection Mapping

| Domain Entity | Firestore Collection | Document ID Strategy | Subcollections |
| :--- | :--- | :--- | :--- |
| `ComplaintModel` | `complaints` | Auto-generated Firestore ID or domain `id` | `updates/{updateId}` (Timeline events) |
| `UserModel` | `users` | Auth UID (`request.auth.uid`) | — |
| `GovtUserModel` | `users` | Auth UID (`request.auth.uid`) | — |
| `NotificationModel` | `notifications` | Auto-generated Firestore ID | — |
| `RewardDataModel` | `rewards` | User ID (`userId`) | — |
| `HazardModel` | `hazards` | Auto-generated Firestore ID | — |
| `GovtDepartmentModel` | `departments` | Unique Department Code/ID (e.g. `dept_roads`) | — |

---

## 3. Domain ↔ Firestore Mapping Strategy

Each domain entity has a dedicated, tested bidirectional mapper in `lib/core/firebase/mappers/`:
* **`ComplaintFirestoreMapper`**: Converts `ComplaintModel` & `TimelineEvent` to/from Firestore documents.
* **`UserFirestoreMapper`**: Handles citizen `UserModel` and government officer `GovtUserModel` mapping.
* **`NotificationFirestoreMapper`**: Maps `NotificationModel` with enum serialization.
* **`HazardFirestoreMapper`**: Maps `HazardModel` ensuring complete omission of citizen PII (email, phone, name).
* **`RewardFirestoreMapper`**: Maps `RewardDataModel`, `CivicAchievement`, and `CivicRewardItem`.
* **`DepartmentFirestoreMapper`**: Maps `GovtDepartmentModel` and `GovtOfficerModel`.

---

## 4. Enum Serialization Strategy

Enums are mapped to standardized string values with safe fallback handling on unexpected inputs:

* **`ComplaintStatus`**: `reported` (default), `verified`, `assigned`, `inProgress`, `resolved`, `rejected`. Backwards-compatible with legacy aliases (`submitted` -> `reported`, `underReview` -> `verified`).
* **`ComplaintPriority`**: `low`, `medium` (default), `high`, `emergency`.
* **`HazardSeverity`**: `low`, `medium` (default), `high`, `critical`.
* **`NotificationType`**: `complaintSubmitted`, `complaintVerified`, `complaintAssigned`, `complaintStatusChanged`, `complaintResolved`, `generalCivic` (default), `hazardAlert`, `rewardEarned`.
* **`SyncStatus`**: Kept strictly **local** in Hive. Never serialized as authoritative Firestore workflow state.

---

## 5. Location & Timestamp Strategies

* **Location**: Serialized as a structured map `{ latitude: number, longitude: number, address: string, landmark?: string, ward?: string, city?: string }`.
* **Timestamps**:
  * Creation: Uses `FieldValue.serverTimestamp()` for authoritative server-side recording.
  * Retrieval: Handles `Timestamp`, ISO8601 strings, or epoch milliseconds into Dart `DateTime` safely.

---

## 6. Cursor-Based Pagination Strategy

To prevent uncontrolled bandwidth and document read consumption on list queries:
* `FirestorePage<T>` encapsulates `List<T>`, `bool hasMore`, and `DocumentSnapshot? lastDocument`.
* Data sources accept `int limit` and `DocumentSnapshot? startAfter` without leaking Firestore types into UI code.

---

## 7. Error Handling

Centralized in `FirestoreErrorHandler`:
* `permission-denied` → `FirestorePermissionDeniedException`
* `not-found` → `FirestoreNotFoundException`
* `unavailable` / `network-request-failed` → `FirestoreUnavailableException`
* `already-exists` → `FirestoreAlreadyExistsException`
* `deadline-exceeded` → `FirestoreTimeoutException`

Raw Firebase exception strings are never exposed directly to end-user UI.

---

## 8. Intentionally NOT Implemented Yet

1. **Firebase Authentication**: `FirebaseAuthService`, login/register flows, and live token listeners belong to future prompts.
2. **Firebase Storage**: Photographic evidence uploads belong to Prompt 4.
3. **FCM & Cloud Functions**: Push alerts and backend triggers belong to future prompts.
4. **`FirebaseSyncProvider` / `SyncManager` Connection**: The offline-to-online reconciliation pipeline will be wired in Prompt 5.
