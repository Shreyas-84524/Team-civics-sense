# CivicFix — Cloud Firestore Architecture & Security Specification

> **Version**: 1.0  
> **Status**: Approved Foundation  
> **Target Project**: `civicfix-38d53` (CivicFix)  
> **Architecture Principle**: Cloud Firestore serves as the authoritative remote backend, while Hive remains the offline persistence and local caching layer.

---

## 1. System Overview

CivicFix uses Cloud Firestore as its primary cloud document database. The cloud data layer is designed around an **offline-first, least-privilege, role-isolated** architecture:

```text
UI (Citizen Mobile / Government Web)
  ↓
Repositories (e.g. ComplaintRepository)
  ├── Local Data Source: Hive (Instant read/write cache & offline drafts)
  └── Remote Data Source: Cloud Firestore (Authoritative cloud source of truth)
            ↓
       SyncManager (Mutex-locked offline retry engine)
            ↓
     FirebaseSyncProvider (Executes Firestore batch writes & Storage uploads)
```

---

## 2. Firestore Collections & Schema Definitions

### 2.1 Collection: `users` (`users/{userId}`)

Stores profile metadata for both citizens and municipal officers. Document ID matches Firebase Auth UID (`userId == request.auth.uid`).

```json
{
  "fullName": "Rahul Sharma",
  "email": "citizen@civicfix.test",
  "phone": "+91 98765 43210",
  "avatarUrl": "https://firebasestorage.googleapis.com/.../avatar.jpg",
  "civicPoints": 480,
  "reportsSubmitted": 8,
  "reportsResolved": 6,
  "badges": ["First Report", "Civic Contributor"],
  "languageCode": "en",
  "wardNumber": "Ward 14 (Central Ward)",
  "role": "citizen",
  "createdAt": "2026-09-08T10:00:00Z",
  "updatedAt": "2026-09-08T12:00:00Z",

  // Government-specific fields (only present when role == 'government'):
  "employeeId": "MC-2026-ENG-842",
  "departmentId": "dept_roads",
  "departmentName": "Roads & Infrastructure",
  "designation": "Senior Municipal Nodal Officer",
  "assignedWard": "Ward 14 (Central Zone)",
  "permissions": ["view_complaints", "update_status", "assign_officer"],
  "organization": "Municipal Civic Administration"
}
```

* **Role Isolation**: The `role` field cannot be self-escalated by clients.
* **Server-Authoritative Counters**: `civicPoints`, `reportsSubmitted`, `reportsResolved`, and `badges` cannot be modified by citizen clients.

---

### 2.2 Collection: `complaints` (`complaints/{complaintId}`)

Primary collection storing civic grievance tickets filed by citizens and managed by municipal departments.

```json
{
  "citizenId": "user_citizen_001",
  "ticketNumber": "CF-2026-000024",
  "title": "Broken street light near park",
  "description": "The pole streetlight opposite the children play area has been dark for 3 days.",
  "category": {
    "id": "cat_electrical",
    "name": "Street Lights",
    "description": "Streetlight outages, exposed wiring, and electrical hazards."
  },
  "status": "reported",
  "priority": "medium",
  "location": {
    "latitude": 12.9716,
    "longitude": 77.5946,
    "address": "4th Cross Road",
    "landmark": "Near Children Park",
    "ward": "Ward 14",
    "city": "Bengaluru"
  },
  "imageUrls": [
    "https://firebasestorage.googleapis.com/.../photo_1.jpg"
  ],
  "upvotes": 4,
  "isHazard": false,
  "assignedTo": "off_105",
  "departmentId": "dept_electrical",
  "departmentName": "Electrical / Public Works",
  "officerNotes": "Technician dispatched to inspect transformer feed.",
  "createdAt": "2026-09-08T10:30:00Z",
  "updatedAt": "2026-09-08T11:15:00Z",
  "resolvedAt": null
}
```

* **Status Values**: `reported`, `verified`, `assigned`, `inProgress`, `resolved`, `rejected`.
* **Priority Values**: `low`, `medium`, `high`, `emergency`.

---

### 2.3 Subcollection: `complaints/{complaintId}/updates/{updateId}`

Immutable audit trail recording each state change and administrative note for a complaint.

```json
{
  "title": "Status Updated to In Progress",
  "description": "Repair crew has begun road resurfacing.",
  "timestamp": "2026-09-08T11:30:00Z",
  "status": "inProgress",
  "updatedBy": "govt_off_001",
  "createdAt": "2026-09-08T11:30:00Z"
}
```

* **Immutability**: Updates cannot be modified or deleted once appended.
* **Integrity**: Citizens can only write the initial `reported` entry; only verified government personnel can write subsequent workflow updates.

---

### 2.4 Collection: `departments` (`departments/{departmentId}`)

Directory of municipal departments responsible for resolving specific issue categories.

```json
{
  "id": "dept_roads",
  "name": "Roads Department",
  "code": "PWD-RD",
  "description": "Pothole repairs, asphalt resurfacing, and pavement maintenance.",
  "activeComplaintsCount": 8,
  "assignedPersonnelCount": 14,
  "organizationId": "org_municipal_corp",
  "active": true,
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-09-08T00:00:00Z"
}
```

* **Access**: Authenticated read; write access restricted to system administration.

---

### 2.5 Collection: `notifications` (`notifications/{notificationId}`)

Citizen-facing notifications delivering real-time lifecycle alerts and broadcasts.

```json
{
  "userId": "user_citizen_001",
  "title": "Complaint Verified",
  "message": "Your report CF-2026-000024 has been verified by the municipal office.",
  "type": "complaintVerified",
  "complaintId": "cmp_101",
  "isRead": false,
  "createdAt": "2026-09-08T11:00:00Z"
}
```

* **User Privacy**: Citizens can only query and read their own `userId` notifications.
* **Mutation**: Clients can only toggle the `isRead` boolean field.

---

### 2.6 Collection: `rewards` (`rewards/{userId}`)

Server-authoritative citizen gamification, civic badges, and unlocked perks.

```json
{
  "userId": "user_citizen_001",
  "points": 480,
  "reportsSubmitted": 8,
  "reportsResolved": 6,
  "achievements": [
    {
      "id": "ach_1",
      "title": "First Report",
      "unlockedAt": "2026-09-01T10:00:00Z"
    }
  ],
  "updatedAt": "2026-09-08T11:30:00Z"
}
```

* **Security**: Client read-only. Points cannot be awarded by client-side writes.

---

### 2.7 Collection: `hazards` (`hazards/{hazardId}`)

Geotagged community safety hazards displayed on the Live Hazard Map.

```json
{
  "complaintId": "cmp_102",
  "ticketNumber": "CF-2026-000021",
  "title": "Road damage near junction",
  "category": {
    "id": "cat_roads",
    "name": "Roads & Potholes"
  },
  "status": "inProgress",
  "latitude": 12.9720,
  "longitude": 77.5950,
  "address": "Main Junction, Central Ward",
  "landmark": "Near Signal 4",
  "ward": "Ward 14",
  "severity": "high",
  "imageUrl": "https://firebasestorage.googleapis.com/.../hazard.jpg",
  "upvotes": 12,
  "createdAt": "2026-09-08T09:00:00Z",
  "updatedAt": "2026-09-08T11:00:00Z"
}
```

* **PII Protection**: Hazard documents intentionally exclude citizen identity (name, email, phone) to ensure privacy while rendering public markers.
* **Severity Values**: `low`, `medium`, `high`, `critical`.

---

## 3. Location & Timestamp Strategies

### 3.1 Geographic Location Representation
* Stored as a structured nested map (`latitude`, `longitude`, `address`, `landmark`, `ward`, `city`).
* **Rationale**: Maintains 100% semantic compatibility with Flutter domain models (`CivicLocation`), Hive offline local adapters (`LocationLocalModel`), and enables direct conversion to Firestore `GeoPoint` when geospatial queries are activated.

### 3.2 Timestamps
* All creation and update operations in cloud requests utilize server timestamps (`FieldValue.serverTimestamp()`) or ISO8601 millisecond-precision timestamps.
* Client-supplied timestamps for audit fields are rejected by Firestore security rules.

---

## 4. Role & Ownership Model

| Role | Creation Rules | Read Permissions | Update Permissions |
| :--- | :--- | :--- | :--- |
| **Citizen** | Self-registered via Auth; starts with `role: 'citizen'`, 0/20 pts | Own profile, own complaints, own notifications, own rewards, public hazards & departments | Profile info (`name`, `phone`, `avatar`, `ward`, `language`), upvotes on complaints/hazards |
| **Government** | Provisioned via administrative claim (`role: 'government'`) | All complaints, officer profiles, departments, hazard map, analytics | Workflow fields (`status`, `priority`, `assignedTo`, `departmentId`, `officerNotes`, `resolvedAt`), timeline updates |

---

## 5. Security Rules Verification Matrix

| Scenario | Tested Rule Assertion | Status |
| :--- | :--- | :--- |
| Unauthenticated Read/Write | `request.auth != null` | **BLOCKED** |
| Citizen A reading Citizen B's private complaint | `resource.data.citizenId == request.auth.uid` | **BLOCKED** |
| Citizen elevating `role: citizen → government` | `!affectedKeys().hasAny(['role', ...])` | **BLOCKED** |
| Citizen changing status (`reported → resolved`) | `!affectedKeys().hasAny(['status', ...])` | **BLOCKED** |
| Citizen assigning complaint to officer | `!affectedKeys().hasAny(['assignedTo', ...])` | **BLOCKED** |
| Citizen modifying another user's notifications | `resource.data.userId == request.auth.uid` | **BLOCKED** |
| Citizen modifying authoritative reward points | `allow write: if false` on `rewards/{userId}` | **BLOCKED** |
| Citizen writing department configurations | `allow write: if false` on `departments/{id}` | **BLOCKED** |
| Government officer updating status & timeline | `isGovernment()` check | **ALLOWED** |
| Citizen filing new complaint with `status: reported` | `citizenId == auth.uid && status == 'reported'` | **ALLOWED** |

---

## 6. Composite Indexes Configuration

Configured in [`firestore.indexes.json`](file:///c:/Learning%20some%20new%20stuf/SPP/Team-civics-sense/civic_app/firestore.indexes.json):
1. **`complaints`**: `citizenId ASC` + `createdAt DESC` (Citizen complaints feed)
2. **`complaints`**: `departmentId ASC` + `status ASC` + `createdAt DESC` (Department queue triage)
3. **`complaints`**: `status ASC` + `createdAt DESC` (Status-filtered lists)
4. **`complaints`**: `isHazard ASC` + `createdAt DESC` (Live hazards filter)
5. **`notifications`**: `userId ASC` + `createdAt DESC` (Citizen notifications feed)
6. **`notifications`**: `userId ASC` + `isRead ASC` + `createdAt DESC` (Unread badge counts)
7. **`hazards`**: `status ASC` + `createdAt DESC` (Live hazard markers)
8. **`hazards`**: `severity ASC` + `createdAt DESC` (Critical safety filter)

---

## 7. Firebase Local Emulator Suite

Emulator ports configured in [`firebase.json`](file:///c:/Learning%20some%20new%20stuf/SPP/Team-civics-sense/civic_app/firebase.json):
* **Firestore Emulator**: `localhost:8080`
* **Auth Emulator**: `localhost:9099`
* **Storage Emulator**: `localhost:9199`
* **Emulator UI**: `localhost:4000`

### Starting the Emulator Suite:
```bash
firebase emulators:start
```
