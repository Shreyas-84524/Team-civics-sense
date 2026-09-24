# CivicFix — Supabase Serverless Notification Pipeline Architecture

## 1. Architectural Role & Overview

CivicFix maintains a clear, secure separation of concerns between Firebase (the primary database and identity authority) and Supabase (the serverless compute layer):

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        CIVICFIX CLIENT APPS                            │
│           Citizen Mobile / Web App  &  Government Admin Portal         │
└───────────────────┬────────────────────────────────┬───────────────────┘
                    │                                │
                    │ 1. Primary DB & Auth           │ 2. Async Notification Trigger
                    ▼                                ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│       FIREBASE (Primary Backend)     │  │     SUPABASE EDGE FUNCTIONS   │
│                                      │  │ (Serverless Execution Layer) │
│ • Firebase Authentication (Identity) │  │                              │
│ • Cloud Firestore (Database of Record│  │ • Deno / TypeScript Runtime   │
│ • Firebase Cloud Storage (Evidence)  │  │ • Zero-Billing Serverless    │
│ • Firebase Cloud Messaging (FCM Push)│  │ • RS256 JWT Verification     │
│ • Security Rules & Offline Hive Sync │  │ • Role & Complaint Auth     │
│ • Device Tokens (users/{uid}/devices)│  │ • Atomic FCM Idempotency     │
│ • Notifications (In-App Feed)        │  │ • Stale Token Auto-Pruning   │
└──────────────────────────────────────┘  └──────────────────────────────┘
```

> [!IMPORTANT]
> **Firebase is the Primary System of Record**: All citizen and government profiles, authentication sessions, grievances, timeline updates, in-app notifications, and storage assets reside in Firebase project `civicfix-38d53`.
> **Supabase is the Serverless Execution Layer**: Supabase Edge Functions (`civicfix-serverless`) provide a zero-cost serverless execution environment replacing Cloud Functions that would otherwise require Firebase Blaze billing.

---

## 2. Notification Pipeline Flow & Lifecycle State Machine

```text
Government Officer Updates Status (e.g. IN_PROGRESS -> RESOLVED)
               │
               ▼
[1] Local Cache & UI State Updated Instantly (Hive)
               │
               ▼
[2] Firestore Status & Timeline Event Committed (Cloud Firestore)
               │
               ├─ If Offline ──► Queued in SyncManager ──► Synchronized later
               │
               ▼ (Only AFTER successful Firestore confirmation)
[3] Flutter Triggers Supabase Edge Function (POST /functions/v1/civicfix-notification)
    (Sends Authorization: Bearer <Firebase ID Token> & eventId)
               │
               ▼
[4] Cryptographic Firebase ID Token Verification
    ├─ Fetches Google JWKS (cached with Cache-Control max-age)
    ├─ Verifies RS256 signature via Web Crypto API (crypto.subtle.verify)
    ├─ Validates aud == "civicfix-38d53", iss == "https://securetoken.google.com/civicfix-38d53"
    └─ Checks exp > now and sub == UID (Rejects 401 if invalid/expired)
               │
               ▼
[5] Server-Side Role Authorization Check
    ├─ Evaluates token custom claim (role == 'government' | 'admin')
    └─ Authoritatively queries Firestore users/{uid} & govt_users/{uid}
       (Rejects 403 Forbidden if caller is citizen or unauthorized)
               │
               ▼
[6] Authoritative Complaint Document Validation
    ├─ Queries Firestore complaints/{complaintId}
    ├─ Derives authoritative citizenId and ticketNumber
    └─ (Rejects 404 Not Found if complaint does not exist)
               │
               ▼
[7] Atomic FCM Deduplication & Idempotency Check
    ├─ Checks notifications/{notifDocId}
    ├─ If dispatchStatus == 'DISPATCHED' ──► Returns 200 OK (idempotent: true, skips FCM)
    ├─ If dispatchStatus == 'DISPATCHING' (<30s) ──► Returns 200 OK (inProgress: true)
    └─ Claims dispatchStatus: 'DISPATCHING'
               │
               ▼
[8] FCM HTTP v1 Push Dispatch to Registered Devices
    ├─ Queries users/{citizenId}/devices
    ├─ Dispatches high-priority push notifications
    ├─ Prunes invalid/unregistered tokens (UNREGISTERED, 404, 410)
    └─ Finalizes notifications/{notifDocId} as 'DISPATCHED' (or 'FAILED' on retryable error)
               │
               ▼
[9] Citizen Receives Real-Time Push Notification on Device
```

---

## 3. Supabase Project Infrastructure

* **Project Name**: `civicfix-serverless`
* **Project Reference ID**: `hkgwsqasmboadvpjckbj`
* **Region**: `ap-south-1` (Mumbai, India)
* **Organization**: Team Civic Sense (`ktnywfbhkqswnbwswstb`)
* **Project URL**: `https://hkgwsqasmboadvpjckbj.supabase.co`
* **Plan**: Free Tier (Active / Healthy)

---

## 4. Deployed Edge Function Specifications

### `civicfix-notification`

* **Status**: `ACTIVE` (Version 3)
* **Endpoint**: `POST https://hkgwsqasmboadvpjckbj.supabase.co/functions/v1/civicfix-notification`
* **Runtime**: Deno / TypeScript (Supabase Edge Runtime)
* **JWT Verification Mode**: `verify_jwt: false` (Supabase layer) with **Custom Cryptographic Firebase ID Token & Role Verification** (Function layer)
* **Source Code**: [`supabase/functions/civicfix-notification/index.ts`](../../supabase/functions/civicfix-notification/index.ts)

#### Request Contract

```http
POST /functions/v1/civicfix-notification HTTP/1.1
Host: hkgwsqasmboadvpjckbj.supabase.co
Authorization: Bearer <firebase_auth_id_token>
Content-Type: application/json

{
  "complaintId": "CF-2026-000024",
  "citizenId": "usr_citizen_firebase_001",
  "oldStatus": "assigned",
  "newStatus": "inProgress",
  "ticketNumber": "CF-2026-000024",
  "title": "Broken street light near park",
  "departmentName": "Electrical Department",
  "officerNotes": "Ground crew dispatched to replace capacitor.",
  "eventId": "evt_cmp_101_inProgress_1790212000000"
}
```

#### Field Specifications

| Field | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `complaintId` | `string` | **Yes** | Unique grievance ticket identifier or Firestore document ID. |
| `citizenId` | `string` | **Yes** | The Firebase Auth `UID` of the reporting citizen. |
| `oldStatus` | `string` | **Yes** | Previous lifecycle status (e.g. `assigned`, `reported`). |
| `newStatus` | `string` | **Yes** | Target lifecycle status (e.g. `inProgress`, `resolved`). |
| `ticketNumber` | `string` | No | Human-readable ticket number (e.g. `CF-2026-000024`). |
| `title` | `string` | No | Complaint title for push notification body generation. |
| `departmentName`| `string` | No | Name of the assigned municipal department. |
| `officerNotes` | `string` | No | Official audit notes or resolution comments. |
| `eventId` | `string` | No | Deterministic idempotency key for deduplicating retries. |

#### Response Formats

**Success with Device Dispatch (`200 OK`)**:
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Notification dispatched",
  "data": {
    "complaintId": "CF-2026-000024",
    "newStatus": "inProgress",
    "devicesAttempted": 2,
    "devicesSucceeded": 2
  }
}
```

**Idempotency Cache Hit (`200 OK`)**:
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Notification already dispatched (idempotent hit)",
  "data": {
    "complaintId": "CF-2026-000024",
    "newStatus": "inProgress",
    "idempotent": true,
    "devicesAttempted": 2,
    "devicesSucceeded": 2
  }
}
```

**No Registered Devices (`200 OK`)**:
```json
{
  "success": true,
  "statusCode": 200,
  "message": "No registered device",
  "data": {
    "complaintId": "CF-2026-000024",
    "newStatus": "resolved",
    "devicesAttempted": 0,
    "devicesSucceeded": 0
  }
}
```

**Validation Error (`422 Unprocessable Entity`)**:
```json
{
  "success": false,
  "statusCode": 422,
  "error": "Unprocessable Entity",
  "message": "Missing required field(s): oldStatus.",
  "expectedPayload": {
    "complaintId": "string (e.g. CF-2026-000024 or cmp_101)",
    "citizenId": "string (Firebase user UID)",
    "oldStatus": "string (e.g. Assigned)",
    "newStatus": "string (e.g. In Progress)"
  }
}
```

**Unauthorized (`401 Unauthorized`)**:
```json
{
  "success": false,
  "statusCode": 401,
  "error": "Unauthorized",
  "message": "Authentication failed: Cryptographic signature verification failed."
}
```

**Forbidden (`403 Forbidden`)**:
```json
{
  "success": false,
  "statusCode": 403,
  "error": "Forbidden",
  "message": "Access denied. Caller is not an authorized CivicFix government or admin account."
}
```

---

## 5. Security & Secrets Management

### Secret Configuration

* **Secret Name**: `FIREBASE_SERVICE_ACCOUNT_KEY`
* **Storage Location**: Supabase Production Environment Secrets (Dashboard or CLI `supabase secrets set`).
* **Content**: The complete JSON string of the Firebase Service Account private key downloaded from the Firebase Console (Project Settings $\rightarrow$ Service accounts).

> [!CAUTION]
> **Strict Secret Isolation**:
> 1. Never commit the service account JSON or private keys to Git.
> 2. Never bundle service account credentials inside the Flutter client application.
> 3. The Edge Function only parses this secret in server memory to generate ephemeral (1-hour) OAuth 2.0 access tokens.
> 4. Server-side logs NEVER output private keys, credentials, or full raw tokens.

---

## 6. Failure & Resilience Model

1. **Firestore Status Updates are Independent & Authoritative**:
   - The primary Firestore complaint update and timeline record are committed **before** calling the notification service.
   - If the Supabase Edge Function is unreachable, times out, or returns an HTTP error, the Firestore status update is **never rolled back**.
2. **Offline-First Synchronization**:
   - When an officer updates status while offline, the action is stored in the local Hive cache and enqueued in `SyncManager`.
   - The Supabase notification trigger is deferred until `FirebaseSyncProvider` successfully synchronizes the update to Cloud Firestore.
3. **Idempotency & Deduplication**:
   - Each notification event generates an `eventId` derived from `complaintId + newStatus + timestamp/syncId`.
   - In-app notification documents are tracked atomically via document ID `notif_${complaintId}_${newStatus}_${eventId}` with lifecycle states (`DISPATCHING`, `DISPATCHED`, `FAILED`).
   - Re-syncing or duplicate requests immediately hit the idempotency check and skip FCM dispatch.
4. **Multi-Device & Stale Token Pruning**:
   - Push notifications are delivered to all registered citizen device tokens.
   - If FCM returns `UNREGISTERED`, `INVALID_ARGUMENT`, or HTTP `404`/`410`, the stale device document is automatically pruned from `users/{citizenId}/devices`.
