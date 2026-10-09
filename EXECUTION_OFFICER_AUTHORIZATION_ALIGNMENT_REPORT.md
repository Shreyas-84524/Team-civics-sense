# CIVICFIX — CRITICAL BUG FIX REPORT
## Execution Officer Assignment & Start Job Authorization Alignment

**Date:** October 8, 2026  
**Status:** Resolved & Verified  
**Scope:** Government Portal, Field Operations, Role-Based Access Control, Cloud Firestore & State Machine  

---

### Executive Summary

When a supervising Junior Engineer (e.g. `GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-01`) assigned a Field Execution Officer (e.g., Ganesh Kulkarni, `GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-02`, UID `rbQflILEPabot9t9EScfQmdmvn73`) to a complaint (`CF-2026-1791368464448000-a32fe69cef8b`), the Complaint Details UI accurately displayed:
- **Field Execution Officer:** Ganesh Kulkarni
- **Designation:** Field Crew Technician 2
- **Ward:** R_SOUTH
- **Department:** Roads & Maintenance
- **Status:** Assigned for Field Work

However, when Ganesh logged in and clicked **Start Job**, the application threw:
```
Bad state: Security Violation: Complaint CF-2026-1791368464448000-a32fe69cef8b is not assigned to crew member GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-02
```

This occurred because the display logic and workdesk query (`loadCrewWorkdesk`) had been upgraded to use the canonical `assignedFieldOfficerId`, but the operational execution methods in `GovernmentCrewWorkService` (`startJob`, `submitWorkCompletion`, `resumeWorkAfterRework`, `reportBlockedIssue`) and `GovernmentComplaintVisibilityService.getPermittedActions` were still asserting ownership solely against `assignedCrewMemberId` (which stores the supervising Junior Engineer).

All authorization checks across the application now uniformly validate against `assignedFieldOfficerId` (supporting both Employee ID and Firebase UID aliases), while strictly enforcing Junior Engineer vs. Field Officer role separation.

---

### 1. Root Cause Breakdown

| Component | Pre-Fix Behavior | Fixed Behavior |
| :--- | :--- | :--- |
| **UI Display & Workdesk** | Read `complaint.assignedFieldOfficerId` | Reads `complaint.assignedFieldOfficerId` (consistent) |
| **`GovernmentCrewWorkService.startJob`** | Checked `complaint.assignedCrewMemberId == crewUser.employeeId` (JE ID) | Delegates to `_authService.canStartFieldWork`, checking `assignedFieldOfficerId` |
| **`GovernmentCrewWorkService.submitWorkCompletion`** | Checked `complaint.assignedCrewMemberId == crewUser.employeeId` | Delegates to `_authService.canSubmitFieldResolution` checking `assignedFieldOfficerId` |
| **`GovernmentCrewWorkService.reportBlockedIssue`** | Checked `complaint.assignedCrewMemberId == crewUser.employeeId` | Delegates to `_authService.canReportFieldObstacle` checking `assignedFieldOfficerId` |
| **`GovernmentCrewWorkService.resumeWorkAfterRework`** | Checked `complaint.assignedCrewMemberId == crewUser.employeeId` | Delegates to `_authService.canResumeFieldWork` checking `assignedFieldOfficerId` |
| **`GovernmentAuthorizationService`** | Missing `canReportFieldObstacle` & `canResumeFieldWork`; `canStartFieldWork` did not check `user.id` (UID) | Added missing methods; checks both `employeeId` and `id` (UID); enforces JE vs FO separation |
| **`ComplaintRoutingService`** | Execution methods matched only `user.employeeId` | Matches both `user.employeeId` and `user.id` against `assignedFieldOfficerId` |
| **`CrewFieldOperationsScreen`** | Showed raw `e.toString()` in snackbars | Sanitized to `"You are not assigned to this job."` on security/authorization errors |

---

### 2. Detailed Findings for Ganesh Kulkarni & Failing Complaint

#### Government Officer Identity Record:
- **Full Name:** Ganesh Kulkarni
- **Role:** `department_crew`
- **Employee ID:** `GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-02`
- **Firebase UID:** `rbQflILEPabot9t9EScfQmdmvn73`
- **Ward:** `R_SOUTH` (Ward R/South)
- **Department:** `maintenance_roads` (Roads & Maintenance)
- **Display Designation:** `Field Crew Technician 2 (Roads & Maintenance) - Ward R/South`

#### Canonical Complaint Record (`CF-2026-1791368464448000-a32fe69cef8b`):
- **`assignedJuniorEngineerId` / `assignedCrewMemberId`:** `GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-01` (Supervising Junior Engineer, e.g. Ramesh Powar)
- **`assignedFieldOfficerId`:** `GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-02` (Executing Field Officer, Ganesh Kulkarni)
- **`assignedFieldOfficerName`:** `Ganesh Kulkarni`
- **`assignedFieldOfficerDesignation`:** `Field Crew Technician 2 (Roads & Maintenance) - Ward R/South`
- **`assignmentStatus`:** `fieldOfficerAssigned`
- **`status`:** `assigned`

---

### 3. Canonical Assignment & Security Invariants Enforced

1. **One Canonical Execution Field (`assignedFieldOfficerId`):**
   - For all ground execution actions (**Start Job**, **Report Obstacle**, **Resume Rework**, **Submit Resolution**), `assignedFieldOfficerId` is the single source of truth.
   - If `assignedFieldOfficerId` is empty (legacy or unassigned state), fallback to `assignedCrewMemberId` is permitted for backward compatibility.

2. **Identity Alias Support (Employee ID & Firebase UID):**
   - Matching supports `user.employeeId` (e.g. `GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-02`) and `user.id` (e.g. `rbQflILEPabot9t9EScfQmdmvn73`).
   - Matching is case-insensitive and whitespace-trimmed.

3. **Strict Junior Engineer vs. Field Officer Separation:**
   - When a Junior Engineer dispatches a complaint to a Field Officer (`assignedFieldOfficerId != null`), the supervising Junior Engineer **cannot** start the job or submit resolution.
   - Attempting to bypass this throws an authorization violation.

4. **Zero Cross-Crew Leakage:**
   - Another crew member in the same Ward and Department unit cannot start or resolve a job assigned to Ganesh.

5. **SLA & Timeline Immutability:**
   - On `startJob`, `workStartedAt`, `workStartedBy`, and `routingStatus: inProgress` are recorded.
   - `slaStartedAt` and `originalCreatedAt` remain strictly untouched.

---

### 4. Verification Suite Results

#### Test Suites Run:
1. **`test/govt_ui/phase8_crew_work_service_test.dart`**
   - **Total Tests:** 17
   - **Passed:** 17 (100%)
   - **Coverage includes:** Section 6 (JE -> FO Separation & Start Job Auth Alignment, 4 tests).
2. **`test/core/services/phase2_field_officer_execution_test.dart`**
   - **Total Tests:** 48
   - **Passed:** 48 (100%)
   - **Coverage includes:** Ground execution, obstacle reporting, resume rework, resolution, and reassignment.
3. **`test/govt_ui/phase8_crew_field_operations_test.dart`**
   - **Total Tests:** 15
   - **Passed:** 15 (100%)
   - **Coverage includes:** RBAC gates, tab navigation, responsive viewport adaptation, and job queue rendering.

#### Static Analysis:
- `flutter analyze` executed with **0 issues found**.

---

### 5. Final Checklist & Sign-off

- [x] UI display and security authorization use the same canonical `assignedFieldOfficerId`.
- [x] Ganesh Kulkarni (`GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-02` / `rbQflILEPabot9t9EScfQmdmvn73`) successfully starts assigned jobs.
- [x] Supervising Junior Engineer is prevented from executing field work once delegated.
- [x] Unassigned crew members in the same ward/department are denied execution access.
- [x] All 4 operational execution actions (Start, Obstacle, Resume, Resolve) unified under `GovernmentAuthorizationService`.
- [x] User-facing error messages sanitized (`"You are not assigned to this job."`).
- [x] Zero Git commits or pushes made in compliance with instructions.
