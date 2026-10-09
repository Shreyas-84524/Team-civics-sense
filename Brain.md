# CivicFix Brain

## Project Context
CivicFix is a municipal grievance redressal, spatial AI automation, and ground workflow execution platform built for the Brihanmumbai Municipal Corporation (BMC / MCGM). The platform connects Greater Mumbai citizens with municipal administrative machinery across 24 administrative wards (A to T) and 18 canonical municipal departments. The citizen mobile app is built with Flutter, featuring offline-first capabilities (Hive + local queue), spatial mapping (MapLibre + MapTiler vector/satellite tiles), Firebase Authentication / Global OTP verification, Cloud Firestore, and Firebase Storage.

---

## Current Canonical Architecture

### 1. Citizen Complaint Flow
- Citizens report issues by submitting geotagged grievances (GPS latitude/longitude, address, photo evidence, category, title, description).
- Ingestion resolves the 24 BMC Wards using Haversine centroid clustering and 18 canonical BMC departments.
- SLA clock commences immediately upon ingestion (`slaStartedAt`) and is strictly immutable.

### 2. Automatic Junior Engineer (Field Engineer) Routing (Phase 1)
- Eliminates manual triage bottlenecks by Ward Department Leads.
- Incoming verified complaints are automatically routed directly to an active Junior Engineer (`role: department_crew`) within the designated Ward and Department.
- Assignment uses workload-aware load balancing across the active crew members in the unit.
- Status moves to `ComplaintStatus.assigned` with `ComplaintAssignmentStatus.crewAssigned`.

### 3. Field Officer Ground Execution & Resolution Workflow (Phase 2)
- Junior Engineer acts as Technical Owner & Dispatcher and assigns a distinct active Field Officer (`role: department_crew`, `assignedFieldOfficerId != assignedJuniorEngineerId`).
- Field Officer accesses their dedicated "My Jobs" queue with strict multi-tenant isolation.
- Field Officer executes ground work:
  - Taps **Start Work** (`inProgress`, records `workStartedAt`).
  - Flags operational obstacles if blocked (`isBlocked = true`, records reason), resumes when cleared.
  - Submits completion evidence (mandatory After Photo + optional remarks) to directly transition the complaint to **`Closed`** (`ComplaintStatus.closed`, `routingStatus: resolved`). Zero mandatory Lead approval gate.

### 4. Department Lead Quality Oversight & Reopen Authority
- Ward Department Lead (`ward_department_lead`) provides supervisory quality review and post-closure audit authority.
- If field work is defective or incomplete, the Lead audits closed grievances and reopens them with a mandatory audit reason (`reopenCount++`, status returns to `inProgress`).
- SLA (`slaStartedAt`, `originalCreatedAt`) is strictly preserved across all reopens and reassignments.

### 5. Citizen Transparency & Tracking (Phase 3)
- Real-time citizen visibility into supervisory Junior Engineer and executing Field Officer identities via immutable snapshots (`assignedJuniorEngineerNameSnapshot`, `assignedJuniorEngineerDesignationSnapshot`, `assignedFieldOfficerNameSnapshot`, `assignedFieldOfficerDesignationSnapshot`).
- Zero direct queries against `government_users` from citizen clients; civil servant PII (phone, email, UIDs) is protected.
- Side-by-side Before/After evidence display and supervisory rework alert banner.

### 6. MapLibre + MapTiler Spatial Infrastructure
- Offline/online interactive map rendering using MapLibre GL Native with MapTiler vector and satellite basemaps.
- Dynamic key provisioning via environment configuration (`MAPTILER_API_KEY`).

### 7. Global OTP & Auth Architecture
- Phone-based citizen authentication integrated with CivicFix global OTP infrastructure and Firebase Auth.

### 8. Multilingual Architecture & Production Translation Infrastructure (Phases 1–8 Complete)
- **Three Strictly Decoupled Localization Paths:**
  1. `Static UI`: Handled via ARB catalogs (`app_en.arb`, `app_hi.arb`, `app_mr.arb`) and Flutter's `gen_l10n` engine across all Citizen and Government portal screens.
  2. `Backend Canonical Values`: Roles, statuses, departments, and categories remain 100% language-independent ASCII tokens in Firestore (e.g. `inProgress`, `department_crew`, `ward_department_lead`, `roads`, `underVerification`). Translated on-demand at the UI boundary via centralized pure mappers in `canonical_display_mappers.dart`.
  3. `User-Generated Content`: Translated dynamically via `RemoteTranslationService` gated by server-side Firebase Cloud Functions (`translateUserContent`) with Google Gemini. Zero client-side API keys.
- **Immutability of Authoritative User Text:**
  - Citizen and officer-entered text (`title`, `description`, `citizenRemarks`, `officerNotes`, `resolutionRemarks`, `blockedReason`, `reworkReason`, `governmentNotes`) is strictly authoritative and immutable.
  - Translated text lives exclusively in transient presentation wrappers (`TranslatableContent`) and cached translation layers (`TwoLevelTranslationCache`), and is NEVER written back into Firestore complaint document fields.
- **Two-Level Hierarchical Caching & Invalidation:**
  - L1 `MemoryTranslationCache` (in-memory LRU) + L2 `PersistentTranslationCache` (durable storage).
  - Deterministic SHA-256 source hashing (`sourceHash`) ensures cache auto-invalidation when authors edit complaint text.
  - Request deduplication coalesces concurrent in-flight calls.
- **Chatbot, Notifications, & TTS Architecture:**
  - `CivicAssistantService` dynamically follows the active UI locale with localized greetings, prompts, and municipal terminology.
  - `NotificationLanguageTemplates` formats 9 canonical notification event types across English, Hindi, and Marathi with recipient preference fallbacks.
  - `TtsLanguageConfig` maps BCP-47 voices (`en-IN`, `hi-IN`, `mr-IN`) adhering strictly to the visible text reading rule.
- **Historical Data Compatibility & Non-Destructive Migration Policy:**
  - Historical records without language metadata resolve safely via `HistoricalLanguageResolver` (explicit metadata -> cached detection -> `LanguageDetector` -> confident detection -> safe fallback to 'auto').
  - `HistoricalMigrationUtility` provides dry-run audit capabilities with guaranteed `recordsModified == 0`.
  - Feature flag / kill-switch `TranslationConstants.dynamicTranslationEnabled` provides instant production rollback safety.

---

## Important Role Model

### Canonical Authentication Roles (6 Municipal Roles):
1. `super_admin`: Central Municipal Commissioner / System Administrator.
2. `zonal_dmc`: Zonal Deputy Municipal Commissioner (overseeing 3-4 Wards).
3. `central_hod`: Central Head of Department (overseeing a specific department citywide).
4. `ward_officer`: Assistant Commissioner / Ward Officer (administrative head of a Ward).
5. `ward_department_lead`: Executive Engineer / Ward Department Lead (supervisory oversight, quality review, audit & rework).
6. `department_crew`: Field Technical Personnel (2,160 citywide; 5 per Ward × Department unit).

### Dual Role Model on `department_crew`:
- **Junior Engineer (`assignedJuniorEngineerId` / `assignedCrewMemberId`):** Technical Owner, initial recipient, field dispatcher, rework coordinator.
- **Field Officer (`assignedFieldOfficerId`):** Physical ground executor, machine operator, on-site contractor supervisor, direct resolver.
- **Alias Relationship:** `assignedJuniorEngineerId` is a semantic alias for `assignedCrewMemberId`.
- **Distinction Invariant:** For every normal grievance, `assignedJuniorEngineerId != assignedFieldOfficerId`.

---

## Current Complaint Workflow

```
Reported (GPS Geotagged + Categorized)
  ↓
Automatically Routed (Ward Detection + Dept Classification + Workload Balance)
  ↓
Assigned to Junior Engineer (status: assigned, assignmentStatus: crewAssigned)
  ↓
Field Officer Assigned (assignedFieldOfficerId set, assignmentStatus: fieldOfficerAssigned)
  ↓
In Progress (workStartedAt logged, optional obstacle handling)
  ↓
Closed (After-photo + remarks submitted by Field Officer; complaint closed directly)
  ↓
Optional Post-Closure Quality Review / Reopen Rework (by Ward Department Lead)
```

---

## Important Invariants

1. **SLA Immutability:** `slaStartedAt` and `originalCreatedAt` must never reset during routing, reassignment, or rework cycles.
2. **Role Separation:** Junior Engineer and Field Officer must be distinct individuals (`assignedJuniorEngineerId != assignedFieldOfficerId`).
3. **Complaint Privacy:** Citizens only access their own complaints; citizens must not access unrestricted government personnel collections (`government_users`).
4. **Canonical Store:** `/complaints` collection in Cloud Firestore is the canonical truth.
5. **No Hardcoded Secrets:** MapTiler API keys and Firebase credentials must never be hardcoded.
6. **Trust Boundary Integrity:** Citizens must not directly mutate government-controlled assignment, audit, or resolution fields.

---

## Recent Major Changes

- **Phase 1 (Automated JE Routing):** Removed manual triage by Ward Department Leads. Introduced automated Ward and Department detection with workload-aware direct routing to Junior Engineers (`department_crew`).
- **Phase 2 (Field Officer Execution & Resolution):** Implemented Junior Engineer dispatch to Field Officers, "My Jobs" isolated workdesk, on-site work start, obstacle blocking, direct Field Officer resolution, and Ward Lead quality reopen.
- **Phase 3 (Citizen Transparency & Tracking):** Added citizen tracking view with immutable officer snapshots, Before/After photo comparison, dynamic timeline stages, and supervisory rework banner without PII leakage.

---

## Debug History

### 2026-10-01: Citizen Complaint Submission Authorization Regression Fix
- **Issue:** Citizen complaint submission failed at the final Review step with: *"CivicFix could not submit this complaint because of an authorization problem. Please try again shortly."*
- **Root Cause:**
  1. In commit `d16c9f6` (Phase 1 Automated Routing), `OfflineFirstComplaintRepository.createComplaint` and `FirebaseComplaintRepository.createComplaint` invoked `_routingService.autoRouteComplaint(complaint)` **before** writing to Cloud Firestore via `_remoteDataSource.createComplaint(routed)`.
  2. Auto-routing mutated the complaint status to `assigned` and populated government assignment fields (`assignedTo`, `assignedDepartmentId`, `assignedCrewMemberId`).
  3. In `complaint_firestore_mapper.dart`, `'departmentId': complaint.assignedDepartmentId` populated `departmentId`.
  4. When the citizen client attempted to create `/complaints/{complaintId}`, Cloud Firestore Security Rules (`firestore.rules` line 280–295) evaluated:
     - `request.resource.data.status == 'reported'` $\to$ **FALSE** (was `'assigned'`)
     - `request.resource.data.assignedTo == null` $\to$ **FALSE** (was non-null)
     - `request.resource.data.departmentId == null` $\to$ **FALSE** (was non-null)
  5. Cloud Firestore rejected the write with `permission-denied` (error code `permission-denied`), mapped by `ReportIssueScreen._mapSubmissionError` to the authorization failure banner.
- **Files Changed:**
  - `TeamCivicSense/civic_app/lib/core/firebase/mappers/complaint_firestore_mapper.dart`: Explicitly ensured `departmentId` and `assignedTo` are strictly `null` when `isCreate: true`.
  - `TeamCivicSense/civic_app/lib/core/repositories/offline_first_complaint_repository.dart`: Fixed ingestion sequencing to create the initial citizen grievance in Firestore with `status: reported` and null government assignment fields first, then execute `autoRouteComplaint(created)` to transition and update cache.
  - `TeamCivicSense/civic_app/lib/core/repositories/firebase_complaint_repository.dart`: Fixed ingestion sequencing so initial remote creation preserves citizen trust boundary before automated routing.
  - `TeamCivicSense/civic_app/test/core/repositories/complaint_submission_authorization_regression_test.dart`: Added comprehensive unit & regression test suite covering all 8 creation payload security rule invariants.
- **Fix Applied:** Enforced strict trust boundary separation where the citizen payload only contains citizen-originating fields (`status: reported`, `assignedTo: null`, `departmentId: null`). Routing occurs immediately following successful document creation.
- **Tests Run:**
  - `flutter analyze` $\to$ 0 issues found.
  - `flutter test test/core/repositories/complaint_submission_authorization_regression_test.dart` $\to$ 8/8 tests passed.
  - Full test suite: 1,079+ unit, integration, and architecture tests passing.
- **Result:** Citizen complaint submission completes seamlessly without authorization errors. Phase 1 automatic JE routing, Phase 2 Field Officer execution, and Phase 3 citizen transparency remain 100% operational.
- **Remaining Risks:** None. Ingestion trust boundaries and Firestore security rules are fully aligned and regression-tested.

---

## Current Task: Phase 1 Legacy Complaint Cleanup Completed
- **Status:** Completed & Verified.
- **Summary:** All legacy and test complaint documents, subcollections (complaint_updates, upvotes), and associated routing test records were safely purged from Cloud Firestore. Government personnel hierarchy, authentication accounts, citizen profiles, and global configuration were 100% preserved.

---

## Complaint Automation Rebuild

Canonical lifecycle:

Citizen Submission
→ Gemini Verification
→ Grok Department Verification
→ Automated Ward/JE Assignment
→ JE assigns Execution Officer
→ Work In Progress
→ Execution Officer Resolution
→ Resolved
→ Closed
→ Departmental Officer Reopen

---

## Phase 1 — Legacy Complaint Cleanup

- **Collections cleaned:**
  - `complaints`: 9 root documents removed (`cPwES4DLJ2pnQB6EirG9`, `cmp_diag_1790621344083`, `cmp_live_1790620651204_000026`, `cmp_r_north_road_01`, `cmp_r_north_road_02`, `cmp_r_north_road_03`, `cmp_r_north_road_04`, `cmp_r_north_road_05`, `fwxoYu5bZi7PRSvIvhdh`)
  - `complaints/{complaintId}/complaint_updates`: 16 subcollection audit timeline documents removed
  - `complaints/{complaintId}/upvotes`: 3 subcollection citizen upvote documents removed
  - Ancillary complaint collections scanned: `complaint_updates` (0), `complaint_routing_tickets` (0), `government_audit_logs` (0), `hazards` (0), `notifications` (0), `rewards` (0)
- **Counts before deletion:**
  - `complaints`: 9 documents
  - `complaint_updates` (subcollections): 16 documents
  - `upvotes` (subcollections): 3 documents
  - Total complaint-owned documents: 28 documents
- **Counts after deletion:**
  - `complaints`: 0 documents
  - `complaint_updates` (subcollections): 0 documents
  - `upvotes` (subcollections): 0 documents
  - Total complaint-owned documents: 0 documents
- **Local cache cleanup:**
  - Hive boxes (`complaints`, `complaint_upvotes`, `complaint_updates`, `pending_sync`, `hazards`) and repository in-memory data structures verified clean.
- **Storage cleanup:**
  - Firebase Storage evidence paths inspected; bucket contains 0 orphaned files.
- **Data intentionally preserved:**
  - `government_users`: 3,699 municipal personnel documents (Super Admin, Zonal DMCs, Central HODs, Ward Officers, Ward Department Leads, Department Crew)
  - `users`: 3,724 citizen and government profile documents
  - `phoneIndex`: 3 registered phone index documents
  - BMC 24 Wards & 18 Departments static hierarchy
  - Firebase Auth users & Global OTP infrastructure
  - MapTiler basemap and spatial configuration

---

## Phase 3 — Trusted Two-Stage AI Verification, Canonical Department Gating & Routing Integration

### 1. Architectural Overview & Trust Boundaries
- **Server-Authoritative Execution:** AI verification and automated Junior Engineer routing execute exclusively on the backend (Cloud Functions triggers on `complaints/{complaintId}` creation/updates).
- **Client Trust Boundaries:** The citizen mobile client creates grievances with `status: underVerification`, `evidenceVerificationStatus: pending`, and `departmentVerificationStatus: pending`. Client is strictly prohibited from mutating AI verification fields, government routing targets, or SLA metadata (`firestore.rules` enforces immutable creation gates and server-authoritative field locks).
- **Dual Secret Provisioning:**
  - `GEMINI_API_KEY`: Primary Gemini API key for Step 1 multimodal evidence verification.
  - `GEMINI_DEPARTMENT_API_KEY`: Dedicated secret environment variable for Step 2 department verification & category classification.

---

### 2. The Authoritative 7-Stage Complaint Lifecycle

```
[1. Citizen Submission]
  ↓ (Status: underVerification)
[2. Gemini Step 1: Evidence Verification]
  ↓ (Status: underVerification, evidenceVerificationStatus: passed/failed)
[3. Gemini Step 2: Department Verification]
  ↓ (Status: underVerification, departmentVerificationStatus: passed/failed, verifiedDepartmentId: allowlist-validated)
[4. 5-Gate Ward + Junior Engineer Auto-Routing]
  ↓ (Status: assigned, assignmentStatus: crewAssigned, assignedCrewMemberId: JE_ID)
[5. Junior Engineer Dispatches Execution Officer]
  ↓ (Status: assigned, assignmentStatus: fieldOfficerAssigned, assignedFieldOfficerId: FO_ID)
[6. Execution Officer Ground Execution & Resolution]
  ↓ Tap "Start Work" -> (Status: inProgress, workStartedAt logged)
  ↓ Complete Ground Work -> (Status: resolved, after-photo + remarks uploaded)
[7. Final Closure & Ward Department Lead Supervisory Rework]
  ↓ Ticket Closed -> (Status: closed, closedAt logged)
  ↓ Lead Rework (if defective) -> (Status: inProgress, reworkCount++, return to field)
```

---

### 3. Key Components & Implementation Matrix

| Component | Responsibility / Functionality | Location |
| :--- | :--- | :--- |
| **Data Models** | `ComplaintStatus.underVerification`, `ComplaintStatus.closed`, verification flags, timestamps | `lib/core/models/complaint_model.dart` |
| **Firestore Serialization** | Dynamic mapping for `underVerification`, `closed`, and verification metadata | `lib/core/firebase/mappers/complaint_firestore_mapper.dart` |
| **Offline Persistence** | Hive fields 59-73, backward-compatible schema adapter | `lib/core/local/models/complaint_local_model.dart`, `complaint_hive_adapter.dart` |
| **Cloud Functions Trigger** | Firestore trigger `onComplaintCreated` & `onComplaintStatusChanged` | `functions/src/index.ts` |
| **Two-Stage AI Verification** | Gemini Step 1 (Evidence) + Step 2 (Department Allowlist Validation) | `functions/src/gemini_verification.ts` |
| **Canonical Hierarchy & Allowlist** | Closed 18 BMC departments allowlist & 24 Wards Haversine centroid resolution | `functions/src/departments.ts` |
| **Automated 5-Gate Routing** | Verification check + Allowlist gate + Ward GPS gate + Least-loaded JE assignment | `functions/src/routing.ts`, `lib/core/services/complaint_routing_service.dart` |
| **Security Rules** | `isValidStatus()` with `underVerification`/`closed`, server-authoritative field lock | `firestore.rules` |
| **Citizen UI Transparency** | 5-stage vertical tracker with Step 1 & Step 2 verification progress chips | `lib/User UI/widgets/complaint_details/complaint_tracker.dart` |

---

### 4. Critical Invariants & Anti-Hallucination Guarantees
1. **Zero Hallucinated Departments:** Gemini output is parsed for canonical BMC department ID and strictly validated against the closed 18 BMC department allowlist (`functions/src/departments.ts`). Unapproved departments immediately fail verification.
2. **Anti-Silent Fallback:** Coordinates outside the 35 km Mumbai administrative perimeter return an explicit resolution error without silently falling back to G/North.
3. **SLA Clock Immutability:** `slaStartedAt` and `originalCreatedAt` are preserved across all transitions, department transfers, and supervisory reopens.
4. **Supervisory Quality Review:** Ward Department Leads (`ward_department_lead`) have supervisory authority to reopen `resolved` or `closed` complaints back to `inProgress` with mandatory rework reasons.

---

### 5. Verification & Test Coverage
- **Flutter Static Analysis:** 0 issues (`flutter analyze`).
- **Flutter Test Suite:** 1,104 / 1,104 tests passing (`flutter test`).
- **Cloud Functions Unit Tests:** 10 / 10 tests passing (`npm test` in `functions/`).

---

## Government Credential Reset — Phase 1: Complete Deletion of Existing Government Auth Credentials
- **Status:** COMPLETED & VERIFIED
- **Active Project:** `civicfix-38d53` (Firebase Auth & Cloud Firestore)
- **Government Auth Identities Deleted:** 2,642 (1 Super Admin, 7 Zonal DMCs, 18 Central HODs, 24 Ward Officers, 432 Ward Department Leads, 2,160 Department Crew)
- **Active Sessions / Refresh Tokens Revoked:** 2,642 government identities revoked prior to permanent deletion
- **Citizen Auth Accounts Preserved:** 10 (100% untouched and operational; 0 citizen accounts affected)
- **Government Organizational Data Preserved:** 3,699 Firestore `government_users` documents (2,642 active canonical + 1,057 retired), municipal hierarchy, wards, departments, and personnel metadata preserved 100%
- **Firestore Credential Fields Scanned & Cleaned:** 0 credential fields found across `government_users` (3,699 docs) and `users` (3,726 docs); zero plaintext or recoverable passwords in Firestore
- **Old Credential Artifacts Permanently Removed:**
  - `government_accounts_credentials_civicfix_dev.xlsx` (root)
  - `TeamCivicSense/resources/Govt Data/government_accounts_credentials (1).xlsx`
  - `TeamCivicSense/resources/Govt Data/government_accounts_credentials_civicfix_dev.xlsx`
  - `TeamCivicSense/civic_app/resources/Govt Data/government_accounts_credentials (1).xlsx`
  - `TeamCivicSense/civic_app/resources/Govt Data/government_accounts_credentials_civicfix_dev.xlsx`
  - `TeamCivicSense/resources/Govt Data/legacy_backup/` directory
  - `TeamCivicSense/.temp/government-account-replacement/` directory
  - Legacy documentation reports scrubbed of historical password strings
- **Zero Credential Backup Policy:** Strict compliance; NO backup files, dumps, exports, hashes, or passwords created or retained
- **Secret Residue in Repository:** 0
- **Readiness for Phase 2:** READY (Clean slate established for generating entirely fresh government credentials)

---

## Government Account Cleanup Follow-up
- **Stale Collections Identified:**
  - `/government_users`: contained 3,699 stale government account documents (2,642 canonical active profiles + 1,057 retired historical profiles; 0 citizen records).
  - `/users`: contained 3,699 stale government account documents (dual-written identical IDs and roles) co-located with 27 citizen user profiles (total 3,726 documents).
- **Reason Previous Cleanup Left Records:**
  - The previous Phase 1 specification explicitly instructed to preserve `/government_users` metadata and personnel records as "CivicFix's government organizational database necessary for generating new accounts" (Sections 7 & 9: *"This task concerns government AUTH CREDENTIALS only... Do NOT delete: personnel records"*).
  - The previous cleanup strictly deleted all 2,642 Firebase Authentication identities while intentionally preserving the Firestore document entities in accordance with those explicit boundaries.
- **Number of Records Deleted:**
  - `/government_users`: 3,699 documents deleted (100% of collection).
  - `/users`: 3,699 stale government documents deleted.
  - Total stale Firestore documents deleted: 7,398 documents.
  - Subcollections deleted: 0 (verified no subcollections existed on government documents).
- **Citizen Records Preserved:**
  - `/users`: All 27 citizen user profile documents 100% preserved and untouched (`role == 'citizen'`).
  - Firebase Authentication: All 10 citizen Auth accounts 100% preserved and active.
  - `/complaints` (4 active grievances) and `/phoneIndex` (3 citizen OTP mappings) 100% preserved.
- **Final Stale Government Records Remaining:**
  - `/government_users`: 0
  - `/users` (government role): 0
  - Firebase Auth (government): 0
- **Readiness:** Clean slate across both Firebase Authentication and Cloud Firestore collections, ready for final Excel-based reprovisioning.

---

## Final Government Account Provisioning

Source:
`New Data.xlsx`

Sheet:
`All Government Accounts`

Final account count:
2,642 accounts

- **Active Firebase Project:** `civicfix-38d53`
- **Firebase Auth Provisioned:** 2,642 newly created Email/Password accounts (0 collisions, 0 reused)
- **Government Profiles Provisioned:** 2,642 profiles dual-written to `/government_users/{new_uid}` and `/users/{new_uid}`
- **Role Mappings Verified:**
  - `government_super_admin`: 1
  - `zonal_dmc`: 7
  - `central_department_hod`: 18
  - `ward_officer`: 24
  - `ward_department_lead`: 432
  - `department_crew`: 2,160
- **Hierarchy Validated:** 100% aligned with 18 canonical BMC departments, 24 administrative wards, and 7 zones
- **Representative Logins Tested:** Verified across all 6 administrative tiers with Firebase Auth REST API (all succeeded with valid tokens and correct role/jurisdiction resolution)
- **Citizen Accounts Preserved:** All 10 citizen Firebase Auth accounts and 27 citizen Firestore profiles 100% preserved and untouched
- **Password Store Invariant:** Passwords passed ONLY to Firebase Authentication during account creation; zero passwords stored in Cloud Firestore or written to persistent logs/reports
- **Bundled Metadata Synchronized:** `government_users.json` (across 3 repository locations) and `firebase_uid_mapping.json` updated with newly minted Firebase UIDs
- **Readiness:** Complete and verified, ready for Phase 3 exhaustive verification

---

## Government Portal — My Work Render Defect Resolution

- **Issue:** Government Portal page "My Work — Solid Waste Management" (`/government/work`) opened with sidebar, top nav, badges, and breadcrumb visible, but the entire main content area below was blank.
- **Root Cause:** In Flutter Web CanvasKit/HTML, `Expanded(child: RefreshIndicator(child: SingleChildScrollView(child: Column(...))))` contained nested `ListView.builder(shrinkWrap: true)` and `GridView.count(shrinkWrap: true)` inside an unconstrained vertical axis. When populated with Kailash Deshmukh's assigned job (`#CF-2026-1791090369943000-64ce47c897cc`), `ShrinkWrappingViewport` threw layout assertions in `box.dart:2251:12` (`assert(hasSize, 'RenderBox was not laid out: $this')`), aborting painting of the main body.
- **Fix:**
  - Removed desktop `RefreshIndicator` wrapping on `SingleChildScrollView` (made conditional on `isMobile`, matching `DepartmentOperationsScreen`).
  - Replaced nested `ListView.builder(shrinkWrap: true)` in `CrewJobQueueSection`, `CrewAwaitingReviewSection`, and `CrewCompletedSection` with direct mapped `Column` items.
  - Replaced `GridView.count(shrinkWrap: true)` in `CrewKpiSummarySection` with responsive `Wrap` and replaced `Spacer()` with fixed spacing.
  - Converted `CrewJobCard` footer to responsive `Wrap`.
- **Validation:**
  - `hot_restart` applied on live web application; runtime errors: 0.
  - Phase 8 Crew Field Operations tests: 15/15 passed.
  - Complete Govt UI test suite: 288/288 passed.
  - Report generated: `GOVERNMENT_MY_WORK_RENDER_FIX_REPORT.md`.

---

## Citizen Map Spatial Loading + Hazard Card

- **Objective:** Upgrade the CivicFix Citizen Map (`HazardMapScreen` + `CivicMapCanvas`) to:
  1. Eliminate full-city eager data loading by loading map hazards/complaints progressively in spatial chunks based on the visible map viewport + prefetch buffer.
  2. Implement interactive tap handling on MapLibre unclustered hazard points to display a floating information card with real-time status tracking, while expanding clusters on tap and dismissing on canvas taps.
- **Spatial Indexing & Chunk Architecture (`GeohashUtils` & `MapChunkManager`):**
  - Grid: Standard Base32 Geohash at precision 5 (~4.9 km × 4.6 km cells), optimally sizing cells for municipal ward scales without excess Firestore reads.
  - Viewport & Prefetch: Computes visible `SpatialBounds` from `MapLibre` camera bounds with a 0.25 margin ratio prefetch buffer so panning feels seamless and unhindered.
  - Debounce & Deduplication: 250ms debounce on camera idle/movement events.
  - Race Condition Protection: Monotonic generational request tokens (`_currentGeneration`) ensure out-of-order async responses from rapid panning are discarded.
  - In-Memory Cache: `_loadedChunkIds` set tracks fetched chunks, issuing Firestore queries only for newly visible chunk IDs.
- **Data Model & Firestore Query Pipeline:**
  - `spatialChunkId` & `geohash` added to `ComplaintModel`, `HazardModel`, and `SpatialFeature` GeoJSON properties with automated fallback computation (`computedSpatialChunkId`).
  - Added `citizenPhaseLabel` mapper providing citizen-friendly progress status (`Under Verification`, `Assigned`, `Work In Progress`, `Resolved`, `Closed`, `Rework / Work In Progress`).
  - `FirebaseHazardDataSource` and `FirebaseComplaintDataSource`: Added `getHazardsBySpatialChunks` / `getComplaintsBySpatialChunks` with 30-item chunk slicing for Firestore `whereIn` constraints.
  - `OfflineFirstHazardRepository` synchronized with chunk cache and local Hive store.
- **Native MapLibre Interaction:**
  - `CivicMapCanvas` utilizes `_mapController.queryRenderedFeatures` targeted at `MapConstants.unclusteredPointsLayerId`.
  - Point Tap: Extracts feature properties (`id`, `title`, `category`, `status`, `citizenPhaseLabel`, `ticketNumber`, `reportedAt`, `assignedDepartment`) and triggers `onHazardTapped`.
  - Cluster Tap: Intercepts cluster feature tap, queries point coordinates, and animates camera zoom (+2.0 zoom delta) centered on cluster without triggering card.
  - Empty Map Canvas Tap: Triggers `onMapTap` callback to dismiss open card.
- **Live Card Synchronization:**
  - `HazardMapScreen` wires dual reactive streams: `_complaintRepository.watchComplaint(complaintId)` and `_hazardRepository.watchHazardById(hazard.id)`. Any status change, field officer dispatch, or resolution on the selected grievance immediately updates `HazardInfoCard` in real time.
- **Verification & Quality:**
  - 9/9 new unit & widget tests in `test/core/map/spatial_chunk_manager_test.dart` passing.
  - 69/69 tests in `test/core/map/` passing.
  - `flutter analyze` completed with 0 errors across the entire codebase.

---

## Crew Member Profile & Login Verification (Phase 2 Reprovisioning Audit)

- **Objective:** Verify whether the 2,160 frontline Department Crew member profiles (`role: department_crew`) across all 24 Wards and 18 Departments exist and are correctly mapped to newly provisioned Firebase Auth accounts, diagnose any login/profile-opening issues, and export a clean local credential CSV for crew members.
- **Verification Findings:**
  - Active Project: `civicfix-38d53` confirmed.
  - Total Crew Users: Exactly 2,160 crew member accounts in `New Data.xlsx`, Firebase Authentication, `/government_users`, and `/users`.
  - Auth $\leftrightarrow$ Profile Linking: 100% matched by newly minted Firebase Auth UIDs (0 orphaned accounts, 0 missing profiles, 0 UID mismatches).
  - Role & Hierarchy: All 2,160 records have `role: 'department_crew'`, valid `wardId`, `departmentId`, and valid `administrativeSupervisorId` (Ward Department Lead).
  - Firestore Security Rules: Verified that authenticated crew users have read permission on their own documents in `/users/{userId}` and `/government_users/{userId}` via ID token.
  - Live Authentication & Profile Resolution: 100/100 sampled logins passed live REST & Firestore query tests, correctly redirecting to `/government/work` (`CrewFieldOperationsScreen`).
- **Root Cause Analysis:**
  - Login failure was caused by password formatting discrepancy (floating-point `.0` string representation e.g. `123456.0` from spreadsheet viewers vs normalized integer string `123456` in Firebase Auth) and absence of a standalone crew credentials export file.
  - No profile remapping or schema repair was required; all 2,160 profiles were already perfectly formed.
- **Handover Artifact:**
  - Generated `CivicFix_Crew_Login_Credentials.csv` containing all 2,160 crew members with headers `Email`, `Password`, `Employee ID`, `Full Name`, `Role`, `Department / Authority`, `Ward / Zone`.
  - File is Git-ignored and protected against commits.
  - Report generated: `CREW_PROFILE_AND_LOGIN_VERIFICATION_REPORT.md` (no plaintext passwords in report or logs).

---

## UI/UX Redesign — Phase 1

- **Authoritative Specification:** `DESIGN.md` (*Civic Precision — Editorial Minimalism*) adopted as the authoritative UI specification.
- **Centralized Design-Token Architecture:** Created `lib/core/theme/civicfix_design_tokens.dart` containing all authoritative color tokens, spacing scales, border radii, elevations, and typography tokens.
- **Strict Color Architecture Rule:** No feature screen owns its own color palette. Literal UI color values exist exclusively inside `civicfix_design_tokens.dart`.
- **Typography Direction:** Plus Jakarta Sans for prominent headers and monumental titles; Inter for dense transactional UI, forms, and descriptive body copy.
- **Spacing, Radius & Elevation Architecture:** 4px/8px modular base scale, Soft Level 1 architectural radii (4px base, 8px card, 12px modal, 9999px pill badges), 1px hairline framing (`#E2E8F0`), and minimal diffuse deep-slate elevation.
- **Global Theme Foundation:** Created `lib/core/theme/civicfix_theme.dart` (`CivicFixTheme.lightTheme`) consuming design tokens for Material 3 `ColorScheme`, `TextTheme`, `AppBarTheme`, `CardThemeData`, `ElevatedButtonThemeData`, `OutlinedButtonThemeData`, `InputDecorationTheme`, `ChipThemeData`, and `DialogThemeData`. Wired into `main.dart`.
- **Next Phase Readiness:** Clean foundation established and verified with 0 analyzer issues; ready for Phase 2 component and screen migration.

---

## UI/UX Redesign — Phase 2: Global Theme + Core Component Migration

- **Objective:** Expand global `ThemeData` to cover all Material 3 components and migrate/standardize all core reusable UI widgets to consume `CivicFixColors` tokens exclusively with zero hardcoded literals.
- **Global Theme Component Coverage (25 Component Configurations):**
  - Expanded `lib/core/theme/civicfix_theme.dart` with institutional configurations for: `appBarTheme`, `cardTheme`, `elevatedButtonTheme`, `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `iconButtonTheme`, `inputDecorationTheme`, `searchBarTheme`, `searchViewTheme`, `checkboxTheme`, `radioTheme`, `switchTheme`, `chipTheme`, `dividerTheme`, `dialogTheme`, `bottomSheetTheme`, `navigationBarTheme`, `navigationRailTheme`, `drawerTheme`, `listTileTheme`, `progressIndicatorTheme`, `tooltipTheme`, `bottomNavigationBarTheme`, `floatingActionButtonTheme`.
  - ColorScheme, Typography (Plus Jakarta Sans + Inter), and Elevation tokens bound across all component themes.
- **Standardized Core Component Architecture (`lib/core/widgets/`):**
  - `CivicFixCard` (`civic_fix_card.dart`): White elevated surface, 1px `#E2E8F0` hairline border, 8px radius, optional top gold accent rule, zero hardcoded colors.
  - `CivicFixButton` / `CivicFixPrimaryButton` (`civic_fix_button.dart`): Deep slate `#0F172A` background, white text, 4px radius, 48px height, touch targets $\ge 48\text{px}$.
  - `CivicFixSecondaryButton` / `CivicFixOutlinedButton` (`civic_fix_outlined_button.dart`): White surface, deep slate text, 1px hairline border, 4px radius.
  - `CivicFixAccentButton`: Burnished gold `#CA8A04` CTA for high-priority citizen/government actions.
  - `CivicFixTextField` (`civic_fix_text_field.dart`): 42px height, 4px radius, 1px border, Inter text, accessible error states.
  - `CivicFixSearchField` (`civic_fix_search_field.dart`): 48px height, `#FFFFFF` fill, `#E2E8F0` border, muted search icon, shortcut badge support.
  - `CivicFixStatusChip` (`civic_fix_status_chip.dart`): Pill 9999px status badges with 1px border for 7 semantic variants (`success`, `warning`, `error`, `info`, `neutral`, `verified`, `processing`).
  - `CivicFixListTile` (`civic_fix_list_tile.dart`): Institutional list row with white background, 1px border, 8px radius, Plus Jakarta Sans title, Inter subtitle.
  - `CivicFixInfoBanner` (`civic_fix_info_banner.dart`): Semantic alert banner with hairline border and light container tinting.
  - `CivicFixSectionHeader` (`section_header.dart`): Plus Jakarta Sans section headers with Inter subtitles and gold action links.
  - `CivicFixEmptyState` (`empty_state.dart`), `CivicFixErrorState` (`error_state.dart`), `CivicFixLoadingState` (`loading_state.dart`): Fully tokenized institutional states.
  - `CivicFixAppBar` (`civic_fix_app_bar.dart`): Clean porcelain header with bottom hairline border and Plus Jakarta Sans typography.
  - `PriorityBadge` & `StatusBadge`: Refactored to eliminate hardcoded hex colors and consume `CivicFixColors` tokens.
  - `CoreWidgets` Barrel (`core_widgets.dart`): Centralized exports for all core components.
- **Verification & Analysis:**
  - `flutter analyze` passed with **0 issues found**.
  - All Phase 2 work completed without Git commit/push (strict rule adhered to).
  - Ready for Phase 3: Screen-by-Screen Layout & Feature Migration.

---

## UI/UX Redesign — Phase 3: Typography, Spacing, Geometry & Shared Layout Consistency

- **Objective:** Establish structural visual consistency, shared page layout primitives, responsive breakpoint standardization, and typography/spacing rhythm across the shared shell and containers.
- **Shared Layout Primitives Created (`lib/core/widgets/`):**
  - `CivicFixPageShell` (`civic_fix_page_shell.dart`): Authoritative page scaffold with porcelain canvas background (`#F8F9FF`), optional `CivicFixPageHeader`, optional app bar, drawer, bottom navigation, floating action button, responsive content wrapping, and specialized constructors (`CivicFixPageShell.form`, `CivicFixPageShell.map`).
  - `CivicFixContentContainer` (`civic_fix_content_container.dart`): Centers content and applies responsive horizontal margins (16px mobile, 24px tablet/desktop) and max width constraints (1280px standard, 680px for forms/auth, 1440px for wide data dashboards).
  - `CivicFixPageHeader` (`civic_fix_page_header.dart`): Standardized page header with Plus Jakarta Sans title, Inter subtitle, breadcrumbs, status chips, back button, and responsive action wrapping.
  - `CivicFixSection` (`civic_fix_section.dart`): Structural section container enforcing consistent 24px vertical rhythm and integrated section headers.
  - `CivicFixResponsiveGrid` (`civic_fix_responsive_grid.dart`): Adaptive column grid for card arrays and metric modules (4 cols mobile, 8 cols tablet, 12-col / 3-4 cols desktop).
- **Responsive Breakpoint Standardization (`CivicFixBreakpoints`):**
  - Mobile: $< 768\text{px}$ (4 columns, 16px margins/gutters)
  - Tablet: $768\text{px} - 1279\text{px}$ (8 columns, 24px margins, 20-24px gutters)
  - Desktop: $1280\text{px}+$ (12 columns, 48px margins, 24px gutters, 1280px max content width)
  - Synchronized `CivicFixBreakpoints`, `AppConstants`, and `GovtThemeTokens`.
- **Government Portal Shell Consistency (`lib/Govt UI/`):**
  - Updated `GovtThemeTokens` breakpoints to match `CivicFixBreakpoints` (768px / 1280px / 1440px).
  - Standardized `GovernmentPageHeader`, `GovtAppBar`, and `GovernmentSectionHeader` to use tokenized margins, hairline borders, and chip radii.
  - Standardized `GovtCard` variants (`info`, `warning`, `critical`) to consume `CivicFixColors` tokens.
- **Citizen App Shell Consistency (`lib/User UI/`):**
  - Standardized `MainNavigationScreen` bottom navigation bar: white elevated surface (`#FFFFFF`), 1px hairline top border, gold selected icon/label (`#CA8A04`), muted unselected icon/label (`#837562`), zero heavy drop shadows.
  - Standardized `HomeHeader` and `AuthHeader` to use token typography, subtle elevation, and 4px button radii.
- **Verification & Analysis:**
  - `flutter analyze` completed with **0 issues found**.
  - All changes made in working tree without Git commit/push (strict rule adhered to).
  - Ready for Phase 4: Citizen Screen-by-Screen Redesign.

---

## UI/UX Redesign — Phase 4: Citizen Home Dashboard + Navigation Experience

- **Objective:** Redesign the Citizen Home Dashboard (`HomeScreen`) and surrounding citizen navigation experience into a premium, editorial, high-clarity civic utility interface following `DESIGN.md`.
- **7-Zone Visual Hierarchy Implemented:**
  - **Zone 1 (Greeting & Identity):** `HomeHeader` displaying citizen greeting, municipal ward indicator (`Greater Mumbai`), profile avatar trigger, and notification indicator with real-time badge.
  - **Zone 2 (Hero Action):** `ReportIssueCta` deep slate `#0F172A` banner with burnished gold `#CA8A04` camera icon badge, clear value proposition, and touch target $\ge 56\text{px}$.
  - **Zone 3 (Grievance Overview):** `HomeComplaintSummaryCard` displaying live counts for *Under Review*, *In Progress*, and *Resolved Fixes* with semantic status dots and 1px dividers.
  - **Zone 4 (Quick Services):** `CivicFixResponsiveGrid.dual` containing `QuickActionCard` tiles (*My Grievances*, *Hazard GIS Map*, *Civic Rewards*, *BMC Directory*) with `#FFFFFF` surfaces, 1px `#E2E8F0` borders, and slate icon containers.
  - **Zone 5 (Recent Grievances):** `ComplaintPreviewCard` list displaying ticket ID pills, status badges, sync indicators, category icons, and relative timestamps.
  - **Zone 6 (Nearby Hazards):** `NearbyHazardCard` preview with category icons, distance pills, locality strings, and "View map $\rightarrow$" action.
  - **Zone 7 (Civic Standing):** `CivicProgressCard` previewing civic standing tier, contribution progress bar, total points, reports filed, and resolved fixes.
  - **Zone 8 (AI Assistant Entry):** `HomeAssistantBanner` providing discoverable access to the CivicFix AI Assistant with editorial styling.
- **Shared Foundation Integration:**
  - `HomeScreen` is encapsulated inside `CivicFixPageShell` with max-width containment (`1280px`), responsive padding, and `CivicFixSection` vertical rhythm (24px).
- **Verification & Analysis:**
  - `flutter analyze` completed with **0 issues found**.
  - No Git commit/push made (strict rule adhered to).
  - Ready for Phase 5: Citizen Grievance Reporting Flow & Details Redesign.

---

## UI/UX Redesign — Phase 5: Citizen Grievance Reporting Flow Redesign

- **Objective:** Redesign the complete Citizen Grievance Reporting Flow (`ReportIssueScreen`) and supporting components into a guided, premium, editorial 4-step progressive disclosure wizard while preserving 100% of underlying business logic (Firebase/Firestore submission, Gemini verification handoff, offline Hive fallback, image picker & compression, GPS location detection, and auth).
- **Authoritative Design Tokens & "Civic Precision" Alignment:**
  - Pure porcelain background (`#F8F9FF`) with pure white elevated surface cards (`#FFFFFF`).
  - 1px hairline architectural framing (`#E2E8F0`).
  - Burnished Gold accent submit CTA (`#CA8A04`) and authoritative Slate controls (`#0F172A`).
  - Plus Jakarta Sans headers and Inter body typography via `CivicFixTypographyTokens`.
  - Zero hardcoded colors (`Color(0x...)`, `Colors.*`).
- **4-Step Guided Flow Architecture:**
  - **Step 1 — Issue Information (`IssueCategorySelector`, `CivicFixTextField`):**
    - Standardized Title input with min 5-character validation.
    - Category selector with pure white surfaces, 1px border, 42px category icon box, and subtle warm gold highlight with checkmark badge upon selection.
    - Description input with min 10-character validation, token decoration, and helper guidance.
    - Immediate Safety Hazard toggle card with warning badge and adaptive switch.
  - **Step 2 — Photo Evidence (`EvidencePicker`):**
    - 3-photo maximum limit with status pill badge.
    - Add Photo card with camera / gallery action buttons.
    - Attached photo cards with thumbnails, source labels (Camera / Gallery), file name, replace bottom sheet, and remove action.
    - Photo preview dialog with metadata and clean close/replace/remove actions.
    - Non-destructive error recovery banners and permission request triggers via `CivicFixInfoBanner`.
  - **Step 3 — Location Selection (`LocationSelectionCard`):**
    - GPS auto-detection card with loading indicator and retry triggers.
    - Manual Map picker integration via `SelectLocationScreen`.
    - Confirmed location card with verified status badge, source tag (GPS / Map), street address, landmark, ward pill badge, coordinates, and accuracy tolerance.
    - Disabled service & permission denial banners via `CivicFixInfoBanner.warning`.
  - **Step 4 — Review & Submission (`ComplaintReviewCard`):**
    - Structured summary breakdown across Information, Evidence, Location, and Department Routing.
    - Individual "Edit" action hooks jumping directly back to corresponding wizard steps with input preservation.
    - Submission error banner via `CivicFixInfoBanner.error` mapping Firestore, Storage, and Network exceptions.
- **Form Layout & Actions:**
  - Responsive form shell constrained to 680px max width (`CivicFixBreakpoints.maxFormWidth`).
  - 28px circular step indicator (`ReportProgressIndicator`) with deep slate/gold active step dots and hairline connectors.
  - Persistent bottom action bar with `CivicFixOutlinedButton` ("Back") and `CivicFixButton` ("Next: Add Evidence", "Next: Location", "Next: Review", "Submit Issue" in Burnished Gold).
  - Unsaved changes protection via `DiscardReportDialog` (12px container radius).
- **Verification & Analysis:**
  - `flutter analyze` completed with **0 issues found** across the entire project.
  - All Phase 5 work completed in working tree without Git commit/push (strict rule adhered to).
  - Ready for Phase 6: Citizen Grievance Details & Tracking Redesign.

---

## UI/UX Redesign — Phase 6: My Complaints, Search, Filters & Status Browsing

- **Objective:** Redesign the Citizen My Complaints experience (`MyComplaintsScreen`, `ComplaintCard`, `ComplaintFilterBottomSheet`) into a fast, searchable, easily filterable, editorial browsing workspace following `DESIGN.md` (*Civic Precision — Editorial Minimalism*) while preserving 100% of underlying reactive data streams, offline synchronization logic, and upvoting workflows.
- **Page Foundation & Header:**
  - Standardized `MyComplaintsScreen` layout with responsive max-width containment (780px) and clean vertical spacing.
  - Added institutional header bar displaying supporting subtitle ("Track the civic issues you've reported.") and primary accent action ("+ Report Issue") in Burnished Gold (`#CA8A04`).
  - Integrated `OfflineCacheBanner` for seamless offline state indication.
- **Search Experience:**
  - Integrated `CivicFixSearchField` with instant client-side filtering across Ticket ID (`CF-2026-...`), Title, Category name, Street address, Landmark, and Ward.
  - Instant clear button and zero redundant network calls during keystrokes.
- **Status Filter System & Advanced Filtering:**
  - Implemented horizontal scrollable status filter bar with high-contrast pill chips (`CivicFixRadius.chipRadius`):
    - *All*, *Under Verification*, *Reported*, *Assigned*, *In Progress*, *Resolved*, *Closed*.
    - Active state: Deep slate `#0F172A` with white text; Inactive state: `#FFFFFF` with `#E2E8F0` border and `#0D1C2F` text.
  - Modernized `ComplaintFilterBottomSheet` modal with category selection chips, status filters, and sort options (*Recently Updated*, *Newest First*, *Oldest First*).
  - Dynamic result counter ("X complaints found") with "Clear all" link button.
- **Complaint Card Redesign (`ComplaintCard`):**
  - Pure white elevated surface (`#FFFFFF`), 1px hairline border (`#E2E8F0`), and 8px architectural radius (`CivicFixRadius.cardRadius`).
  - Top header row: Category pill with icon, copyable Ticket ID with feedback, sync status indicator (Pending Sync / Syncing / Sync Failed), and status badge (`StatusBadge`).
  - Middle body: Plus Jakarta Sans title, location row with pin icon, assigned personnel indicator (Field Officer / Supervising JE / Quality rework banner), and multi-photo thumbnail preview.
  - Footer row: Clock icon with relative updated time, safety hazard badge or interactive support/upvote counter, and chevron navigation affordance.
- **Empty, Loading & Error States:**
  - `CivicFixEmptyState`: "No complaints yet" (with Report Issue CTA) and "No complaints found" (with Clear Filters CTA).
  - `CivicFixLoadingState`: Institutional loading indicator.
  - `CivicFixErrorState`: Network/auth failure banner with retry action.
- **Verification & Analysis:**
  - `flutter analyze` completed with **0 issues found** across the entire project.
  - All Phase 6 work completed in working tree without Git commit/push (strict rule adhered to).
  - Ready for Phase 7: Citizen Grievance Details & Tracking Redesign.

---

## UI/UX Redesign — Phase 7: Complaint Details, Lifecycle Tracking & Transparency

- **Objective:** Complete redesign of the Citizen Complaint Details experience (`ComplaintDetailsScreen`, `ComplaintTracker`, `OfficersHandlingCard`, `ResolutionEvidenceCard`, `ReworkStatusCard`, `StatusHistoryTimeline`, `IssueInfoCard`, `LocationInfoCard`, `EvidenceGallery`, `ComplaintDetailsSkeleton`) following `DESIGN.md` (*Civic Precision — Editorial Minimalism*).
- **9-Zone Information Architecture:**
  1. **Zone 1: Identity & Header:**
     - Ticket ID pill (e.g., `#CF-2026-000401`) with one-tap copy action and floating snackbar confirmation.
     - Live status badge (`StatusBadge` / `CivicFixStatusChip`).
     - Category badge (with category icon and label).
     - Full issue headline with interactive support/upvote action button (live optimistic counter updates).
     - Network sync status indicator pills (Pending Sync, Syncing, Sync Failed with retry button).
  2. **Zone 2: Current Status Hero Card:**
     - Restrained, institutional hero card answering "Where is my complaint right now?", "Who is managing it?", and "What is the next expected milestone?".
     - Live state banners for active investigation, rework cycles, blocked on-hold states, and resolved completions (`✓ Issue Resolved`).
  3. **Zone 3: Lifecycle Progress Tracker (`ComplaintTracker`):**
     - Canonical 5-stage vertical progression: *Under Verification*, *Assigned*, *In Progress*, *Resolved*, *Closed*.
     - Distinct node states: Active (Burnished Gold / Alert border + glow), Completed (Deep Slate / Success checkmark), Pending (Hairline grey ring).
     - 2-Step Verification breakdown (AI Evidence Verification + Municipal Department Routing) with citizen-friendly fallback copy ("Manual Department Review") concealing raw Gemini/429/503 technical errors.
     - Interactive expandable stage explanation accordion on tap.
     - Verification retry action trigger when AI service is temporarily unavailable.
  4. **Zone 4: Issue Information (`IssueInfoCard`):**
     - Clean card with Category, Department, Description, Priority level pill, and Safety Hazard tag.
  5. **Zone 5: Location & Jurisdiction (`LocationInfoCard`):**
     - Verified street address, Ward jurisdiction, landmark, and interactive "View Location" map navigation trigger.
  6. **Zone 6: Assigned Municipal Team (`OfficersHandlingCard`):**
     - Institutional separation between Supervising Junior Engineer (Ward oversight) and Field Execution Officer (Ground crew repair).
     - Progressive execution states: *Pending Field Allocation*, *Assigned for Field Work*, *Work In Progress* (with start timestamp), *Temporarily On Hold* (with ground obstacle reason), and *Work Completed*.
     - Zero leakage of civil servant PII (phone, email, credentials, raw auth tokens).
  7. **Zone 7: Resolution & Work Evidence (`ResolutionEvidenceCard` & `EvidenceGallery`):**
     - Side-by-side or clean stacked Before vs After comparative evidence preview.
     - Field Execution Officer completion remarks presented in stylized quote block.
     - Execution signoff metadata and resolution timestamp.
     - Interactive full-screen zoomable/swipeable `ImageViewerModal`.
  8. **Zone 8: Supervisory Quality Review / Rework (`ReworkStatusCard`):**
     - Displayed conditionally for reopened complaints (`isReopened == true` or `reopenCount > 0`).
     - Alert header with cycle tag (`Rework Cycle #N`), supervisory quality audit note, SLA preservation notice, and prior resolution evidence history accordion.
  9. **Zone 9: Activity Timeline (`StatusHistoryTimeline`):**
     - Chronological update history (newest first) with hairline connectors, semantic status nodes, and Inter timestamps.
- **Responsive Layout & Visual Tokens:**
  - Responsive containment constrained to 780px max width (`maxWidth: 780`) for tablet/desktop clarity.
  - Zero hardcoded color literals; strictly using centralized `CivicFixColors`, `CivicFixTypographyTokens`, `CivicFixSpacing`, and `CivicFixRadius`.
- **Verification & Analysis:**
---

## UI/UX Redesign — Phase 8: Government Portal Dashboard, Navigation & Command Center

- **Objective:** Redesign the central Government Portal layout shell, global navigation, top application header, KPI card system, and role-aware command dashboards according to `DESIGN (2).md` (*Civic Precision — Editorial Minimalism*).
- **Core Architecture & Standardized Components:**
  1. **Government App Shell (`GovernmentAppShell` & `GovtShellScreen`):**
     - Responsive shell supporting Desktop persistent sidebar (260px), Tablet collapsed rail (72px), and Mobile off-canvas drawer.
     - Maximum content width containment (`1440px`), smooth transitions, and preserved state management.
  2. **Authoritative Sidebar Navigation (`GovtSidebar`):**
     - Deep slate foundation (`#0F172A`), burnished gold indicator & active icon treatment (`#CA8A04`), white active typography, subtle hover highlights (`CivicFixColors.sidebarItemHover`), and tokenized divider lines.
     - Role & profile card displaying officer initials, name, and municipal department without leaking sensitive PII.
     - Destructive session sign-out action with standard confirmation dialog.
  3. **Operational Top Navigation Header (`GovtAppBar` & `GovernmentPageHeader`):**
     - Live breadcrumb hierarchy trail (`GovtBreadcrumbs`), page title, jurisdiction tags (`GovtJurisdictionBadge`), and role badges (`GovtRoleBadge`).
     - Real-time notification bell with counter badge and compact profile menu.
  4. **Standardized KPI & Metric Card System (`GovernmentKpiCard`, `StatCard`, `GovtCard`):**
     - High-density, scannable metric tiles with Plus Jakarta Sans display typography (`26px`/`24px`), semantic icon container, percentage trend pills (`GovtThemeTokens.successLight` / `GovtThemeTokens.errorLight`), and loading skeleton states (`GovtKpiSkeleton`).
  5. **Role-Aware Command Center Dashboards:**
     - **Super Admin (`CityCommandCenterScreen`):** Executive 6-zone citywide oversight across all 7 zones, 24 wards, 18 departments, and 432 operational units with multi-criteria filtering and urgent alert center.
     - **Zonal DMC (`ZoneCommandCenterScreen`):** Supervisory command center with zonal ward isolation, department-ward cross-tabulation matrix, and supervisory escalation triggers.
     - **Central HOD (`DepartmentCommandCenterScreen`):** Technical department command center spanning 24 ward units, department-wide SLA breaches, inter-department routing, and technician crew allocation.
     - **Ward Officer (`WardCommandCenterScreen`):** Administrative ward command center overseeing all 18 departments within the ward, routing request adjudication (approve/reject), and emergency complaints register.
     - **Ward Department Lead (`DepartmentOperationsScreen`):** Operational unit dispatch with crew workload management, 48-hour SLA tracking, return-for-rework workflow, and **Manual Department Review** fallback queue for complaints received during temporary Gemini AI unavailability.
     - **Crew Field Operations (`CrewFieldOperationsScreen`):** Streamlined mobile/desktop view for ground technicians to start work, flag obstacles, and submit completion evidence.
- **Design System & Zero Hardcoded Colors:**
  - Tokenized all Government UI colors into `CivicFixColors` (including `sidebarBackground`, `sidebarSurface`, `sidebarDivider`, `roleSuperAdmin`, `roleZonalDmc`, `roleCentralHod`, `roleWardOfficer`, `roleWardLead`, `roleCrew`, `jurisdictionZone`, `jurisdictionWard`, `jurisdictionDept`).
  - Bridged all tokens cleanly via `GovtThemeTokens` and `GovtTypography`.
  - Zero hardcoded hex literals (`Color(...)`, `Colors.*`) remaining in government navigation and command components.
- **Verification & Analysis:**
  - `flutter analyze` passed with **0 issues found** (clean baseline maintained).
  - Preserved all Firestore security rules, auth role guards, and backend query boundaries.
  - Strict non-commit rule adhered to (no git commit or push performed).

---

## Execution Officer Assignment ID Mismatch Fix

- **Objective:** Diagnose and eliminate `Invalid argument(s): Complaint not found for ID: <id>` encountered when assigning an Execution Officer / Field Officer to a complaint in the Government portal.
- **Root Cause Analysis:**
  1. `ComplaintRoutingService._getComplaint(id)` was checking only the transient in-memory map `_complaintsCache`. It lacked fallback parsing for Firestore query results (contained an unpopulated comment stub) and did not consult `GovtComplaintRepository`.
  2. When `ComplaintRoutingService()` was instantiated with zero arguments (in `CrewFieldOperationsScreen` or `GovtComplaintDetailsScreen`), `_firestore` defaulted to null and was never connected to `FirebaseFirestore.instance` or `RepositoryLocator.govtComplaintRepository`.
  3. Dialog handlers (`_openExecutionOfficerAssignment` and `_handleAssignFieldOfficer`) did not pre-register active complaint instances into `ComplaintRoutingService`, creating a race condition / miss when fetching complaints.
  4. User-facing exception presentation displayed raw Dart stack strings instead of clear guidance.
- **Key Architectural & Code Changes:**
  - **`ComplaintRoutingService` (`lib/core/services/complaint_routing_service.dart`):**
    - Added `GovtComplaintRepository? _complaintRepo` to constructor and `_effectiveComplaintRepo` getter defaulting to `RepositoryLocator.govtComplaintRepository`.
    - Added `_effectiveFirestore` getter falling back automatically to `FirebaseFirestore.instance` when `RepositoryLocator.isFirebaseReady`.
    - Rewrote `_getComplaint(id)` to execute a multi-tier lookup:
      1. Trim and validate input ID.
      2. Check `_complaintsCache` by key and by value fields (`id`, `ticketNumber`, `serverId`, `localId`).
      3. Query `_effectiveComplaintRepo.getComplaintById(cleanId)` (checks local Hive & repo cache).
      4. Query Firestore `doc(cleanId).get()` via `ComplaintFirestoreMapper.fromFirestore`.
      5. Fallback query Firestore with `where('ticketNumber', isEqualTo: cleanId)` and `where('localId', isEqualTo: cleanId)`.
      6. Proper security error isolation: If Firestore returns `permission-denied`, throw `StateError` instead of misclassifying the grievance as missing.
    - Updated `assignFieldOfficer`, `reassignFieldOfficer`, and all routing/review/transfer mutation methods to use `_effectiveFirestore` and persist cache updates across `_effectiveComplaintRepo` and `_complaintsCache`.
  - **UI Screens & Pre-Registration:**
    - `CrewFieldOperationsScreen` (`lib/Govt UI/screens/dashboard/crew_field_operations_screen.dart`): Pre-registers `routing.registerComplaint(job.complaint)` and passes canonical `job.complaint.id`. Added `kDebugMode` logging.
    - `GovtComplaintDetailsScreen` (`lib/Govt UI/screens/complaints/govt_complaint_details_screen.dart`): Pre-registers `_routingService.registerComplaint(c)` and logs identity fields.
  - **Dialog Error Handling & Sanitization:**
    - `CrewFieldOfficerAssignmentDialog` (`lib/Govt UI/widgets/dashboard/sections/crew/crew_field_officer_assignment_dialog.dart`): Added debug logging and friendly error translation (`"Unable to load this complaint for assignment. Please refresh and try again."`).
    - `DepartmentLeadAssignDialog` (`lib/Govt UI/widgets/dashboard/sections/department_lead/department_lead_assign_dialog.dart`): Added matching debug logging and friendly error translation.
- **Verification & Analysis:**
  - `flutter analyze` completed with **0 issues found** across the entire project.
  - All 48 tests in `test/core/services/phase2_field_officer_execution_test.dart` passed.
  - All 28 tests in `test/govt_ui/phase8_crew_field_operations_test.dart` passed.
  - All tests in `test/govt_ui/phase8_crew_work_service_test.dart` passed.
  - Preserved all business invariants: JE != FO strict separation, unit boundary enforcement (1 Ward x 1 Department), SLA clock immutability, zero PII leakage, and Firestore security rules intact.
  - Strict non-commit rule adhered to (no git commit or push performed).

---

## Execution Officer Assignment Authorization Alignment Fix

- **Objective:** Fix the contradiction in the complaint assignment and execution workflow where the Complaint Details UI correctly displayed the assigned Field Execution Officer (e.g. Ganesh Kulkarni, `GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-02`, UID `rbQflILEPabot9t9EScfQmdmvn73`), but when Ganesh attempted to start work via "Start Job", the system threw: `Security Violation: Complaint <id> is not assigned to crew member GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-02`.
- **Root Cause Analysis:**
  1. **Dual-Assignment Mismatch:** The UI and workdesk query (`loadCrewWorkdesk`) checked `complaint.assignedFieldOfficerId`, whereas execution methods in `GovernmentCrewWorkService` (`startJob`, `submitWorkCompletion`, `resumeWorkAfterRework`, `reportBlockedIssue`) and `GovernmentComplaintVisibilityService.getPermittedActions` checked only `complaint.assignedCrewMemberId` (which holds the supervising Junior Engineer ID, e.g., `GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-01`).
  2. **Missing Work State Attributes on Start:** `GovernmentCrewWorkService.startJob` did not record `workStartedAt`, `workStartedBy: crewUser.employeeId`, and `routingStatus: inProgress`, leading to incomplete audit and state transitions.
  3. **ID vs Employee ID Alias Resolution:** `ComplaintRoutingService` matched only `user.employeeId` instead of supporting both `user.employeeId` and `user.id` (Firebase UID) aliases against `assignedFieldOfficerId`.
  4. **Unsanitized Error UX:** Raw `Bad state: Security Violation...` exception text was surfaced in snackbars rather than clean user-facing feedback (`"You are not assigned to this job."`).
- **Key Architectural & Code Changes:**
  - **`GovernmentAuthorizationService` (`lib/core/services/government_authorization_service.dart`):**
    - Enhanced `canStartFieldWork` and `canSubmitFieldResolution` and added `canReportFieldObstacle` and `canResumeFieldWork` to validate `complaint.assignedFieldOfficerId` against `user.employeeId` and `user.id` (Firebase UID).
    - Preserved fallback matching to `complaint.assignedCrewMemberId` / `assignedJuniorEngineerId` *only* when no separate Field Officer has been assigned yet.
    - Preserved strict Junior Engineer vs Field Officer separation: if `assignedFieldOfficerId` is set, only that Field Officer can start/execute the job.
  - **`GovernmentCrewWorkService` (`lib/Govt UI/services/government_crew_work_service.dart`):**
    - Updated `startJob`, `submitWorkCompletion`, `resumeWorkAfterRework`, and `reportBlockedIssue` to delegate authorization to `GovernmentAuthorizationService`.
    - Enhanced `startJob` to persist `workStartedAt: now`, `workStartedBy: crewUser.employeeId`, `routingStatus: inProgress`, and append a timeline event and audit log.
    - Updated `_getUser` fallback to avoid inheriting complaint assignment names.
  - **`GovernmentComplaintVisibilityService` (`lib/Govt UI/services/government_complaint_visibility_service.dart`):**
    - Updated `getPermittedActions` to use `_authService.canStartFieldWork` and `_authService.canAssignFieldOfficer`.
  - **`ComplaintRoutingService` (`lib/core/services/complaint_routing_service.dart`):**
    - Updated `startFieldWork`, `markFieldWorkBlocked`, and `resolveByFieldOfficer` to compare both `employeeId` and `id` (UID).
  - **`CrewFieldOperationsScreen` (`lib/Govt UI/screens/dashboard/crew_field_operations_screen.dart`):**
    - Sanitized user-facing error snackbars on authorization/security failures (`"You are not assigned to this job."`).
- **Verification & Testing:**
  - Added Section 6 to `test/govt_ui/phase8_crew_work_service_test.dart` covering Field Execution Officer assignment, Start Job authorization, Junior Engineer vs Field Officer separation, and obstacle/completion flows.
  - All 17 tests in `test/govt_ui/phase8_crew_work_service_test.dart` passing.
  - All 48 tests in `test/core/services/phase2_field_officer_execution_test.dart` passing.
  - All 15 tests in `test/govt_ui/phase8_crew_field_operations_test.dart` passing.
  - Strict non-commit rule adhered to (no git commit or push performed).

---

## Citizen Evidence Visibility Fix

- **Objective:** Fix the issue where citizen report evidence thumbnails/cards were visible in the Government Portal (Junior Engineer, Field Execution Officer, Ward Department Lead, and Complaint Details screens), but the actual uploaded grievance images failed to render and showed broken image placeholders.
- **Root Cause Analysis:**
  1. **Direct `Image.network` Bypass of Supabase Signed URL Service:** Government UI dialogs and sections (`CrewJobDetailDialog`, `DepartmentLeadComplaintDetailDialog`, `DepartmentLeadVerificationDialog`, `DepartmentLeadAwaitingVerificationSection`, `CrewAwaitingReviewSection`, `GovtHazardInfoCard`) passed raw Supabase storage paths (e.g. `CF-2026-1791368464448000-a32fe69cef8b/CF-2026-1791368464448000-a32fe69cef8b_evidence_01.jpg`) directly into `Image.network()`. Because the Supabase bucket `complaint-evidence` is strictly private and storage paths are not HTTP URLs, `Image.network()` threw a `UriFormatException` / `SocketException` and defaulted to broken image error placeholders.
  2. **Incomplete Multi-Stage Evidence Construction:** `GovtComplaintDetailsScreen._buildEvidenceItems` only iterated over `c.imageUrls` and completely omitted Field Officer Before-Work photos (`c.beforeWorkPhoto`), After-Work resolution photos (`c.afterWorkPhoto`), and archived rework cycle evidence (`c.previousResolutionEvidence`).
  3. **Verification Dialog Evidence Field Indexing Error:** `DepartmentLeadVerificationDialog` hardcoded `c.imageUrls[1]` as the after-work photo instead of checking canonical `c.afterWorkPhoto`.
  4. **Strict Deserialization of Schema Variations:** `ComplaintFirestoreMapper.fromFirestore` assumed `data['imageUrls']` was always a non-null `List`, throwing or ignoring complaints if evidence was stored under legacy/alternative keys (`evidenceUrls`, `photoUrls`, `evidencePaths`, `citizenEvidence`, `attachments`, `initialEvidence`, `beforeEvidence`, `evidence`) or as structured object maps.
  5. **Lack of User-Facing Error Boundaries & Retry:** `SupabaseEvidenceImage` lacked retry mechanisms for transient network/signed URL generation issues and did not emit diagnostic debug logs in `kDebugMode`.
- **Key Architectural & Code Changes:**
  - **`FirestoreMapperHelpers` (`lib/core/firebase/mappers/firestore_mapper_helpers.dart`):**
    - Added `parseImageUrls`, `parseBeforeWorkPhoto`, `parseAfterWorkPhoto`, and `parsePreviousResolutionEvidence` supporting canonical and all legacy/alternative evidence fields, structured maps, and string entries.
  - **`ComplaintFirestoreMapper` (`lib/core/firebase/mappers/complaint_firestore_mapper.dart`):**
    - Updated `fromFirestore` to use the robust `FirestoreMapperHelpers` parsers across all evidence fields.
  - **`SupabaseEvidenceImage` (`lib/core/widgets/supabase_evidence_image.dart`):**
    - Converted to stateful widget with tap-to-retry capability, structured error fallbacks, and rich `kDebugMode` diagnostic logging distinguishing missing paths, signed URL generation errors, and image decode/network failures.
  - **`GovernmentEvidenceGallery` (`lib/Govt UI/widgets/complaints/shared/government_evidence_gallery.dart`) & UI Screens:**
    - Standardized evidence display in `CrewJobDetailDialog` and `DepartmentLeadComplaintDetailDialog` using `GovernmentEvidenceGallery` with interactive full-screen viewer modal.
    - Updated `DepartmentLeadVerificationDialog`, `DepartmentLeadAwaitingVerificationSection`, `CrewAwaitingReviewSection`, `CrewEvidenceSubmissionDialog`, and `GovtHazardInfoCard` to use `SupabaseEvidenceImage` with full private Supabase signed URL resolution.
  - **`GovtComplaintDetailsScreen` (`lib/Govt UI/screens/complaints/govt_complaint_details_screen.dart`):**
    - Updated `_buildEvidenceItems` to assemble the full multi-stage lifecycle: Citizen Evidence, Field Inspection (Before Work), Resolution Evidence (After Work), and Previous Resolution Cycles.
- **Verification & Analysis:**
  - `flutter analyze` passed with **0 issues found**.
  - All 6 tests in `test/core/storage/supabase_evidence_storage_service_test.dart` passed.
  - All 12 tests in `test/govt_ui/phase9_shared_complaint_operations_test.dart` passed.
  - All 17 tests in `test/govt_ui/phase8_crew_work_service_test.dart` passed.
  - All 15 tests in `test/govt_ui/phase8_crew_field_operations_test.dart` passed.
  - All 48 tests in `test/core/services/phase2_field_officer_execution_test.dart` passed.
  - Strict non-commit rule adhered to (no git commit or push performed).

---

## Chatbot Rollout — Phase 1

- **Current Chatbot Architecture:**
  - **Screen & UI:** `AssistantScreen` (`User UI/screens/assistant_screen.dart`) managed via `StatefulWidget` with in-memory `List<AssistantMessage>`.
  - **Widgets:** `AssistantMessageBubble` (`User UI/widgets/assistant/assistant_message_bubble.dart`) and `HomeAssistantBanner` (`User UI/widgets/home_assistant_banner.dart` on Home Screen Zone 8).
  - **Service:** `CivicAssistantService` (`User UI/services/assistant_service.dart`).
  - **Models:** `AssistantMessage` and `AssistantMessageSender` (`core/models/assistant_message_model.dart`).
- **AI Provider & Model:**
  - Citizen Chatbot is currently a **mock / rule-based keyword matcher** running locally in Dart.
  - No active LLM or Gemini API call is hooked into `assistant_service.dart`.
  - Zero client-side API key exposure.
- **Current Prompt Strategy:**
  - Static template `generateLanguageSystemPrompt` exists in `assistant_service.dart` with 8 municipal glossary translations, but is **currently unused** at runtime.
- **Knowledge Sources:**
  - Exactly 12 hardcoded canned `CivicIntentResponse` items in Dart code.
  - RAG / Vector Retrieval / Firestore retrieval is **completely absent**.
- **Conversation Memory Behavior:**
  - **Missing**. 0 previous messages passed into processing (single-turn query execution only).
  - History is lost upon exiting `AssistantScreen`.
- **App Context Behavior:**
  - **Missing**. No user role, ticket ID, complaint status, or live municipal data is injected into queries.
- **Casual Conversation Baseline:**
  - **Missing**. 100% of casual greetings (`Hello`, `Hi`, `How are you?`) fail into the generic fallback message.
- **Multilingual Baseline:**
  - **Partial**. Canned responses for the 12 intents exist for `en`, `hi`, and `mr`.
  - Natural NLU, transliteration, and code-mixed queries fail into fallback.
- **Security Findings:**
  - **Safe**. No secrets, API keys, government credentials, or PII exposed.
- **Major Limitations:**
  - Keyword substring collision (e.g. asking "What happens after I submit a complaint?" triggers instructions on how to submit a complaint due to matching "submit").
  - Rigid brittle keywords prevent answering variations like "Under Verification" or "How does the map work?".
  - Lacks rich markdown formatting, TTS voice, copy action, and retry logic.
- **Phase 2 Readiness:**
  - **Ready**. Audit completed, baseline documented, and architecture mapped for safe Phase 2 implementation.

---

## Chatbot Rollout — Phase 2: Conversational Personality, Intent Routing & Prompt Foundation

- **Conversational Architecture & Refactoring:**
  - Decoupled assistant logic into a layered, modular architecture:
    - **Models (`lib/core/assistant/models/`):** `CivicAssistantIntent` (8 intent classes), `AssistantIntentResult`, `AssistantAppContext` (decoupled interface for role, screen, ticket ID), `AssistantRagContext` (decoupled placeholder for retrieved knowledge snippets), `AssistantConversationHistory` (bounded sliding-window memory).
    - **Config & Personality (`lib/core/assistant/config/`):** `CivicAssistantPersonality` (identity, tone, boundaries), `CivicAssistantPromptBuilder` (structured 5-tier prompt assembler: System instructions, Verified Knowledge, Dynamic RAG snippets, Session history, Active query).
    - **Intent Routing (`lib/core/assistant/routing/`):** `CivicAssistantIntentRouter` replacing brittle single-keyword matching with semantic multi-token pattern analysis and multi-turn contextual follow-up resolution.
    - **Verified Knowledge Base (`lib/core/assistant/knowledge/`):** `CivicAssistantKnowledge` containing authoritative descriptions of 24 BMC Wards, 18 Departments, 5-stage SLA lifecycle, Junior Engineer vs Field Execution Officer roles, photo evidence rules, and reopen rework policies.
    - **Engine & Providers (`lib/core/assistant/services/`):** `CivicAssistantConversationEngine`, `GroundedCivicAssistantProvider` (zero-latency deterministic local provider), `CompositeCivicAssistantProvider` (intelligent routing + error boundary), `CivicAssistantController` (session lifecycle, retry, clear).
    - **Service & UI:** Refactored `CivicAssistantService` and updated `AssistantScreen` to maintain in-session context, handle retries, and preserve Civic Precision UI styling.
- **Intent Classes (8 Categories):**
  1. `CASUAL_GREETING`: Natural friendly greetings ("Hello", "Hi", "Good morning", "Namaste") without forcing immediate complaint menus.
  2. `CASUAL_SMALL_TALK`: Conversational queries ("How are you?", "What are you doing?", "Who are you?", "Thank you", "Bye").
  3. `CIVICFIX_GENERAL`: Platform overview ("What is CivicFix?", "What does this app do?").
  4. `CIVICFIX_PROCESS`: Workflow & post-submission stages ("What happens after I submit a complaint?", "What does Under Verification mean?", "Who handles my complaint?").
  5. `CIVICFIX_HELP`: Actionable reporting and editing guidance ("How do I report a pothole?", "Can I edit a complaint after submitting it?").
  6. `CIVICFIX_NAVIGATION`: In-app finding ("Where can I see my complaints?", "How does the map work?").
  7. `OUT_OF_SCOPE_GENERAL`: Harmless general conversation ("Tell me a joke", "Capital of Japan") answered pleasantly with a gentle return to CivicFix.
  8. `UNKNOWN`: Grounded, polite fallback ("I don't have enough verified CivicFix information to answer that accurately yet.").
- **Keyword Collision Elimination:**
  - Eliminated naive substring matching on `"submit"`.
  - Asking *"What happens after I submit a complaint?"* correctly routes to `CIVICFIX_PROCESS` and returns the 5-stage workflow instead of reporting instructions.
  - Asking *"Can I edit a complaint after submitting it?"* correctly routes to `CIVICFIX_HELP` and explains audit immutability rules.
- **Session Memory & Context Window:**
  - `AssistantConversationHistory` maintains a bounded sliding window (default 10 messages) avoiding unbounded memory/token growth.
  - Multi-turn understanding: If the user states *"My complaint is under verification"* and asks *"What happens next?"*, the assistant correctly contextually resolves Stage 3 (Assignment to Junior Engineer & Field Officer).
- **Prompt Architecture & RAG Readiness:**
  - `CivicAssistantPromptBuilder` cleanly separates System instructions, Verified domain knowledge, RAG retrieved snippets, App context, Session history, and User query.
  - Ready for vector search / dynamic chunk retrieval in Phase 3 without code refactoring.
- **Error & Failure Handling:**
  - Sanitized user-facing error state ("I'm having trouble responding right now. Please try again.") with tap-to-retry capability.
  - Zero raw provider errors, HTTP codes, or stack traces exposed to citizens.
- **Verification & Analysis (Phase 2):**
  - `flutter analyze` passed with **0 issues found** across the entire project.
  - All 18 unit and widget tests in `test/core/assistant/` passing (100% success).

### 11. Chatbot Rollout — Phase 3: Authoritative CivicFix Knowledge Base (Completed)
- **Objective Achieved:** Built a comprehensive, modular, canonical knowledge repository for the CivicFix citizen chatbot, establishing a trusted single source of truth across all 18 BMC departments, 24 Wards, 6 administrative roles, 5-stage lifecycle, evidence rules, SLAs, and troubleshooting workflows.
- **Knowledge Architecture (`lib/core/assistant/knowledge/`):**
  - `KnowledgeEntry` data model (`knowledge_entry.dart`): Strongly typed entry schema with `id`, `title`, `topic`, `audience`, `tags`, `canonicalContent`, `relatedTopics`, and `sourceReference`.
  - `civicfix_overview_knowledge.dart`: Platform overview, citizen/government dual features, and BMC/MCGM governance.
  - `citizen_workflows_knowledge.dart`: 4-step reporting workflow, 5-stage live tracking, Civic Points gamification, and community upvoting.
  - `complaint_lifecycle_knowledge.dart`: 5-stage lifecycle (Reported -> Under Verification -> Assigned -> In Progress -> Resolved) and supervisory Quality Review.
  - `complaint_statuses_knowledge.dart`: Clear definitions for `reported`, `underVerification`, `assigned`, `inProgress`, `resolved`, `closed`, `blocked`, and `reopened`.
  - `complaint_categories_knowledge.dart`: Citizen grievance categories mapped to responsible municipal departments.
  - `departments_knowledge.dart`: Exactly 18 canonical BMC departments with verified system codes (`maintenance_roads`, `water_works`, `solid_waste_management`, `building_factory`, `garden_trees`, `public_health`, `pest_control_insecticide`, `encroachment`, `licence`, `shops_establishments`, `assessment_collection`, `estate`, `colony_slum`, `education_schools`, `security`, `legal`, `administration_establishment`, `town_planning_development_plan`).
  - `wards_knowledge.dart`: Exactly 24 canonical BMC Wards (A, B, C, D, E, F/North, F/South, G/North, G/South, H/East, H/West, K/East, K/West, L, M/East, M/West, N, P/North, P/South, R/Central, R/North, R/South, S, T) covering Island City, Western Suburbs, and Eastern Suburbs.
  - `government_roles_knowledge.dart`: 6-tier administrative hierarchy + dual-role operational invariant (`assignedJuniorEngineerId != assignedFieldOfficerId`).
  - `evidence_rules_knowledge.dart`: Up to 3 citizen photos, mandatory After-Work photo before resolution, previous resolution preservation on rework, private storage + signed URLs.
  - `assignment_workflow_knowledge.dart`: Ward × Department scoping, least-loaded Junior Engineer allocation, Field squad dispatch.
  - `field_execution_knowledge.dart`: Start Work action, physical obstacle logging & resumption, completion evidence.
  - `resolution_rework_knowledge.dart`: Supervisory quality review window, reopen workflow, and continuous SLA preservation.
  - `sla_rules_knowledge.dart`: SLA starts immediately at Stage 1 (Reported); continuous and immutable across reassignments, obstacle periods, and reworks.
  - `verification_workflow_knowledge.dart`: 2-Stage verification pipeline + graceful fallback to Ward Lead manual review.
  - `map_gis_knowledge.dart`: MapLibre GL raster/vector basemaps, color-coded hazard markers, clustering, radius filters.
  - `account_help_knowledge.dart`: Phone OTP sign-in, profile management, PII privacy protection.
  - `faq_knowledge.dart`: 19+ curated canonical FAQs covering all common citizen support questions.
  - `troubleshooting_knowledge.dart`: Offline queue & sync pending, GPS troubleshooting, upload recovery, delayed ticket escalation.
  - `civic_assistant_knowledge.dart`: Central aggregator with fast ID lookup, topic filtering, multi-field search ranking, consolidated prompt generator, and strict hallucination boundary enforcement.
- **Verification & Analysis (Phase 3):**
  - `flutter analyze`: **0 issues found** across the entire project.
  - `flutter test test/core/assistant/`: **30/30 tests passed** (100% success rate).
### 12. Chatbot Rollout — Phase 4: RAG Retrieval Engine & Knowledge Grounding (Completed)
- **Objective Achieved:** Built a dedicated, intent-aware, hybrid RAG (Retrieval-Augmented Generation) retrieval engine that dynamically queries, scores, and injects top-K verified knowledge chunks into prompt context while enforcing confidence thresholds, related topic expansion, casual bypass, and strict hallucination boundaries.
- **Dedicated Retrieval Architecture (`lib/core/assistant/retrieval/`):**
  - `retrieval_models.dart`:
    - `AssistantRetrievalConfig`: Configurable parameters (`maxResults = 5`, `minScoreThreshold = 15.0`, `includeRelated = true`, `maxRelatedExpansion = 2`, `debugMode = false`).
    - `AssistantRetrievedChunk`: Strongly typed retrieved knowledge unit (`id`, `title`, `topic`, `content`, `score`, `matchReason`, `sourceReference`, `relatedTopics`).
    - `AssistantRetrievalRequest`: Input query, intent classification, session history, and retrieval configuration.
    - `AssistantRetrievalResult`: Ranked chunks, query metadata, topScore, execution latency, diagnostics, and bypass flags.
  - `query_normalizer.dart`:
    - `cleanText`: Punctuation normalization preserving ward slashes (e.g. `f/north`, `k/west`) and hyphens.
    - `extractTokens`: Stop word filtering removing non-discriminative English stop words.
    - `getExpandedTokenSet`: Domain synonym and acronym expansion (`je` -> junior engineer dispatcher, `fo` -> field officer execution squad, `ee` -> ward lead executive engineer, `swm` -> solid waste management garbage, `pothole` -> maintenance_roads, `tat/sla` -> turnaround timeline, `reopen` -> rework quality audit, `offline` -> sync pending queue, `gps` -> map coordinates, `report/issue/photo/resolution/repair/closed`).
  - `assistant_rag_retriever.dart`:
    - `AssistantRagRetriever`: Abstract interface defining `retrieve(AssistantRetrievalRequest)`.
    - `AssistantSemanticRetriever`: Future-ready vector embedding interface for dense vector retrieval.
  - `civic_assistant_hybrid_retriever.dart`:
    - Singleton hybrid retriever implementing multi-factor scoring:
      - Exact ID match (+100.0)
      - Word-bounded Ward & Department code matching (+80.0)
      - Exact/partial title phrase & token match (+20.0 to +80.0)
      - Exact/partial tag match (+15.0 to +50.0)
      - Canonical content match (capped at +30.0)
      - Intent-aware topic boost (+25.0 for process/help/navigation topics)
    - Zero-leakage Casual Bypass: Automatically skips retrieval for `CASUAL_GREETING`, `CASUAL_SMALL_TALK`, and `OUT_OF_SCOPE_GENERAL` (0ms retrieval overhead).
    - Multi-turn contextual resolution: Extracts context tokens from previous conversational turns to accurately retrieve knowledge for follow-ups (e.g. "What happens next?").
    - Bounded related topic expansion: Expands up to `maxRelatedExpansion` related chunks from top hits without exceeding `maxResults`.
- **Grounding & Prompt Integration (`lib/core/assistant/`):**
  - `AssistantRagContext`: Upgraded to support `AssistantRetrievedChunk` instances, `fromRetrievalResult()`, and formatted prompt chunks.
  - `CivicAssistantPromptBuilder`: Injects compact retrieved knowledge chunks in Section 2 under `=== VERIFIED CIVICFIX DOCUMENTATION (RETRIEVED KNOWLEDGE) ===` instead of loading the monolithic knowledge base.
  - `GroundedCivicAssistantProvider` & `CompositeCivicAssistantProvider`: Fully wired to use the hybrid RAG pipeline with sub-millisecond local retrieval execution.
- **Verification & Quality:**
  - `flutter test test/core/assistant/`: **52/52 tests passing (100%)** across all 4 test suites (`assistant_screen_widget_test.dart`, `civic_assistant_foundation_test.dart`, `civic_assistant_knowledge_test.dart`, `civic_assistant_rag_retriever_test.dart`).
  - `flutter analyze`: Clean static analysis (0 issues).
  - Strict compliance with non-commit and non-push constraints.

### 13. Chatbot Rollout — Phase 5: Live App Context, Complaint-Aware Responses & Safe Personalization (Completed)
- **Objective Achieved:** Equipped the CivicFix citizen assistant with safe, real-time application and complaint context (`AssistantAppContext`, `ComplaintToAssistantContextMapper`, screen awareness, lifecycle status awareness, obstacle/rework/sync awareness) while maintaining strict zero-PII privacy, read-only safety, hybrid RAG grounding, and zero regression on casual conversation.
- **Context Modeling & Privacy Architecture (`lib/core/assistant/models/assistant_app_context.dart`):**
  - Strongly typed `AssistantAppContext` supporting:
    - User/Screen context: `userRole`, `currentScreen`, `reportStep`, `selectedMapFeatureType`.
    - Sanitized Complaint context: `selectedComplaintId`, `selectedTicketNumber`, `complaintStatus`, `complaintCategory`, `wardId`, `departmentId`, `verificationStage`, `hasJuniorEngineerAssigned`, `assignedJuniorEngineerName`, `hasFieldOfficerAssigned`, `assignedFieldOfficerName`, `isBlocked`, `blockedReason`, `reopenCount`, `reopenReason`, `syncState`.
    - Computed getters: `hasComplaintContext`, `ticketId`, `isUnderVerification`, `isAssigned`, `isInProgress`, `isResolved`, `isClosed`, `isOfflinePending`.
  - Zero-PII Strict Allowlist: Excludes phone numbers, emails, passwords, OTPs, Firebase UIDs, civil servant credentials, and private storage evidence URLs.
  - Read-Only Security Invariant: Model is strictly informational with zero ability to mutate Firestore state, approve complaints, change statuses, or reassign officers.
- **In-Memory Complaint Mapper (`lib/core/assistant/adapters/complaint_context_mapper.dart`):**
  - `ComplaintToAssistantContextMapper`: Pure functional adapter converting active in-memory `ComplaintModel` to sanitized `AssistantAppContext`.
  - Zero redundant Firestore re-queries; leverages existing state from `ComplaintDetailScreen` or `HomeScreen`.
- **RAG Retriever Context Expansion (`lib/core/assistant/retrieval/civic_assistant_hybrid_retriever.dart`):**
  - Incorporates `AssistantAppContext` into `AssistantRetrievalRequest`.
  - Dynamically extracts context tokens (status, category, ward, department, obstacle, rework, sync state) for retrieval scoring boosts (+30.0 for matching status/process entries).
- **Prompt Grounding & Contradiction Protection (`lib/core/assistant/config/civic_assistant_prompt.dart` & `civic_assistant_conversation_engine.dart`):**
  - Section 5 of Prompt Builder formats `=== CURRENT CIVICFIX APP CONTEXT ===` with explicit read-only instructions and ticket details.
  - State Contradiction Guard: Prevents citizen misconceptions (e.g. citizen asking "Why is my complaint closed?" when status is inProgress/underVerification) by clarifying actual active lifecycle stage.
- **Controller & UI Session Context (`lib/core/assistant/controller/civic_assistant_controller.dart` & `assistant_screen.dart`):**
  - `CivicAssistantController` supports `updateComplaintContext()` and `clearComplaintContext()`.
  - `AssistantScreen` accepts optional `initialContext` and preserves context across multi-turn sessions without leaks.
### 14. Chatbot Rollout — Phase 6: English, Hindi & Marathi Multilingual Conversation (Completed)
- **Objective Achieved:** Equipped the CivicFix citizen assistant with natural, symmetrical multilingual capabilities across English (`en`), Hindi (`hi`), and Marathi (`mr`). The assistant understands native Devanagari script, Romanized transliterations (Hinglish/Marathlish), and English queries, while preserving a single canonical authoritative knowledge base, parity across RAG retrieval, safe live app context, zero PII, and strict read-only boundaries.
- **Multilingual Language Modeling & Resolution (`lib/core/assistant/models/assistant_language.dart` & `lib/core/assistant/services/assistant_language_resolver.dart`):**
  - Strongly typed `AssistantLanguage` enum (`english`, `hindi`, `marathi`) with `code`, `displayName`, `nativeName`, `isDevanagari`, `localeTag`, and helper parsing.
  - Priority-based `AssistantLanguageResolver`:
    1. Explicit language request in query ("Explain in Hindi", "मराठीत सांगा").
    2. Devanagari script and lexical keyword analysis (`_marathiKeywords`, `_hindiKeywords`, morphological endings).
    3. Transliterated Romanized markers (`_hinglishMarkers`, `_marathlishMarkers`).
    4. Multi-turn session history continuity.
    5. Caller requested language / Active app locale (`AssistantAppContext.selectedLanguage`).
    6. English default fallback.
- **Domain Lexicon & RAG Retrieval Bridge (`lib/core/assistant/knowledge/civic_assistant_lexicon.dart` & `lib/core/assistant/retrieval/query_normalizer.dart`):**
  - Centralized `CivicAssistantLexicon` with `_canonicalDisplayTerms` and `_multilingualTokenBridge` mapping Devanagari and Romanized vocabulary to canonical English search tokens.
  - `QueryNormalizer`: Unicode preservation for Devanagari range (`\u0900-\u097F`) during text cleaning; expansion with `CivicAssistantLexicon.getCanonicalBridgeTokens()` for retrieval parity across all 3 languages without duplicate knowledge files.
- **Multilingual Intent Routing (`lib/core/assistant/routing/civic_assistant_intent_router.dart`):**
  - Intent classification regex patterns expanded to support English, Devanagari Hindi, Devanagari Marathi, Hinglish, and Marathlish for casual greetings, small talk, process, help, navigation, general, out of scope, and contextual follow-ups.
- **Multilingual Conversational Engine (`lib/core/assistant/services/civic_assistant_conversation_engine.dart`):**
  - Response generators across all intent categories with natural phrasing in `en`, `hi`, and `mr`.
  - State Contradiction Guard localized in all three languages.
  - Live Complaint Context explanation localized in `en`, `hi`, and `mr` while preserving canonical Ticket Numbers (`CF-2026-000042`, `MCGM-2026-9901`), Ward Codes (`K/West`, `R/South`), and Officer Names (`Ganesh Kulkarni`, `Ramesh Patil`) untouched.
  - Localized Strict Hallucination Boundary responses in English, Hindi, and Marathi.
- **Controller & UI Session Context (`lib/core/assistant/controller/civic_assistant_controller.dart` & `civic_assistant_provider.dart`):**
  - Dynamic language resolution on user message with language state update and UI notification.
  - `AssistantScreen`: Localized welcome greetings, prompt suggestions, and empty state guidance dynamically responding to app locale.
- **Verification & Testing (Phase 6):**
  - `flutter test test/core/assistant/`: **104/104 tests passing (100% success rate)** across all 6 test suites (`civic_assistant_multilingual_test.dart` [28 tests], `civic_assistant_app_context_test.dart`, `civic_assistant_rag_retriever_test.dart`, `civic_assistant_foundation_test.dart`, `civic_assistant_knowledge_test.dart`, `assistant_screen_widget_test.dart`).
### 15. Chatbot Rollout — Phase 7: Quality Evaluation, Hallucination Hardening & Production Reliability (Completed)
- **Objective Achieved:** Established a formal automated evaluation framework and production reliability hardening suite for the CivicFix Chatbot. Hardened against prompt injection, sensitive data extraction (Firebase UIDs, tokens, OTPs, storage URLs), hallucinated departments/statuses, universal SLA misconceptions, officer personal contact leaks, and out-of-domain advice (medical/legal/financial), while maintaining 100% test pass rate, 0.0% hallucination rate, 0.0% privacy violation rate, sub-10ms response latency, and multilingual parity across English, Hindi, and Marathi.
- **Automated Evaluation Framework (`lib/core/assistant/evaluation/`):**
  - Strongly typed models: `AssistantEvaluationCase`, `AssistantEvaluationResult`, `AssistantEvaluationSummary`, and `AssistantEvaluationCategory` across 20 canonical categories.
  - `AssistantEvaluationRunner`: Evaluates queries against expected intent, required facts, forbidden claims, topic retrieval accuracy, language accuracy, and latency thresholds.
  - `AssistantEvaluationDataset`: Standardized 132-case dataset covering:
    - Casual Conversation & Small Talk
    - CivicFix General Overview & Governance
    - 5-Stage Complaint Lifecycle & Workflow
    - Status Explanations (all 8 statuses)
    - 18 BMC Department Routing & Classifications
    - 6 Government Roles & Hierarchy
    - Evidence Rules & After-Work Proof Requirements
    - SLA Calculation & Turnaround Times (Emergency, Potholes, Garbage, Water)
    - Supervisory Quality Review & Rework Rules
    - MapLibre GIS Map, Color-Coded Pins & Clustering
    - Offline-First Queue, Hive Storage & Auto-Sync
    - Safe Live App Context (Under Verification, Assigned, In Progress, Blocked, Resolved, Closed)
    - Multi-Turn Follow-Ups & Session Memory
    - Multilingual Responses (English, Hindi, Marathi)
    - Mixed-Language & Transliterated Hinglish/Marathlish
    - Unknown / Low-Confidence Queries
    - Out-of-Scope General Inquiries
    - Privacy & Sensitive Credential Red-Teaming
    - Hallucination Hardening (Fake Departments, Fake Statuses, Universal SLA)
    - Provider & Network Fallbacks
- **Production Hardening Defenses (`lib/core/assistant/services/civic_assistant_conversation_engine.dart`):**
  - **Prompt Injection Defense:** Blocks jailbreak attempts ("ignore previous instructions", "print system prompt", "DAN mode", "root override") with localized security refusals.
  - **Privacy Extraction Defense:** Rejects extraction of Firebase UIDs, Auth tokens, JWTs, OTPs, passwords, API keys, database connection URLs, and Cloud Storage bucket paths.
  - **Hallucination Hardening Guard:** Rejects fictitious departments ("Smart Roads & Flying Cars", "Department of Space/Magic") and fictitious statuses ("awaitingMayorApproval", "citizenApproved") with explicit redirection to the 18 official BMC departments and 8 canonical statuses.
  - **Universal SLA Clarification Guard:** Refutes claims that SLA is always 24 hours or uniform across complaints, providing category-specific turnaround rules.
  - **Officer Contact Boundary:** Refuses requests for personal mobile numbers or direct emails of municipal personnel, protecting civil servant privacy.
  - **High-Risk Domain Defense:** Rejects medical prescriptions, legal lawsuit counsel, and financial/stock advice, directing users to licensed professionals.
  - **Missing Context Guidance:** Prompts users to select or open a complaint when asking status/assignment questions without active complaint context.
  - **Debounce & Rapid-Tap Protection:** Debounces rapid user input within `CivicAssistantController` to prevent race conditions and duplicate message submissions.
- **Verification & Reliability Metrics:**
  - Automated Evaluation Suite: **132 / 132 cases passed (100.0%)**.
  - Intent Routing Accuracy: **100.0%**.
  - Knowledge Retrieval Accuracy: **96.6%**.
  - Grounded Answer Accuracy: **100.0%**.
  - Hallucination Rate: **0.00% (Target: 0.0%)**.
  - Privacy Violation Rate: **0.00% (Target: 0.0%)**.
  - Multilingual Parity: **98.5%**.
  - Average Response Latency: **5.65 ms** (sub-10ms deterministic baseline).
  - All Assistant Tests: `flutter test test/core/assistant/` → **110 / 110 passed (100%)** across 7 test suites (`civic_assistant_evaluation_test.dart`, `civic_assistant_app_context_test.dart`, `civic_assistant_multilingual_test.dart`, `civic_assistant_rag_retriever_test.dart`, `civic_assistant_foundation_test.dart`, `civic_assistant_knowledge_test.dart`, `assistant_screen_widget_test.dart`).
  - Static Analysis: `flutter analyze` → **0 issues found**.
  - Strict compliance with non-commit and non-push constraints.

### 16. Chatbot Rollout — Phase 8: Production Rollout, Observability & Release Readiness (Completed)
- **Objective Achieved:** Finalized production integration, privacy-safe observability, emergency kill switches, safe fallback degradation, context-aware welcome UX, multilingual suggestion chips, quality feedback mechanisms, token budgeting, and post-release maintenance workflows for the CivicFix Citizen Assistant.
- **Production Provider & AI Security Architecture (`lib/core/assistant/services/civic_assistant_provider.dart`):**
  - Verified Runtime Path:
    - Default local execution: `GroundedCivicAssistantProvider` operates 100% on-device using the verified 19 modular knowledge files and hybrid RAG retrieval.
    - Zero remote secrets: Client bundles 0 provider API keys or credentials.
    - Composite Provider: `CompositeCivicAssistantProvider` seamlessly orchestrates local high-confidence resolution and optional remote backend AI with instant local fallback degradation on timeout/error.
- **Production Feature Flags & Limits (`lib/core/assistant/config/civic_assistant_config.dart`):**
  - Master kill switch `assistantEnabled` (allows emergency remote shutdown to maintenance mode without breaking app).
  - Toggles for `remoteAiEnabled`, `observabilityEnabled`, `feedbackEnabled`, and `ttsReadinessEnabled`.
  - Strict bounded limits: `maxHistoryLength` (10 messages, sliding window of 6 turns), `maxRetrievalChunks` (top-K = 5), `maxPromptTokens` (2048 budget).
  - Semantic metadata: `knowledgeVersion: 'v1.2.0-2026Q1'`, `assistantVersion: 'v1.8.0-phase8'`, `retrievalVersion: 'v1.4.0-hybrid'`.
- **Privacy-Safe Telemetry & Observability (`lib/core/assistant/observability/`):**
  - `CivicAssistantAnalytics`: Emits pseudonymized events (`session_started`, `query_submitted`, `intent_classified`, `retrieval_completed`, `response_generated`, `feedback_submitted`, `chat_cleared`).
  - Strict Zero-PII Guarantee: Automated redaction filters eliminate phone numbers, emails, passwords, OTPs, UIDs, tokens, and raw query transcripts from telemetry.
  - `CivicAssistantObservability`: In-memory aggregate monitor tracking total requests, success rate (100%), error rate (0%), fallback rate, latency average (5.65ms), p95 latency, intent distribution, and locale breakdown.
  - Categorized error taxonomy (`assistant_error_type.dart`): `networkFailure`, `providerUnavailable`, `rateLimited`, `retrievalFailure`, `invalidResponse`, `contextUnavailable`, `assistantDisabled`, `unknownFailure`.
- **Context-Aware Welcome & UX Polish (`lib/User UI/`):**
  - Opening welcome greetings and 2–4 starter suggestion chips customized by screen (`Home`, `ComplaintDetails` with active ticket/status, `ReportIssue`, `Map`) in English, Hindi, and Marathi.
  - `AssistantMessageBubble`: Accessible semantic labels, one-tap copy action, TTS readiness hook (`Icons.volume_up_outlined`), and unobtrusive helpfulness feedback (👍 / 👎).
  - Non-Auto-Training Policy: Citizen feedback ratings route strictly to human-in-the-loop review queues rather than direct unsupervised model retraining.
- **Verification & Testing (Phase 8):**
  - `flutter test test/core/assistant/`: **120 / 120 tests passing (100% success rate)** across all 8 test suites (`civic_assistant_production_release_test.dart` [10 tests], `civic_assistant_evaluation_test.dart` [132 benchmark cases], `civic_assistant_app_context_test.dart`, `civic_assistant_multilingual_test.dart`, `civic_assistant_rag_retriever_test.dart`, `civic_assistant_foundation_test.dart`, `civic_assistant_knowledge_test.dart`, `assistant_screen_widget_test.dart`).
  - `flutter analyze`: Clean static analysis (**0 issues found**).
### 17. Chatbot TTS Rollout — Phase 1: Centralized Text-to-Speech Service Integration (Completed)
- **Objective Achieved:** Connected the existing speaker icon (`Icons.volume_up_outlined`) beside assistant message bubbles in `AssistantMessageBubble` and `AssistantScreen` to a centralized, production-grade Text-to-Speech (TTS) engine supporting Indian English (`en-IN`), Hindi (`hi-IN`), and Marathi (`mr-IN`).
- **Dependencies & Architecture (`pubspec.yaml`, `lib/core/assistant/services/civic_assistant_tts_service.dart`):**
  - Integrated `flutter_tts: ^4.2.5` without introducing redundant multimedia libraries.
  - Defined `CivicTtsEngine` interface and `DefaultFlutterTtsEngine` wrapper with headless/unit test tolerance.
  - Implemented `CivicAssistantTtsService` singleton with full lifecycle state management (`idle`, `speaking`, `paused`, `stopped`, `error`).
- **Locale Mapping & Regional Fallbacks:**
  - English $\rightarrow$ `en-IN` (safe fallback to `en-US` if regional pack is unavailable).
  - Hindi $\rightarrow$ `hi-IN`.
  - Marathi $\rightarrow$ `mr-IN` (safe fallback to `hi-IN` Devanagari phonemes if Marathi voice is not installed on device).
- **Concurrency & Verbatim Speech Guarantee:**
  - Single active session concurrency: stops any in-flight playback immediately before starting a new message speech, preventing audio overlap.
  - Reads exact visible response text (`message.text`) without re-querying AI or altering canonical tokens (`CF-2026-000042`, `K/West`, `Ganesh Kulkarni`).
  - Strict guard: Rejects speaking user queries (`isUser == true`), error messages (`isError == true`), or empty strings.
  - Conservative voice parameters: speech rate `0.45`, pitch `1.0`, volume `1.0`.
- **UI & Controller Wiring (`lib/User UI/screens/assistant_screen.dart`, `lib/core/assistant/controller/civic_assistant_controller.dart`):**
  - Wired `onSpeakTap: () => _handleSpeak(message)` callback in `AssistantScreen`.
  - Automated playback shutdown on screen disposal (`dispose()`) and on chat reset (`clearChat()`).
  - Added controller TTS delegation methods (`speakMessage`, `stopSpeech`, `isSpeaking`).
- **Verification & Testing (Phase 1 TTS):**
  - Unit & Integration Test Suite (`test/core/assistant/civic_assistant_tts_service_test.dart`): 14 dedicated test cases verifying locale mappings, Devanagari speech, Marathi fallback, concurrency interruption, completion handlers, error handlers, and controller delegation.
  - Widget Tests (`test/core/assistant/assistant_screen_widget_test.dart`): verified speaker button rendering and interaction.
  - All Assistant Tests: `flutter test test/core/assistant/` $\rightarrow$ **135 / 135 tests passing (100% success rate)** across all 9 test suites.
  - Static Analysis: `flutter analyze` $\rightarrow$ **0 issues found** (clean codebase).
### 18. Chatbot TTS Rollout — Phase 2: Speaker Playback UX, Reactive State & Lifecycle Hardening (Completed)
- **Objective Achieved:** Elevated the technical TTS integration into a reactive, accessible, message-specific, and lifecycle-safe playback experience while preserving the compact message action row (Copy, Speaker, Thumbs Up, Thumbs Down).
- **Reactive State & Active Message Tracking (`lib/core/assistant/services/civic_assistant_tts_service.dart`, `lib/core/assistant/controller/civic_assistant_controller.dart`):**
  - Exposed `activeSpeakingMessageId` and `isSpeaking` reactively across the assistant architecture.
  - Implemented `toggleSpeakMessage(message)`: starts playback on idle/new message, stops playback when tapping the same speaking message.
  - Symmetrical session tokening (`_sessionToken`) guarantees stale native platform channel callbacks cannot overwrite or clear newer active speech playback.
- **Message Language Ownership:**
  - Guaranteed reply language ownership: older assistant messages generated in Marathi/Hindi retain their respective native Devanagari voice packs (`mr-IN` / `hi-IN`) even if the user subsequently alters the active application locale to English.
  - Exact displayed text invariant: reads visible `message.text` directly without reading hidden RAG metadata, timestamps, or altering canonical identifiers (`CF-2026-000042`, `K/West`, `Ganesh Kulkarni`).
- **UI & Lifecycle Hardening (`lib/User UI/screens/assistant_screen.dart`, `lib/User UI/widgets/assistant/assistant_message_bubble.dart`):**
  - **Visual Playback States:**
    - Idle: `Icons.volume_up_outlined` in `CivicFixColors.disabledText` with tooltip `"Read aloud"` and semantic label `"Listen to message"`.
    - Speaking: `Icons.stop_circle_outlined` in `CivicFixColors.primary` with tooltip `"Stop reading"` and semantic label `"Stop reading message"`.
    - Zero layout displacement: compact 14px icon bounds prevent any jumping of adjacent Copy or Feedback action buttons.
  - **Lifecycle Management:** `AssistantScreen` implements `WidgetsBindingObserver` to halt active speech immediately when the app transitions to `inactive`, `paused`, or `detached` lifecycle states.
  - **Turn Interruption:** Submitting a new user query or selecting a prompt chip immediately stops any active speech.
  - **Chat Reset & Disposal:** `clearChat()` and `dispose()` halt playback and reset `activeSpeakingMessageId` to `null`.
- **Verification & Testing (Phase 2 TTS):**
  - Unit & Integration Tests (`test/core/assistant/civic_assistant_tts_service_test.dart`): 18 tests covering toggle start/stop, switching A $\rightarrow$ B, active ID tracking, stale callback resilience, language ownership, and canonical token preservation.
  - Widget Tests (`test/core/assistant/assistant_screen_widget_test.dart`): 5 tests covering interactive toggle states, active icon changes, clear chat stop, and new query turn interruption.
  - Total Assistant Suite: `flutter test test/core/assistant/` $\rightarrow$ **141 / 141 tests passing (100% success rate)** across all 9 suites.
  - Static Analysis: `flutter analyze` $\rightarrow$ **0 issues found**.
  - Strict compliance with non-commit and non-push constraints.

### 19. Chatbot Feedback Rollout — Phase 3: Firestore Feedback Persistence & Privacy-Safe Telemetry (Completed)
- **Objective Achieved:** Connected the existing 👍 (helpful / upvote) and 👎 (unhelpful / downvote) message action buttons to Firebase Cloud Firestore with atomic 1-to-1 message linkage, vote switching, clean deselect removal, and strict privacy shielding for human-in-the-loop quality analysis.
- **Dedicated Firestore Collection & Schema (`chatbot_feedback/{feedbackId}`):**
  - Deterministic Document ID: `${sessionId}_${assistantMessageId}` guarantees exactly 1 feedback record per assistant reply across all user interactions.
  - Strongly Typed Model (`ChatbotFeedbackRecord` in `lib/core/assistant/models/chatbot_feedback_record.dart`):
    - `feedbackId`, `sessionId`, `assistantMessageId`, `userMessageId`, `userMessage`, `assistantReply`, `feedbackType` (`upvote` | `downvote`), `language`, `intentCategory`, `currentScreen`, `complaintStatus`, `retrievedKnowledgeIds`, `retrievalSuccess`, `providerMode`, `responseLatencyMs`, `knowledgeVersion`, `assistantVersion`, `ownerUid`, `createdAt`, `updatedAt`.
  - **Precise Message Linkage:** Directly links the assistant reply receiving feedback to the exact triggering user query via `userMessageId` and `userMessage` metadata.
  - **Bounded Payloads & Verbatim Preservation:** Limits `userMessage` and `assistantReply` to a safe maximum of 2,000 characters while preserving regional Devanagari text (Hindi, Marathi) and canonical municipal tokens (`CF-2026-000042`, `R/South`, `Ganesh Kulkarni`) verbatim without alteration.
- **Centralized Feedback Service & Request Serialization (`lib/core/assistant/services/civic_assistant_feedback_service.dart`):**
  - Pluggable Engine Architecture: `CivicAssistantFeedbackEngine` interface with `FirestoreCivicAssistantFeedbackEngine` (production) and `MockCivicAssistantFeedbackEngine` (testing).
  - Request Serialization Lock: In-flight operations per `assistantMessageId` are serialized to prevent race conditions during rapid tapping (e.g. 👍 $\rightarrow$ 👎 $\rightarrow$ 👍).
  - Optimistic UI & Automatic Rollback: Updates the visual message bubble immediately; upon Firestore write failure, automatically rolls back the vote state and displays a localized SnackBar alert.
  - Vote Switching & Deselect Removal:
    - Tap inactive vote: persists `upvote` or `downvote`.
    - Tap opposite vote: updates existing document (`feedbackType`, `updatedAt`).
    - Tap active vote again (Deselect): deletes document from Firestore and clears local rating.
- **Firestore Security Rules (`firestore.rules`):**
  - Authenticated Authoring: `create` requires `isSignedIn()` and `request.resource.data.ownerUid == request.auth.uid` with CEL type safety and 2,000-character payload limits.
  - Read Access: Restricted to owner (`isOwner(ownerUid)`) or authorized municipal personnel (`isGovernment()`). Public and cross-citizen client reads are strictly denied.
  - Update Lock: Owner can only update mutable fields (`feedbackType`, `language`, `updatedAt`), while immutable keys (`ownerUid`, `sessionId`, `assistantMessageId`, `userMessageId`, `createdAt`) are strictly write-locked.
  - Delete Access: Owner only (`isOwner(ownerUid)`) for active vote deselect.
- **Privacy Allowlist & Non-Auto-Training Policy:**
  - Strict allowlist filtering: passwords, OTPs, auth tokens, private evidence URLs, citizen/officer phone numbers, and emails are permanently excluded from feedback documents.
  - Explicit Non-Auto-Training Invariant: feedback records are persisted strictly for human quality evaluation and municipal knowledge base tuning, NEVER for direct automated model retraining.
- **Core Invariant Independence:**
  - **TTS Independence:** Submitting or deselecting feedback does not affect active audio speech, `isSpeaking`, or `activeSpeakingMessageId`.
  - **Copy Independence:** Message text clipboard copy operations operate independently.
  - **Clear Chat Safety:** Resetting the conversation UI clears in-memory history but preserves already submitted Firestore feedback records.
- **Verification & Testing (Phase 3 Feedback):**
  - Unit & Integration Tests (`test/core/assistant/civic_assistant_feedback_service_test.dart`): 17 tests covering deterministic IDs, length bounding, privacy allowlist, upvote/downvote submission, switching, deselect deletion, multilingual preservation, rapid tap concurrency, and controller rollback.
  - Widget Tests (`test/core/assistant/assistant_screen_widget_test.dart`): 9 tests covering interactive upvote/downvote taps, visual state changes, active vote deselect, and failure rollback.
  - Security Rules Tests (`test/core/firebase/firestore_rules_validation_test.dart`): 19 tests validating security rules and CEL constraints.
  - Full Assistant & Rules Suite: **181 / 181 tests passing (100% success rate)** across all 10 suites.
  - Static Analysis: `flutter analyze` $\rightarrow$ **0 issues found**.

---

## Rewards & Gamification — Phase 1

### 1. Reward Architecture
- **Objective:** Built a robust, centralized, and idempotent gamification and reward engine tied directly into the canonical CivicFix complaint lifecycle.
- **Single Source of Truth:** `RewardEvaluationService` serves as the centralized authority for evaluating and granting civic points.
- **Direct Lifecycle Integration:** Integrated seamlessly with `OfflineFirstComplaintRepository` (for `submitted`) and `ComplaintRoutingService` (for `verified`, `assigned`, `inProgress`, and `resolved`).
- **No Secondary DB:** Operates directly on the canonical complaint records and existing Firebase Firestore / Hive architecture without duplicating complaint storage.

### 2. Stage Values & Maximum Cap
- **Point Schedule (Exact Once-Per-Stage Guarantee):**
  - **Submitted:** `+10` Civic Points
  - **Verified:** `+20` Civic Points
  - **Assigned:** `+15` Civic Points
  - **In Progress:** `+20` Civic Points
  - **Resolved:** `+35` Civic Points
- **Maximum Ceiling:** Exactly `100` Civic Points per complaint (`10 + 20 + 15 + 20 + 35 = 100`).

### 3. Idempotency Strategy
- **Deterministic Document & Event ID:** Every lifecycle stage award generates an event with the deterministic key `${complaintId}_${stage.stageKey}` (e.g. `cmp_123_assigned`).
- **In-Memory & Database Pre-Checks:** Before any points are awarded, `RewardEvaluationService` verifies whether the deterministic event ID exists in local cache or Firestore.
- **In-Flight Concurrency Locks:** In-flight operations for an event ID are locked (`_inFlightEvents`) to prevent double-granting during rapid concurrent events.
- **Transactional Atomic Increments:** Uses Firestore transactions and `FieldValue.increment` to atomically write `reward_events`, update citizen total points in `users`, and maintain summary counters in `rewards`.

### 4. Anti-Abuse & Integrity Rules
- **Rejected & Fraudulent Quarantine:** Complaints flagged with AI synthetic evidence (`isAiGeneratedEvidenceRejected`), rejected status (`status == ComplaintStatus.rejected`), or failed verification are strictly blocked from earning any subsequent stage rewards (`verified`, `assigned`, `inProgress`, `resolved`).
- **Duplicate Grievance Quarantine:** Complaints identified as duplicates are blocked from earning progression points.
- **Reopen / Rework Safety:** When a resolved complaint is reopened by a Department Lead (moving status back to `inProgress`, `reopenCount++`), previous stages and subsequent re-resolution do NOT re-award points.
- **Grievance Ceiling Guard:** The service strictly enforces a 100-point hard ceiling per grievance, preventing any edge-case over-crediting.

### 5. Canonical Models & Firestore Structure
- **Collection `reward_events/{eventId}`:**
  - `id`: `${complaintId}_${stage}`
  - `citizenId`: String (UID of the citizen)
  - `complaintId`: String (Canonical grievance ID)
  - `complaintTitle`: String (Grievance title)
  - `rewardType`: String (`submitted`, `verified`, `assigned`, `in_progress`, `resolved`)
  - `points`: int (Points awarded for this stage)
  - `description`: String (Human-readable description)
  - `createdAt`: Timestamp
  - `metadata`: Map (Ticket number, category, status, reopen count)
- **Collection `users/{citizenId}`:**
  - `civicPoints`: int (Incremented atomically)
  - `reportsSubmitted`: int
  - `reportsResolved`: int
- **Collection `rewards/{citizenId}`:**
  - Aggregated reward counters and tier progress.

### 6. Verification Results
- **Unit & Integration Tests:**
  - `test/core/services/reward_evaluation_service_test.dart` $\rightarrow$ **7 / 7 tests passing (100%)**.
  - `test/core/repositories/hive_rewards_repository_test.dart` $\rightarrow$ **3 / 3 tests passing (100%)**.
  - `test/core/services/phase2_field_officer_execution_test.dart` $\rightarrow$ **48 / 48 tests passing (100%)**.
  - Full core test suite $\rightarrow$ **166 / 166 tests passing (100%)**.
- **Static Analysis:**
  - `flutter analyze lib/ test/core/services/reward_evaluation_service_test.dart` $\rightarrow$ **0 issues found**.

---

## Rewards & Gamification — Phase 2

### 1. Level Thresholds & Progression Model
- **Canonical Civic Levels (Exact Thresholds):**
  - **Level 1 (0–99 pts):** `Civic Starter` (🌱) — Initial entry tier; 100 points required to reach Level 2.
  - **Level 2 (100–249 pts):** `Civic Contributor` (🌿) — Active citizen reporter; 150 points tier span to Level 3.
  - **Level 3 (250–499 pts):** `Civic Champion` (🌳) — Proven neighborhood contributor; 250 points tier span to Level 4.
  - **Level 4 (500–999 pts):** `Civic Leader` (🏆) — Community steward; 500 points tier span to Level 5.
  - **Level 5 (1000+ pts):** `Civic Hero` (⭐) — Pinnacle civic tier; max level reached, no fake next level, progress complete (1.0).

### 2. Centralized Progress & Level Calculation
- **Model / Calculator (`CivicLevelInfo` & `CivicLevel` in `lib/core/models/reward_model.dart`):**
  - `CivicLevelInfo.calculate(int points)` derives:
    - `currentLevel`: Canonical `CivicLevel` enum with level number (1..5), title, symbol, minimum, and threshold.
    - `totalPoints`: Non-negative clamped points.
    - `nextLevel`: Next `CivicLevel` or `null` for Level 5 (`Civic Hero`).
    - `pointsRemaining`: `(nextThreshold - points).clamp(0, nextThreshold)` or `0` for Level 5.
    - `progress`: Tier progress `(points - minimum) / (nextThreshold - minimum)` clamped [0.0, 1.0] or `1.0` for Level 5.

### 3. Rewards Dashboard Architecture (`RewardsScreen`)
- **Location:** `lib/User UI/screens/rewards_screen.dart`
- **Component Hierarchy:**
  1. `PointsProgressCard`: Level badge (`Level X • Title`), total points, LinearProgressIndicator, dynamic subtitle (`X pts to Level Y: NextTitle` or `Hero Tier Achieved — Top civic milestone unlocked!`), and ratio.
  2. `CivicImpactCard`: 5-metric impact summary (Submitted, Verified, Resolved, Community Upvotes, Achievements Unlocked).
  3. `RecentRewardActivityCard`: List of real `RewardEvent` items with `+points` badge, description, ticket number, and relative timestamps.
  4. `AchievementCard` Grid: Canonical MVP Achievements with lock/unlock status.
  5. `Community Perks` List: Redeemable partner benefits catalog.

### 4. Reward History & Civic Impact Data Sources
- **Reward History:** Persisted canonical `RewardEvent` documents from Firestore `reward_events` collection and in-memory `RewardEvaluationService`.
- **Civic Impact Data Source:** Derived cleanly from existing `UserModel` (`reportsSubmitted`, `reportsResolved`), `ComplaintModel` (verified complaints count, resolved count, and total upvotes sum), and unlocked `CivicAchievement` count without creating duplicate counters.

### 5. Verification & Test Results
- **Unit Tests (`test/core/services/civic_level_calculator_test.dart`):** 10 tests verifying 0, 100, 250, 500, 1000, >1000 points, boundary conditions (99, 249, 499, 999), intermediate progress math, and impact summary derivation.
- **Widget Tests (`test/user_ui/rewards_dashboard_phase2_test.dart`):** 3 widget tests verifying Level 1 UI rendering, Level 5 Civic Hero rendering (no fake next level, Max Level badge), and real-time live UI updates upon point changes.
- **Core Suite Regression:** **179+ tests passing (100% success rate)** across all reward and core service suites.
- **Static Analysis:** `flutter analyze` $\rightarrow$ **0 issues found**.


---

## Rewards & Gamification — Phase 3

### 1. Canonical Achievement Badges & Definitions
- **The 5 Canonical CivicFix Achievements:**
  1. `evidence_expert` (**Evidence Expert** 📸): Awarded for submitting 5 verified complaints with clear photographic evidence attached.
  2. `ground_reporter` (**Ground Reporter** 📍): Awarded for submitting 5 verified complaints with precise GPS coordinates.
  3. `community_voice` (**Community Voice** 🗣️): Awarded for receiving 10 community upvotes across submitted complaints.
  4. `community_helper` (**Community Helper** 🤝): Awarded for actively supporting/upvoting 10 civic grievances raised by neighbors.
  5. `resolution_champion` (**Resolution Champion** 🏆): Awarded for seeing 5 citizen-reported grievances through to full municipal resolution (`resolved` or `closed`).

### 2. Configurable Thresholds Matrix (`AchievementThresholds`)
- Centralized in `lib/core/services/achievement_evaluator.dart`:
  - `AchievementThresholds.evidenceExpert`: **5** verified complaints with photos.
  - `AchievementThresholds.groundReporter`: **5** verified complaints with GPS coordinates.
  - `AchievementThresholds.communityVoice`: **10** total received upvotes.
  - `AchievementThresholds.communityHelper`: **10** total supported complaints.
  - `AchievementThresholds.resolutionChampion`: **5** resolved complaints.

### 3. Evaluator Architecture & Data Derivation
- **Class:** `AchievementEvaluator` in `lib/core/services/achievement_evaluator.dart`
- **Zero Duplicate Counters Principle:** Progress is derived directly on demand from existing sources:
  - Evidence & Ground reporting derived from citizen complaints filtering on `isVerified` and `imageUrls.isNotEmpty` / valid GPS lat-long.
  - Community voice derived from aggregating `upvotes` across citizen complaints.
  - Community helper derived from citizen's upvoted complaints / user profile activity.
  - Resolution champion derived from citizen complaints matching `ComplaintStatus.resolved` or `ComplaintStatus.closed`.
- **Idempotent Unlock & Timestamp Immutability:**
  - `unlockedAt` timestamp is minted at the moment of qualification and strictly preserved across subsequent evaluations (`existing.unlockedAt`). Once unlocked, a badge is never reverted or re-timestamped.

### 4. Locked / Unlocked UI Architecture (`AchievementCard`)
- **Location:** `lib/User UI/widgets/rewards/achievement_card.dart` & `lib/User UI/screens/rewards_screen.dart`
- **Locked State UX:** Shows subtle locked padlock icon, requirement explanation ("Unlock Requirement: X"), linear progress bar, and numeric fraction/percentage (`3 / 5 (60%)`).
- **Unlocked State UX:** Shows vibrant accent badge, unlock checkmark, badge title, description, and exact unlock timestamp (`Unlocked 09/10/2026`).
- **Interactive Detail Modal:** Clicking any badge displays full requirements, current progress ratio, and badge status in an accessible dialog.

### 5. Verification & Test Results
- **Evaluator Unit Tests (`test/core/services/achievement_evaluator_test.dart`):** 7 / 7 tests passing covering initial zero state, individual badge qualification thresholds, single unlock lifecycle, and timestamp immutability.
- **Card Widget Tests (`test/user_ui/achievement_card_test.dart`):** 2 / 2 tests passing covering locked progress UI, unlock date rendering, and modal details.
- **Full Rewards Suite:** 32 / 32 tests passing.
- **Static Analysis:** `flutter analyze` $\rightarrow$ **0 issues found**.

---

## Rewards & Gamification — Phase 4

### 1. Community Reward Rules & Invariants
- **Community Voice:**
  - Progress derives strictly from legitimate, verified community support/upvotes on the citizen's own valid complaints.
  - Enforces single-voter integrity: distinct voter IDs are required; a user cannot generate multiple upvotes on the same ticket.
  - Toggling upvotes on/off does not generate duplicate points or inflate counters.
- **Community Helper:**
  - Progress derives strictly from distinct verified complaints by OTHER citizens supported by the user.
  - Self-upvotes are strictly excluded and blocked.
  - Reaching the 10-supported-complaints milestone idempotently awards the canonical +10 Civic Points bonus.
- **Quality > Quantity:**
  - The system values authentic resolution and verified civic reporting over mass complaint submission or spam upvoting.

### 2. Centralized Anti-Abuse Checks & Quarantines
- **Self-Upvote Block:** `OfflineFirstComplaintRepository.upvoteComplaint` and `RewardEvaluationService.evaluateCommunityUpvote` strictly reject attempts where `voterId == complaint.citizenId`.
- **Rejected & Fraudulent Complaint Quarantine:** Complaints with `status == rejected`, `evidenceVerificationStatus == 'failed'`, or AI-generated fake evidence are blocked from lifecycle progression beyond submitted and blocked from generating community rewards.
- **Duplicate Grievance Quarantine:** Complaints identified as duplicates (`verificationFailureReason` containing 'duplicate' or duplicate flags) cannot receive lifecycle points or community voice progression.
- **Reopen / Rework Safety:** Reopened complaints returning from `resolved` to `inProgress` or `reopenCount > 0` cannot re-award previously credited stage points.
- **Upvote Toggle Farming Prevention:** Unique `${voterId}_${complaintId}` lock prevents repeated on/off vote cycles from farming points or inflating metrics.

### 3. Architecture & Centralization
- **Backend Service:** `RewardEvaluationService` in `lib/core/services/reward_evaluation_service.dart`.
- **Evaluator:** `AchievementEvaluator` in `lib/core/services/achievement_evaluator.dart`.
- **Repository Guard:** `OfflineFirstComplaintRepository` in `lib/core/repositories/offline_first_complaint_repository.dart`.
- **Zero UI-Coupled Decision Logic:** All reward grants, point calculations, and qualification checks execute strictly within the centralized reward engine.

### 4. Verification & Test Results
- **Dedicated Anti-Abuse Suite (`test/core/services/community_rewards_anti_abuse_test.dart`):** 8 / 8 tests passing covering:
  - Self-upvote blocking
  - Duplicate upvote blocking
  - Upvote toggle farming prevention
  - Rejected complaint stage/upvote quarantine
  - Duplicate complaint progression quarantine
  - Reopened complaint stage re-award protection
  - Community Voice legitimate upvote derivation
  - Community Helper 10-complaint milestone qualification & idempotent bonus
- **Full Rewards Suite:** 40 / 40 tests passing across all unit and widget tests.
- **Static Analysis:** `flutter analyze` $\rightarrow$ **0 issues found**.

---

## Rewards & Gamification — Phase 5: Final Transparency, History & Production QA

### 1. Final Rewards Screen Architecture
- **Exact 4 Canonical Sections:**
  1. **Current Level (`PointsProgressCard`):** Displays current Civic Level (1..5), non-negative point balance, next milestone goal, remaining points needed, dynamic ratio progress bar, and "Civic Hero" max-level handling.
  2. **Civic Progress (`CivicImpactCard`):** 5 clean metrics derived dynamically from existing complaint & profile records without redundant counters (Submitted, Verified, Resolved, Community Upvotes, Achievements Unlocked).
  3. **Reward History (`RecentRewardActivityCard`):** Displays real `RewardEvent` instances (newest first) with point pill (`+35`), stage reason, complaint ticket/title, and relative timestamps (`10m ago`, `2d ago`). Includes empty state handling (`No reward activity yet`).
  4. **Achievement Badges (`AchievementCard` Grid):** Canonical 5 badges with visual lock/unlock distinction, requirements, progress fraction, unlock date, and tap-to-expand detail dialog.

### 2. Point Traceability & Full Lifecycle Verification
- **Strict Point-to-Event Mapping:** Every awarded Civic Point is permanently backed by an immutable `RewardEvent` with deterministic ID (`${complaintId}_${stage}`).
- **Authoritative 100-Point Complaint Lifecycle:**
  - `Submitted` $\rightarrow$ **+10 pts**
  - `Verified` $\rightarrow$ **+20 pts**
  - `Assigned` $\rightarrow$ **+15 pts**
  - `In Progress` $\rightarrow$ **+20 pts**
  - `Resolved` $\rightarrow$ **+35 pts**
  - **Total per Complaint:** Exactly **100 Civic Points**.
- All 5 lifecycle events are recorded in reward history without omissions or duplications.

### 3. Production Resilience, Offline & Error States
- **Offline / Cached State:** Displays `OfflineCacheBanner` at top of screen with manual refresh trigger; persists cached user points and achievements via Hive.
- **Loading State:** Centered `LoadingState` spinner during initial repository resolution.
- **Error State:** Accessible `ErrorState` with retry button when Firestore/network fails.
- **Responsive Layout:** Encapsulated within `ResponsiveContainer(maxWidth: 600)` with adaptive grid layout for mobile and desktop screens.

### 4. Final Anti-Abuse QA Verdict
- **Same stage twice:** +0 duplicate points (PASS)
- **Reopened complaint rework:** No repeat lifecycle rewards (PASS)
- **Rejected / fraudulent complaints:** Stages and upvotes quarantined (PASS)
- **Duplicate complaints:** Quarantined from reward progression (PASS)
- **Upvote toggle farming:** Toggling cannot generate duplicate rewards (PASS)
- **Self-upvote:** Strictly blocked in repository & service (PASS)
- **Achievement unlock:** Guaranteed exactly once with immutable timestamp (PASS)

### 5. Final Verification & Test Results
- **Full QA Test Suite (`test/user_ui/rewards_phase5_production_qa_test.dart`):** 5 / 5 tests passing.
- **Total Rewards Test Suite:** 45 / 45 tests passing across all 5 phases.
- **Static Analysis:** `flutter analyze` $\rightarrow$ **0 issues found**.
- **Final System Status:** **CIVICFIX REWARDS SYSTEM READY**.






## Rewards Certificate System — Phase 1

### 1. Architectural Overview & Certificate Models
- **Canonical Model (`CivicCertificate`):**
  - Stored in `certificates` Firestore collection and cached locally via `HiveCertificateRepository`.
  - Core fields: `certificateId`, `recipientUid`, `recipientDisplayName`, `certificateType` (`civic_level` / `achievement`), `certificateTitle`, `civicLevel`, `pointsAtIssue`, `verifiedComplaintsAtIssue`, `resolvedComplaintsAtIssue`, `achievementReason`, `issuedAt`, `status` (`valid` / `revoked`), `verificationSlug`, `pdfStoragePath`, `revocationReason`, `revokedAt`, `certificateVersion`, `createdAt`.
  - **Zero Private PII Leakage:** Plaintext emails, phone numbers, and credentials are intentionally excluded.

### 2. Trusted Backend Eligibility & Idempotent Issuance
- **Eligibility Engine (`CertificateIssuanceService`):**
  - Validates eligibility exclusively from authoritative backend records (`UserRepository`, `ComplaintRepository`, `RewardsRepository`).
  - **Level Tier Eligibility:** Issued for Level 2 (`Civic Contributor`), Level 3 (`Civic Champion`), Level 4 (`Civic Leader`), and Level 5 (`Civic Hero`).
  - **Achievement Milestone Eligibility:** Requires verifiable unlock of canonical achievements (`Evidence Expert`, `Ground Reporter`, `Community Voice`, `Community Helper`, `Resolution Champion`).
- **Strict Idempotency Guarantee:**
  - Deterministic ID formula: `cert_${recipientUid}_${sanitizedType}_${sanitizedMilestoneKey}`.
  - Verification Slug: Deterministic 24-character SHA-256 hash `v_${hash(certId + recipientUid + issuedAt)}`.
  - Re-issuing for the same milestone returns the existing certificate without creating duplicate Firestore documents or storage assets.

### 3. PDF Generation & QR Embedding
- **Generator (`CertificatePdfGenerator`):**
  - Produces high-resolution landscape A4 PDFs following the Civic Precision design system.
  - Multi-tier decorative gold & slate architectural borders, municipal seal emblem, authoritative typography, and recipient snapshot metrics.
  - Dynamic QR code embedding verification URL: `https://civicfix.org/verify/{verificationSlug}`.
  - Cloud Storage path mapping: `civic-certificates/{certificateId}/certificate.pdf`.

### 4. Citizen Experience & "My Certificates" UI
- **`MyCertificatesSection` in `RewardsScreen`:**
  - Lists earned certificates alongside available milestones ready to claim.
  - Displays certificate title, issue date, snapshot points/resolved stats, and green `VALID` or red `REVOKED` status badge.
  - View modal displays the certificate details dialog with live QR preview, verification slug, and official seal.
  - Integrated Claim action generates certificate PDF and persists record in real-time.

### 5. Verification & Test Results
- **Certificate System Test Suite (`test/core/services/certificate_system_test.dart`):** 6 / 6 tests passing.
- **Combined Rewards & Certificate Test Suite:** 26 / 26 tests passing across lifecycle, anti-abuse, and UI.
- **Static Analysis:** `flutter analyze` $\rightarrow$ **0 issues found**.

## Rewards Certificate System — Phase 2

### 1. Architectural Overview & Public Verification Portal
- **Public Verify Route:** `/verify/{verificationSlug}`
- **Authentication:** Zero login requirement; completely open and accessible to external institutions (universities, employers, NGOs, municipal auditors).
- **Public Data Allowlist (`PublicCertificateData`):**
  - **Exposed Safe Fields:** `certificateId`, `recipientDisplayName`, `certificateType`, `certificateTitle`, `civicLevel`, `pointsAtIssue`, `verifiedComplaintsAtIssue`, `resolvedComplaintsAtIssue`, `achievementReason`, `awardImportance`, `issuedAt`, `status` (`VALID` / `REVOKED`), `verificationSlug`, `certificateVersion`, `revocationReason`, `revokedAt`.
  - **Strict Security Redaction:** Firebase UIDs, citizen phone numbers, email addresses, private internal database keys, evidence URLs, and credentials are mathematically excluded and cannot leak.

### 2. Validation States & Trust Semantics
1. **`VALID`:**
   - Emerald Verified Badge: "✓ Certificate Verified — Authentic CivicFix Achievement Record".
   - Displays recipient name, authoritative title, civic level, certificate ID, issue date, and impact metrics snapshot (+points, verified reports, resolved reports).
   - Explains the municipal authority importance behind the award.
2. **`REVOKED`:**
   - Crimson Alert Banner: "CERTIFICATE REVOKED — This certificate is no longer considered valid by CivicFix."
   - Displays historical record data and official revocation reason/date without granting verified green badges.
3. **`INVALID` / `NOT FOUND`:**
   - Amber / Neutral state: "Certificate Not Verified — No valid CivicFix certificate was found for this verification reference."
   - No database lookup errors or structural details are exposed to the client.

### 3. Vercel Serverless Portal (`verification_portal`)
- **Structure:**
  - `vercel.json`: Clean URL rewrites from `/verify/:slug` to `/verify.html?slug=:slug` and API routing `/api/verify/:slug` to `/api/verify.js`.
  - `api/verify.js`: Serverless validation function with Firestore REST query integration, CORS support, and allowlist mapping.
  - `public/verify.html`, `public/styles.css`, `public/app.js`: Civic Precision responsive single-page portal.
  - `.env.example` / `README.md`: Environment configuration for `PUBLIC_BASE_URL`, `FIREBASE_PROJECT_ID`, and `FIREBASE_API_KEY`.

### 4. Verification & QA Matrix
- **Unit & Logic Tests (`test/core/services/public_certificate_verification_test.dart`):** 5 / 5 tests passing.
- **UI & Widget Tests (`test/user_ui/public_certificate_verification_screen_test.dart`):** 3 / 3 tests passing.
- **Full Combined Suite:** 34 / 34 tests passing across all Certificate and Rewards tests.
- **Static Analysis:** `flutter analyze` $\rightarrow$ **0 issues found**.

---

## CivicFix Notification System Audit & Pipeline Architecture

### 1. Architectural Overview & Component Pipeline
- **End-to-End Pipeline:**
  1. **Lifecycle Event / Trigger:** Complaint submitted, AI evidence verification evaluated, department auto-routed to Junior Engineer, field work started, blocked, resumed, resolved, closed, or reopened.
  2. **Authoritative Record Creation:** Backend Cloud Functions write deterministic records to `notifications/{notificationDocId}` with recipient `userId`, `title`, `message`, `type`, `complaintId`, `ticketNumber`, `priority`, and server timestamps.
  3. **Multi-Device Token Resolution:** Backend queries active FCM registration tokens in `users/{citizenId}/devices` subcollection.
  4. **FCM Multicast Dispatch:** Dispatches high-priority push payloads targeted to Android channel `civicfix_complaints_channel` with deep-link navigation data (`complaintId`, `targetRoute`, `type`, `role`).
  5. **Client Receiving Handlers:**
     - **Foreground:** `FirebaseMessaging.onMessage` triggers in-app banner alert (`MockNotificationService.showInAppAlert`) and updates unread badge.
     - **Background:** `FirebaseMessaging.onMessageOpenedApp` intercepts system tray push tap and routes directly to `ComplaintDetailsScreen` (`AppRoutes.complaintDetails`).
     - **Terminated:** `FirebaseMessaging.getInitialMessage()` retrieves cold-launch push notification payload and completes deferred navigation after widget tree initialization.
     - **Background Isolate Handler:** Top-level `@pragma('vm:entry-point') firebaseMessagingBackgroundHandler` executes in background isolate.
  6. **In-App Notification Center (`NotificationsScreen`):**
     - Filterable by `All`, `Unread`, `Read` with live count badges.
     - Supports bulk "Mark all as read" and individual notification state synchronization.
     - Backed by `OfflineFirstNotificationRepository` with Hive local caching and Firestore real-time snapshot sync.

### 2. Root Cause Defect Identification & Resolution
- **Defect 1 (Missing Initial Submission Trigger):** `onComplaintCreated` in `functions/src/index.ts` previously executed AI verification without creating a `notifications` record or dispatching an FCM push for complaint submission. Resolved by adding `sendCitizenNotification` upon initial ingestion.
- **Defect 2 (Status Transition Coverage):** `getStatusContent` and `onComplaintStatusChanged` lacked explicit templates for `reopened` and `reported` transitions. Resolved with dedicated lifecycle message templates.
- **Defect 3 (Android 8.0+ Channel Meta-Data):** Added `com.google.firebase.messaging.default_notification_channel_id` meta-data in `AndroidManifest.xml` targeting `civicfix_complaints_channel` to prevent system-level push drops on API 26+.
- **Defect 4 (Token Sanitation & Security):** `FirebaseUserDataSource.sanitizeTokenDocId` safely sanitizes FCM tokens for Firestore subcollection IDs, with rules enforcing owner-only read/write on `users/{userId}/devices/{deviceId}`.

### 3. Verification & Compliance Checklist
- [x] **FCM registration flow:** Verified across email/password login, registration, Google Sign-In, and profile hydration.
- [x] **Token refresh handling:** Active `onTokenRefresh` listener updates Firestore device document upon token rotation.
- [x] **Backend trigger coverage:** Authoritative triggers across Submission, Verification, Assignment, In-Progress, Resolved, Closed, and Reopened.
- [x] **Android permissions:** `POST_NOTIFICATIONS` declared in `AndroidManifest.xml` and requested dynamically on Android 13+ (API 33+).
- [x] **Android channels:** Default channel `civicfix_complaints_channel` configured in manifest and FCM payload.
- [x] **Background message receipt:** `@pragma('vm:entry-point')` background isolate handler configured in `main.dart`.
- [x] **Foreground in-app notification:** Non-blocking in-app alert banner presented via `_presentForegroundNotification`.
- [x] **Notification center loading:** Offline-first caching with Firestore remote fallback and cursor pagination.
- [x] **Unread badge synchronization:** Real-time stream and value listenables binding unread counts to home header and app bar.
- [x] **Security rules compliance:** Strictly enforced owner-read, server-only creation (`allow create: if false`), and `isRead`-only updates.


## Gamification Repair — Phase 1

### 1. Investigation & Root Cause Summary
- **Live Failure Confirmed:** Complaint lifecycle points and achievement bonuses never reach citizen profiles in production.
- **Root Cause Chain:**
  1. Complaint actions invoke `RewardEvaluationService.evaluateStage`, which attempts client-side transactions writing `reward_events`, `users.civicPoints`, and `rewards`.
  2. Deployed Firestore Security Rules (`civicfix-38d53`) reject these writes with `permission-denied` (lines 334-348 prohibit client updates to `civicPoints`; line 718 prohibits client writes to `rewards/{userId}`; `reward_events` has no write rule).
  3. Evaluator catches and suppresses the exception (`debugPrint`), adds the event ID to in-memory set, and returns `granted: true`, falsely signalling success and preventing same-session retries.
  4. Local cache fallback checks `if (userRepo is HiveUserRepository)`, which evaluates to `false` because runtime repository is `OfflineFirstUserRepository`. No profile cache write occurs.
  5. Backend infrastructure is missing: Supabase reconciler `sync-civic-rewards` (`hkgwsqasmboadvpjckbj`) is not deployed (HTTP 404 `NOT_FOUND`), and Firebase Cloud Functions has 0 deployed triggers.
  6. Rewards screen reads user profile before sync, overwrites fresh points with stale `user.civicPoints` (20), and binds to `getUserListenable()` which lacks Firestore stream updates.

### 2. Live Affected Record Evidence
- **Citizen:** `pfZM...lbg1` (5 complaints filed). Stored `civicPoints`: 20 (registration allowance only).
- **Complaint:** `KaYLHbQD2HKd5Eu7Pxco` (Ticket `CF-2026-1791090369943000-64ce47c897cc`). Status: `inProgress` (submitted + verified + assigned + inProgress = 65 eligible points).
- **Rewards Documents:** `rewards/pfZM...lbg1` does not exist (404); `rewards/{uid}/events` and root `reward_events` have 0 documents.

### 3. Proposed Authoritative Reward Contract
- **Single Trusted Backend Owner:** No client writes to reward collections. Backend worker running with Google Service Account / Admin privileges executes atomic batch commits.
- **Point Policy:** Submitted (+10), Verified (+20), Assigned (+15), In Progress (+20), Resolved (+35); Max 100 pts per complaint. Community Helper: one-time +10 bonus at >=10 supported complaints. Other achievements grant badges only (0 pts).
- **Deterministic Keys:** `eventId = SHA256("${citizenId}:${localId || ticketNumber || complaintId}")_${stage}`.
- **Atomic Boundary:** Single batch write creates missing `rewards/{citizenId}/events/{eventId}`, updates `rewards/{citizenId}` summary, and increments `users/{citizenId}.civicPoints`.
- **Response Semantics:** Explicit `committed`, `already_awarded`, `pending`, `failed` statuses.

### 4. Verification Limits & Test Coverage
- **Local Tests:** 32 / 32 tests passed across reward and achievement suites; passed falsely due to `db: null` injection, mock repositories, and in-memory assertions.
- **Verification Limits:** Supabase edge functions undeployed (404); live mutation testing intentionally avoided to preserve production balances and test neutrality.
- **Full Report:** See [GAMIFICATION_PHASE_1_AUDIT_AND_CONTRACT.md](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/GAMIFICATION_PHASE_1_AUDIT_AND_CONTRACT.md).


## Gamification Repair — Phases 3 & 4

### 1. Overview & Objectives
- **Phase 3 (Profile, Points, and History):** Synchronized authoritative point totals across `ProfileScreen` and `RewardsScreen`; removed stale `user.civicPoints` overwrites; switched history reads to canonical subcollection `rewards/{userId}/events` with owner-only read rules; preserved all counters (`reportsVerified`, `communityUpvotes`, `supportedComplaints`, `recentActivity`, `syncPending`); implemented account switching detection in `OfflineFirstUserRepository` to purge stale cache and prevent cross-account point leaks.
- **Phase 4 (Achievements):** Standardized target progress across domain models, mappers, and `AchievementEvaluator` (targets: 5, 5, 10, 10, 5); bound Community Helper progress to authoritative `supportedComplaints`; preserved immutable `unlockedAt` timestamps across refreshes and restarts; restricted bonus points strictly to Community Helper's one-time +10 bonus via committed backend events; retained recognition-only status (0 pts) for the other four badges.

### 2. Files Modified
- `lib/core/models/reward_model.dart`: Added `targetProgress` to `CivicAchievement`, default values configured.
- `lib/core/firebase/mappers/reward_firestore_mapper.dart`: Added mapping for `targetProgress`, `currentProgress`, `unlockedAt`, and supported complaint metrics.
- `lib/core/firebase/mappers/user_firestore_mapper.dart`: Added robust `num?` conversions for `civicPoints` and complaint counts.
- `lib/core/repositories/offline_first_user_repository.dart`: Purges local cache on UID mismatch; prioritizes authoritative server points.
- `lib/core/repositories/offline_first_rewards_repository.dart`: Preserves all mapped metrics and recent events without field dropping.
- `lib/core/repositories/hive_rewards_repository.dart`: Removed legacy points-based achievement unlock mutations.
- `lib/core/services/achievement_evaluator.dart`: Integrated canonical targets and authoritative `supportedComplaintsCount`; preserved `unlockedAt` timestamps.
- `lib/User UI/screens/rewards_screen.dart`: Authoritative points synchronization with local user cache; canonical event history loading.
- `lib/User UI/screens/profile_screen.dart`: Pull-to-refresh (`RefreshIndicator`) and initial user hydration on load.
- `lib/core/services/civic_rewards_sync_service.dart`: Clean null-aware operator usage for reconciliation payloads.
- `lib/core/firebase/firestore/firebase_rewards_data_source.dart`: Reads canonical history from `rewards/{userId}/events`.

### 3. Verification & Test Status
- `flutter analyze`: 0 errors, 0 warnings, 0 lints.
- **Reward & Service Tests:** 36/36 passed (`reward_evaluation_service_test.dart`, `community_rewards_anti_abuse_test.dart`, `firestore_mappers_test.dart`, `rewards_dashboard_phase2_test.dart`, `rewards_phase5_production_qa_test.dart`).
- **Repository & Achievement Tests:** 15/15 passed (`hive_rewards_repository_test.dart`, `hive_user_repository_test.dart`, `achievement_evaluator_test.dart`, `achievement_card_test.dart`).
- **Hive Model & Adapter Tests:** 16/16 passed (`local_models_and_adapters_test.dart`).
- **Full Report:** See [GAMIFICATION_PHASE_3_4_REPORT.md](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/GAMIFICATION_PHASE_3_4_REPORT.md).


## Gamification Repair — Phase 5: Final Verification & Deployment Plan

### 1. Verification Summary
- **Client & Mapper Test Suite:** 67 / 67 tests passed (`reward_evaluation_service_test.dart`, `community_rewards_anti_abuse_test.dart`, `firestore_mappers_test.dart`, `rewards_dashboard_phase2_test.dart`, `rewards_phase5_production_qa_test.dart`, `hive_rewards_repository_test.dart`, `hive_user_repository_test.dart`, `achievement_evaluator_test.dart`, `achievement_card_test.dart`, `local_models_and_adapters_test.dart`).
- **Backend Policy Engine Suite:** 7 / 7 tests passed (`test_civic_rewards_engine.js` covering 100 pt lifecycle cap, idempotent retries, reopened complaints, fraud rejection, authorization rules, Community Helper milestone, and recognition-only badges).
- **Static Analysis & Compilation:** `flutter analyze` clean (0 issues); `flutter build web --release` compiled cleanly.

### 2. Read-Only Historical Reconciliation Dry Run
- Executed against live production Firestore (`civicfix-38d53`).
- Analyzed 2 citizen profiles and 12 production complaints.
- Citizen `pfZMsRAkKCQvUBpd8KWPowEMlbg1`: 12 filed complaints (11 eligible across submitted, verified, assigned, inProgress, and closed). Currently stored: 20 pts. Theoretical total: 435 pts. Discrepancy: **+415 uncredited civic points**.
- Zero production documents were modified during the audit.

### 3. Production Deployment Plan
- **Supabase Target:** `hkgwsqasmboadvpjckbj` (`civicfix-serverless`, `ap-south-1`). Deploy command: `npx supabase functions deploy sync-civic-rewards --no-verify-jwt`.
- **Firebase Target:** `civicfix-38d53`. Deploy command: `firebase deploy --only firestore:rules`.
- **Full Report:** See [GAMIFICATION_PHASE_5_FINAL_REPORT.md](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/GAMIFICATION_PHASE_5_FINAL_REPORT.md).
