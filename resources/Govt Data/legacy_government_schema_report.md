# CivicFix — Legacy Government Schema & Architecture Report

> **Document Type:** Developer Architecture & Data Audit  
> **Phase:** 1 (Audit, Legacy Removal & Foundation Preparation)  
> **Target System:** Brihanmumbai Municipal Corporation (BMC / MCGM) Operations  
> **Status:** ARCHIVED & SUPERSEDED  

---

## 1. Executive Summary

This document captures the complete legacy government-side data model, hierarchy, collections, and authentication mechanisms in **CivicFix** prior to Phase 1 cleanup. This report serves as a permanent reference before replacing the old architecture with the new BMC-style hierarchical system.

---

## 2. Legacy Government Roles & Hierarchy

The legacy architecture implemented a flat 5-tier municipal officer model with a deterministic UID pattern (`MUM` + 2-character ward code + 5-digit serial):

| Tier | Legacy Role Identifier | Hierarchy Level | Count | Legacy Password | Scope / Responsibility |
| :---: | :--- | :--- | :---: | :---: | :--- |
| **1** | `Admin` / `admin` | Level 1 (Apex) | 1 | `[REDACTED_PURGED]` | Dr. Bhushan Gagrani, IAS (Municipal Commissioner & Administrator) |
| **2** | `Ward Officer` / `ward_officer` | Level 2 (Ward Executive) | 24 | `[REDACTED_PURGED]` | Assistant Municipal Commissioners (AMCs for Wards A through T) |
| **3** | `Ward Nagarsevak` / `nagarsevak` | Level 2 (Elected Representative) | 24 | `[REDACTED_PURGED]` | Municipal Corporators (Government of Maharashtra / BMC) |
| **4** | `Departmental Officer` / `dept_officer` | Level 3 (Ward Departmental Nodal) | 168 | `[REDACTED_PURGED]` | 1 Departmental Officer per department in each of 24 wards ($24 \times 7$) |
| **5** | `Field Engineer` / `engineer` | Level 4 (Ground Operations) | 840 | `[REDACTED_PURGED]` | 5 Field Engineers per department in each of 24 wards ($24 \times 7 \times 5$) |
| **Total** | **All Legacy Government Personnel** | | **1,057** | | **100% Deterministic Accounts** |

### Legacy Mathematical Model:
$$\text{Total Officers} = 1 + 24 + 24 + (24 \times 7) + (24 \times 7 \times 5) = 1 + 24 + 24 + 168 + 840 = \mathbf{1,057}$$

---

## 3. Existing Government Collections & Documents

### Firestore Collections Involved:
1. **`users` (`FirestoreCollections.users`)**:
   - Used for both Citizens (`role: 'citizen'`) and Government Officers (`role: 'government'` or `'admin'`).
   - Fields on legacy government docs: `id`, `fullName`, `email`, `employeeId`, `departmentId`, `departmentName`, `designation`, `assignedWard`, `phone`, `organization`, `role`, `permissions`, `createdAt`, `updatedAt`.
2. **`govt_users` (`FirestoreCollections.govtUsers`)**:
   - Registered constant for dedicated government officer profile documents.
3. **`departments` (`FirestoreCollections.departments`)**:
   - 7 BMC Technical Departments: Mechanical & Electrical (`BMC-M&E`), Roads (`BMC-RDS`), Solid Waste Management (`BMC-SWM`), Storm Water Drains (`BMC-SWD`), Hydraulic Engineer (`BMC-HYD`), Gardens (`BMC-GDN`), Sewerage Operations (`BMC-SEW`).
4. **`officers` (`FirestoreCollections.officers`)**:
   - Registered collection constant for officer entities.
5. **`complaints` (`FirestoreCollections.complaints`)**:
   - Contains grievance records filed by citizens and triaged by government personnel.
6. **`complaint_updates` / `complaints/{complaintId}/updates`**:
   - Timeline audit events tracking status changes and officer actions.

---

## 4. Existing Authentication Implementation

1. **Authentication Providers:**
   - **`FirebaseGovtAuthService` (`civic_app/lib/core/auth/firebase_govt_auth_service.dart`)**:
     * Authenticates officers via Firebase Auth using email/password (`$ID@civicfix.gov.in`).
     * Verifies claims via `request.auth.token.role in ['government', 'admin']` and Firestore user profile lookup `users/{uid}`.
     * Registers and manages FCM device tokens for government push alerts.
   - **`MockGovtAuthService` (`civic_app/lib/Govt UI/services/govt_auth_service.dart`)**:
     * In-memory mock service containing a hardcoded default officer (`govt_off_001`, `MC-2026-ENG-842`, `Shreyas S. (Executive Officer)`).

2. **Route Protection & Guards:**
   - **`AppRouter._protectedGovtRoute` (`civic_app/lib/core/routing/app_router.dart`)**:
     * Checks `govtAuth.isAuthenticated` and verifies role is `'government'` or `'admin'`.
     * Redirects unauthorized requests to `/govt/login`.
   - **`SplashScreen._checkAuthAndNavigate` (`civic_app/lib/User UI/screens/splash_screen.dart`)**:
     * Checks citizen session and separate government session; routes government users to `/govt/dashboard`.

---

## 5. Files Dependent on Legacy Architecture

| Category | File Path | Nature of Dependency |
| :--- | :--- | :--- |
| **Data Files** | `resources/Govt Data/government_officers.csv` | 1,057 legacy officer records |
| **Data Files** | `resources/Govt Data/government_officers.json` | 1,057 legacy officer JSON catalog |
| **Data Files** | `resources/Govt Data/government_officers.xls` | Excel binary workbook |
| **Data Files** | `resources/Govt Data/government_officers.xlsx` | Excel OOXML workbook |
| **Data Files** | `resources/Govt Data/README.md` | Legacy 1,057 officer system documentation |
| **App Models** | `civic_app/lib/Govt UI/models/department_model.dart` | `GovtOfficerModel` class and `defaultOfficers` mock array (`off_101`..`off_109`) |
| **App Models** | `civic_app/lib/Govt UI/models/govt_user_model.dart` | `GovtUserModel` with legacy fields (`assignedWard`, static permissions) |
| **Services** | `civic_app/lib/Govt UI/services/govt_auth_service.dart` | `MockGovtAuthService` with static `_defaultOfficer` |
| **Services** | `civic_app/lib/Govt UI/services/govt_complaint_repository.dart` | `getOfficers()` returning legacy `GovtOfficerModel.defaultOfficers` |
| **Services** | `civic_app/lib/core/repositories/offline_first_govt_complaint_repository.dart` | `getOfficers()` returning legacy `GovtOfficerModel.defaultOfficers` |
| **Mappers** | `civic_app/lib/core/firebase/mappers/department_firestore_mapper.dart` | `officerToFirestore` / `officerFromFirestore` using legacy `GovtOfficerModel` |
| **Screens** | `civic_app/lib/Govt UI/screens/complaints/govt_complaint_assignment_screen.dart` | Dropdown populated with legacy `GovtOfficerModel` list |
| **Security Rules** | `civic_app/firestore.rules` | `isGovernment()` helper and role checks |

---

## 6. Complaint Document References to Government Officers

The following fields in `complaints` documents refer to government officers and assignments:
- **`assignedTo`**: Stores the name or UID of the assigned officer/engineer (e.g. `'Officer A (Ramesh Patel)'` or legacy UID).
- **`departmentName`**: Municipal department assigned to handle the complaint.
- **`officerNotes`**: Internal notes or instructions appended by reviewing/assigning officers.
- **`timeline[].updatedBy`**: Name or UID of the officer who changed the complaint's status or created an audit event.

---

## 7. Plan for Phase 1 Cleanup & Removal

1. **Retain in `legacy_backup/`:**
   - All 5 legacy generated officer files (`.csv`, `.json`, `.xls`, `.xlsx`, `README.md`).
2. **Remove from active `resources/Govt Data/`:**
   - The 4 legacy officer files (`government_officers.*`) to prevent active runtime or build confusion.
3. **Preserve Verified BMC Data:**
   - `departments.json` (7 verified BMC departments).
   - `wards.json` (24 verified BMC administrative wards A through T).
4. **Clean In-Code Mock Records:**
   - Remove legacy mock officer instances (`defaultOfficers`, `_defaultOfficer`).
   - Clean up legacy mapper functions for mock officers (`officerToFirestore`, `officerFromFirestore`) while preserving department mappers.
   - Clean up repository methods that return legacy mock officer lists, replacing mock data references with clean empty/future-compatible contracts.
5. **Preserve Citizen Architecture:**
   - Citizen authentication, registration, phone verification, and profiles remain 100% intact and untouched.
   - Citizen complaint filing, viewing, upvoting, and tracking remain 100% intact.
6. **Prepare for Phase 2 Roles:**
   - Structure codebase for: `government_super_admin`, `zonal_dmc`, `central_department_hod`, `ward_officer`, `ward_department_lead`, and `department_crew`.
