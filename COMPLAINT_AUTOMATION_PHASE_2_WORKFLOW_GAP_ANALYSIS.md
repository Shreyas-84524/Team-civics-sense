# COMPLAINT AUTOMATION REBUILD — PHASE 2 WORKFLOW GAP ANALYSIS
**CivicFix Municipal Grievance & AI Automation Platform**  
**Audit Date:** October 2, 2026 | **Environment:** `civicfix-38d53` (Clean Baseline)

---

## 1. Executive Summary
This diagnostic audit provides a comprehensive, evidence-backed evaluation of the existing CivicFix codebase against the newly specified **Canonical 7-Stage Complaint Lifecycle**.

### Core Audit Verdict:
- **Foundational Municipal Routing & Ground Execution (Stages 4, 5, 6, 7-Reopen):** The 24-Ward Haversine centroid resolution, workload-balanced Junior Engineer routing, JE-to-Field Execution Officer dispatching, on-site resolution evidence capture, and Ward Department Lead quality rework loops are **robust and operational**.
- **Major Architectural Defect:** The existing system **completely bypasses the AI verification gate during ingestion**. Grievances transition immediately from `reported` to `assigned` (Junior Engineer assigned) without waiting for Gemini visual authenticity or Grok department validation.
- **Grok AI Integration:** Currently **MISSING (0% implemented)** across models, services, prompts, and UI.
- **Gemini AI Integration:** Implemented client-side via `firebase_ai` for authenticity checking, but invoked solely as a non-blocking background side-effect on offline sync queue draining, never gating ingestion.
- **Lifecycle Model Gaps:** The state enum lacks explicit `underVerification` and `closed` states.

---

## 2. Current End-to-End Complaint Sequence
Based on direct code inspection of `ReportIssueScreen`, `OfflineFirstComplaintRepository`, and `ComplaintRoutingService`:

```
Citizen Fills Form & Attaches Photo
         ↓
ReportIssueScreen.submitComplaint()
         ↓
OfflineFirstComplaintRepository.createComplaint()
         ↓
[Online Path]
   1. Upload local media to Storage
   2. Firestore.collection('complaints').create(initialComplaint) [status: reported]
   3. ComplaintRoutingService.autoRouteComplaint(created)  <-- CRITICAL DEFECT: IMMEDIATE AUTO-ROUTING
         ↓
   4. Resolves Ward via Haversine centroid (e.g., R_NORTH)
   5. Resolves Department via category mapping (e.g., maintenance_roads)
   6. Selects least-loaded Junior Engineer (department_crew)
   7. Mutates status -> 'assigned', assignmentStatus -> 'crewAssigned'
   8. Caches 'assigned' complaint in local Hive box
         ↓
   * Note: Gemini is NEVER called in online creation. Grok does NOT exist.
   * Note: Firestore document remains 'reported' because citizen token cannot write govt assignment fields.
```

---

## 3. Canonical Required Sequence

```
Stage 1: Citizen Submission
   ↳ Creates complaint with status: UNDER_VERIFICATION
         ↓
Stage 2: Gemini Verification (Step 1 of 2)
   ↳ Multimodal Vision: Authenticity, Real Civic Issue, Non-Synthetic Evidence
   ↳ Citizen UI: "Step 1 of 2: Gemini Verification — In Progress / Passed"
   ↳ Status REMAINS: UNDER_VERIFICATION (Must NOT be assigned yet)
         ↓ [PASS]
Stage 3: Grok Department Verification (Step 2 of 2)
   ↳ Problem Type Classification & BMC Department Validation
   ↳ Confirms or overrides selected category -> Verified Department + Verified Complaint
   ↳ Citizen UI: "Step 2 of 2: Grok Department Verification — Passed"
   ↳ Status REMAINS: UNDER_VERIFICATION until both AI checks succeed
         ↓ [PASS]
Stage 4: Automated Ward + Junior Engineer Routing
   ↳ GPS Location -> BMC Ward (1 of 24)
   ↳ Verified Department (1 of 18)
   ↳ Least-loaded Junior Engineer (department_crew) auto-assigned
   ↳ Status BECOMES: ASSIGNED (Citizen sees Dept, Ward, JE Name + Designation)
         ↓
Stage 5: Junior Engineer → Execution Officer Dispatch
   ↳ JE assigns distinct Execution Officer (department_crew, JE != EO)
   ↳ Status BECOMES: WORK IN PROGRESS
   ↳ Citizen sees JE + Execution Officer snapshots
         ↓
Stage 6: Execution Officer Resolution
   ↳ Field physical execution -> Mandatory After Photo + Remarks + Timestamp
   ↳ Status BECOMES: RESOLVED (Citizen sees Before/After photos + remarks)
         ↓
Stage 7: Ticket Closure + Departmental Officer Reopen
   ↳ Automatic or Admin final transition -> CLOSED
   ↳ Departmental Officer (ward_department_lead) Quality Audit:
        ↳ If defective -> Status: REOPENED / IN PROGRESS (reopenCount++, SLA preserved)
```

---

## 4. Stage 1 Findings: Citizen Submission
- **Required:** Citizen submits grievance; initial state is `UNDER VERIFICATION`.
- **Current Implementation:** `ReportIssueScreen` collects title, description, category, GPS location, and up to 3 photos. Initial status is created as `ComplaintStatus.reported`.
- **Status:** `PARTIAL`
- **Gaps:** `ComplaintStatus.underVerification` does not exist in the enum or Firestore security rules.

---

## 5. Stage 2 Findings: Gemini Verification
- **Required:** Gemini verifies evidence authenticity and civic validity; complaint remains `UNDER VERIFICATION`.
- **Current Implementation:**
  - `GeminiAiAuthenticityService` (`lib/core/ai/gemini_ai_authenticity_service.dart`) utilizes `firebase_ai` (`gemini-2.5-flash`) with structured JSON schema (`authenticityResponseSchema`).
  - `GeminiAiDetectionService` (`lib/core/ai/gemini_ai_detection_service.dart`) implements category matching and hazard severity detection.
- **Critical Flaw:** Gemini is **never invoked** in `OfflineFirstComplaintRepository.createComplaint()` or `FirebaseComplaintRepository.createComplaint()`. It is only referenced in `FirebaseSyncProvider` during offline queue background sync (`// 5b. Run AI Authenticity Verification on local evidence (isolated, never fails complaint)`).
- **Status:** `INCORRECT / BYPASSED`

---

## 6. Stage 3 Findings: Grok Department Verification
- **Required:** Grok AI verifies problem type and responsible BMC department; gates routing.
- **Current Implementation:** Completely absent from the codebase. No xAI/Grok client, API service, prompt templates, department normalization mapping, or verification gates exist.
- **Status:** `MISSING`

---

## 7. Stage 4 Findings: Automated Ward + JE Routing
- **Required:** Automatically routes to Ward + JE only after Gemini & Grok pass; status becomes `ASSIGNED`.
- **Current Implementation:**
  - `ComplaintRoutingService.autoRouteComplaint()` accurately resolves the 24 BMC Wards and selects the least-loaded Junior Engineer.
  - Immutably establishes `slaStartedAt` and logs `auto_routed_to_junior_engineer`.
- **Flaw:** Executes immediately upon complaint creation, completely bypassing Stages 2 and 3.
- **Status:** `INCORRECT ORDER` (Logic complete, sequencing wrong).

---

## 8. Stage 5 Findings: Junior Engineer → Execution Officer Dispatch
- **Required:** JE assigns distinct Execution Officer; status becomes `WORK IN PROGRESS`.
- **Current Implementation:**
  - `ComplaintRoutingService.assignFieldOfficer()` strictly validates that `juniorEngineerId != fieldOfficerId`.
  - Captures immutable snapshots: `assignedFieldOfficerNameSnapshot`, `assignedFieldOfficerDesignationSnapshot`.
  - **Semantic Difference:** Status currently remains `assigned` (`assignmentStatus = fieldOfficerAssigned`), and requires the Field Officer to tap "Start Work" (`startFieldWork()`) before status becomes `inProgress`.
- **Status:** `COMPLETE (SEMANTIC DIFFERENCE NOTED)`

---

## 9. Stage 6 Findings: Execution Officer Resolution
- **Required:** Execution Officer submits completion photo, remarks, timestamp; status becomes `RESOLVED`.
- **Current Implementation:**
  - `ComplaintRoutingService.resolveByFieldOfficer()` requires mandatory `afterPhotoUrl` and `resolutionRemarks`.
  - Directly transitions status to `ComplaintStatus.resolved`.
  - Citizen UI displays side-by-side Before/After photos and resolution remarks.
- **Status:** `COMPLETE`

---

## 10. Stage 7 Findings: Ticket Closure + Departmental Officer Reopen
- **Required:** Ticket transitions to `CLOSED`. Departmental Officer has supervisory quality audit and reopen authority.
- **Current Implementation:**
  - `ComplaintRoutingService.reopenComplaint()` allows `ward_department_lead` (Executive Engineer), `ward_officer`, and `central_department_hod` to reopen resolved grievances with mandatory `reopenReason`.
  - Preserves previous evidence in `previousResolutionEvidence`, increments `reopenCount`, preserves immutable `slaStartedAt`, and routes back to `inProgress`.
  - **Missing Feature:** `ComplaintStatus.closed` does not exist.
- **Status:** `PARTIAL`

---

## 11. Status Model Findings

### Supported Status Enums (`ComplaintStatus`):
| Status Enum | Current UI Label | Canonical Role |
|---|---|---|
| `reported` | Reported | Stage 1 (needs migration to `underVerification`) |
| `verified` | Verified | Legacy human triage marker |
| `assigned` | Assigned | Stage 4 (JE Assigned) |
| `inProgress`| In Progress | Stage 5 (Work Underway) |
| `resolved` | Resolved | Stage 6 (Field Work Resolved) |
| `rejected` | Rejected | Administrative closure |

### Missing Lifecycle States:
- `underVerification`: Required for Stages 1, 2, and 3 while AI pipelines run.
- `closed`: Required for Stage 7 final lifecycle closure.

---

## 12. Citizen UI Findings
- **Progress Tracker (`ComplaintTracker`):** Renders a fixed 5-stage stepper (`Reported` $\to$ `Verified` $\to$ `Assigned` $\to$ `In Progress` $\to$ `Resolved`).
- **Missing AI Progress Indicators:** Does not have sub-steps for `Step 1: Gemini Verification` and `Step 2: Grok Department Verification`.
- **Officer Transparency (`OfficersHandlingCard`):** Fully implemented. Dynamically renders Junior Engineer and Execution Officer cards with designation snapshots without leaking officer PII.

---

## 13. Notification Audit Findings

| Lifecycle Event | In-App / FCM Notification Status |
|---|---|
| Complaint Submitted | Missing explicit notification |
| Gemini Verified (Stage 2) | **Missing** |
| Grok Department Verified (Stage 3) | **Missing** |
| JE Assigned (Stage 4) | Implemented (`complaintAssigned` in Cloud Functions) |
| Execution Officer Assigned (Stage 5) | Missing distinct alert (grouped with assignment) |
| Work Started (Stage 5) | Implemented (`complaintStatusChanged`) |
| Work Resolved (Stage 6) | Implemented (`complaintResolved`) |
| Ticket Closed (Stage 7) | **Missing** |
| Complaint Reopened (Stage 7) | Generic status changed; missing dedicated rework alert |

---

## 14. Offline Behavior Findings
- **Local Persistence:** Uses Hive (`HiveComplaintRepository`, `HiveBoxes.complaints`).
- **Current Offline Risk:** If an offline complaint is saved, `autoRouteComplaint` runs locally in Hive, prematurely assigning the complaint to a JE in local cache before it has ever touched the server or AI verification.
- **Requirement for Phase 3:** Offline drafts must be saved with `syncStatus: pending` and `status: underVerification`. Auto-routing must be deferred until network connectivity is established and server AI verification passes.

---

## 15. Firestore Trust-Boundary Findings
- **Security Rules (`firestore.rules`):**
  - Citizens can only `create` with `status: 'reported'`, `assignedTo: null`, `departmentId: null`.
  - Citizens cannot mutate government assignment fields (`isGovernment()` guard).
- **Architectural Conflict:** The Flutter client currently tries to run `autoRouteComplaint()` immediately after `createComplaint()`. Since the client is authenticated as a citizen, direct Firestore updates to assignment fields fail under security rules.
- **Resolution for Phase 3:** AI verification and automated JE assignment must run on a **trusted backend** (Cloud Functions or Supabase Edge Functions with Service Account / Admin privileges).

---

## 16. AI API Security Findings
- **Gemini API:** Currently uses `firebase_ai` via Firebase project credentials.
- **Grok API:** Requires an `xAI API Key`.
- **Security Requirement:** Grok API keys must **never be embedded in Flutter client `.env` or client APKs**. Grok calls must be executed securely within trusted Cloud Functions or Supabase Edge Functions.

---

## 17. Ward Geofencing Assessment
- **Current Method:** `ComplaintRoutingService.resolveWardForLocation()` uses Great-Circle Haversine distance to the nearest of 24 BMC Ward administrative centroid coordinates.
- **Assessment:** **ACCEPTABLE WITH LIMITATIONS**.
  - Centroid approximation works well for central locations but can produce boundary classification errors along irregular ward boundaries (railway lines, creeks).
  - Fallback to `G_NORTH` occurs when GPS is missing or (0,0).
  - Recommendation: Maintain Haversine as an instant fallback, but introduce GeoJSON polygon point-in-polygon lookup for high-accuracy production municipal routing.

---

## 18. Current vs. Required Matrix

| Stage | Canonical Requirement | Current Implementation | Status | Files Involved | Key Gap |
|---|---|---|---|---|---|
| **Stage 1** | Citizen Submission $\to$ `underVerification` | Submits to Firestore as `reported` | `PARTIAL` | `report_issue_screen.dart`<br>`offline_first_complaint_repository.dart` | Status is `reported` instead of `underVerification`. |
| **Stage 2** | Gemini Visual Verification | Client service exists; bypassed in ingestion | `INCORRECT` | `gemini_ai_authenticity_service.dart`<br>`firebase_sync_provider.dart` | Never called during online grievance creation; does not gate routing. |
| **Stage 3** | Grok Department Verification | Not implemented | `MISSING` | (None) | Zero Grok integration or department validation logic. |
| **Stage 4** | Automated Ward + JE Routing | Fully functional load balancing & Ward resolution | `INCORRECT ORDER` | `complaint_routing_service.dart` | Runs immediately on ingestion before Stages 2 & 3. |
| **Stage 5** | JE $\to$ Execution Officer Dispatch | Distinct JE/FO dispatch with immutable snapshots | `COMPLETE*` | `complaint_routing_service.dart`<br>`officers_handling_card.dart` | *Status remains `assigned` until physical "Start Work" button tap. |
| **Stage 6** | Execution Officer Resolution | Mandatory After Photo + remarks $\to$ `resolved` | `COMPLETE` | `complaint_routing_service.dart`<br>`govt_complaint_details_screen.dart` | Meets 100% of canonical requirements. |
| **Stage 7** | Closed + Lead Reopen | Quality rework loop complete; `closed` state missing | `PARTIAL` | `complaint_routing_service.dart`<br>`complaint_model.dart` | `ComplaintStatus.closed` does not exist in schema/rules. |

---

## 19. What is Already Reusable
1. **Ward Detection & Routing Engine:** `ComplaintRoutingService.resolveWardForLocation` & `selectLeastLoadedJuniorEngineer`.
2. **Hierarchy Repository:** 3,699 government users, 24 Wards, 18 Departments across Mumbai.
3. **Execution Officer Dispatch & Resolution:** Full ground execution workflow, `assignFieldOfficer`, `startFieldWork`, `resolveByFieldOfficer`.
4. **Supervisory Quality Rework:** `reopenComplaint` with SLA preservation, historical photo archiving, and reopen counter.
5. **Citizen Transparency UI:** `OfficersHandlingCard` and snapshot renderers.
6. **Gemini Vision Foundation:** `GeminiAiAuthenticityService` prompt templates and JSON schemas.

---

## 20. What Must Be Changed
1. **Complaint Ingestion Flow:** Remove immediate `autoRouteComplaint()` call from client-side `createComplaint()`.
2. **Execution Sequencing:** Enforce strict sequential gating: Ingestion $\to$ Gemini $\to$ Grok $\to$ Ward/JE Routing.
3. **Status Enum & Mappers:** Add `underVerification` and `closed` to `ComplaintStatus`, `complaint_firestore_mapper.dart`, and `firestore.rules`.
4. **Client Progress Tracker:** Upgrade `ComplaintTracker` and `TimelineStepper` to render 2-step AI verification progress.
5. **Offline Queue Sync:** Ensure offline sync pipeline respects AI verification gates before assigning JEs.

---

## 21. What Must Be Created
1. **Grok AI Department Verification Service:** Prompt template, JSON schema, and xAI API client.
2. **Server-Authoritative AI Verification Pipeline:** Cloud Function or Edge Function trigger `onComplaintCreated` that orchestrates Gemini $\to$ Grok $\to$ Automated Routing with Admin SDK credentials.
3. **AI Verification UI Widgets:** Visual indicators for Gemini (Authenticity) and Grok (Department) status.
4. **Closure Lifecycle Service:** Endpoint / action for transitioning resolved grievances to `closed`.

---

## 22. User Assistance Required for Phase 3

| Required Item | Why It Is Needed |
|---|---|
| **1. Gemini API Key / Credentials** | Required for server-side Gemini 2.5 Flash multimodal vision analysis to assess image authenticity and civic issue validity. |
| **2. Grok / xAI API Key** | Required to connect to the xAI Grok API (`grok-2` / `grok-vision`) for natural language problem classification and BMC department validation. |
| **3. Backend Architecture Selection** | Choice between **Firebase Cloud Functions** (Node.js/TypeScript) or **Supabase Edge Functions** (Deno/TypeScript) for hosting the secure server-side AI pipeline. |
| **4. Stage 5 Workflow Preference** | Decision on whether JE dispatch should immediately mark grievance as `inProgress` (Option A) or keep the explicit field officer "Start Work" button tap (Option B). |

---

## 23. Recommended Phase 3 Implementation Order

```
Step 1: Status Model & Schema Expansion
   ↳ Add `underVerification` and `closed` to ComplaintStatus, Firestore rules, and local models.

Step 2: Server-Side AI Verification Pipeline (Trusted Backend)
   ↳ Implement Cloud/Edge Function trigger on complaint creation.
   ↳ Execute Step 1: Gemini Multimodal Authenticity Verification.
   ↳ Execute Step 2: Grok Problem Type & BMC Department Validation.

Step 3: Automated Routing Gate
   ↳ Trigger `ComplaintRoutingService` automatically ONLY after Gemini + Grok return PASS.

Step 4: Citizen Verification UI & Progress Tracker
   ↳ Update ComplaintTracker and ComplaintDetailsScreen to show Step 1 (Gemini) and Step 2 (Grok) status chips.

Step 5: Notification & Rework Adjustments
   ↳ Add push notifications for AI verification milestones and final ticket closure.

Step 6: Automated End-to-End Regression Verification
   ↳ Run full test suite to ensure all 7 stages execute seamlessly.
```

---

## 24. Baseline Quality & Test Verification
- **`flutter analyze`:** **0 issues found** (Clean).
- **`flutter test`:** **1,096 / 1,096 tests passed** (100% passing).
- **`Brain.md` Update:** Updated with Phase 2 gap analysis and canonical lifecycle definition.

---

## Final Phase 2 Audit Sign-Off

```text
STAGE 1 — CITIZEN SUBMISSION: PARTIAL
STAGE 2 — GEMINI VERIFICATION: INCORRECT
STAGE 3 — GROK DEPARTMENT VERIFICATION: MISSING
STAGE 4 — WARD + JE AUTOMATION: INCORRECT
STAGE 5 — JE → EXECUTION OFFICER: COMPLETE
STAGE 6 — EXECUTION OFFICER RESOLUTION: COMPLETE
STAGE 7 — CLOSE + DEPARTMENTAL OFFICER REOPEN: PARTIAL

READY FOR PHASE 3: YES
```
