# Phase 1: Government Architecture Cleanup & Backend Preparation Report

> **Project:** CivicFix (Flutter + Firebase)  
> **Phase:** 1 — Government Role Architecture Cleanup  
> **Date:** September 27, 2026  
> **Status:** COMPLETED / PASS  

---

## 1. Old Roles Found

The legacy government architecture utilized a 5-tier municipal officer model:
1. **`Admin` (`admin`)**: Municipal Commissioner & Administrator (1 account: `Dr. Bhushan Gagrani, IAS`, UID: `MUMHQ00001`, password: `mum_admin`).
2. **`Ward Officer` (`ward_officer`)**: Assistant Municipal Commissioners (24 accounts: 1 per ward for Wards A–T, password: `mum_wardoff`).
3. **`Ward Nagarsevak` (`nagarsevak`)**: Municipal Corporators (24 accounts: 1 per ward, password: `mum_nagarsevak`).
4. **`Departmental Officer` (`dept_officer`)**: Departmental Nodal Officers (168 accounts: 24 wards $\times$ 7 departments, password: `mum_dept`).
5. **`Field Engineer` (`engineer`)**: On-field inspection & maintenance engineers (840 accounts: 24 wards $\times$ 7 departments $\times$ 5 engineers, password: `mum_engg`).

**Total Legacy Government Roster:** 1,057 personnel across 24 wards and 7 technical departments.

---

## 2. Old Firebase Collections Found

1. **`users` (`FirestoreCollections.users`)**: Contained mixed citizen profiles (`role: 'citizen'`) and legacy government profiles (`role: 'government'`, `role: 'admin'`).
2. **`govt_users` (`FirestoreCollections.govtUsers`)**: Registry constant for dedicated government officer profile records.
3. **`officers` (`FirestoreCollections.officers`)**: Registry constant for field maintenance officers.
4. **`departments` (`FirestoreCollections.departments`)**: 7 municipal technical departments.
5. **`complaints` (`FirestoreCollections.complaints`)**: Grievances filed by citizens and triaged by government personnel.
6. **`phoneIndex` (`FirestoreCollections.phoneIndex`)**: Phone-to-UID index for SMS OTP verification (citizen-only, preserved).

---

## 3. Number of Old Government Accounts Found

- **Static/CSV/JSON Generated Dataset:** 1,057 officer records.
- **In-Memory Hardcoded Mock Officers:** 9 mock personnel (`off_101` through `off_109`) in `GovtOfficerModel.defaultOfficers`.
- **Live Firestore Government User Documents:** 2 documents:
  - `lXL56cvYhsa8CJhyW3qksgM0kon1` (`muma001001@civicfix.gov.in` — Assistant Municipal Commissioner Santoshkumar Dhonde)
  - `riC922waQ4SVX8QkcChywRmaP7f1` (`mumhq00001@civicfix.gov.in` — Municipal Commissioner Dr. Bhushan Gagrani, IAS)
- **Live Firebase Auth Government Accounts:** 2 accounts corresponding to the above UIDs.

---

## 4. Number of Accounts Removed / Cleaned

- **Generated Legacy Dataset:** 1,057 records archived to `legacy_backup/` and removed from active dataset folder.
- **Mock Model Array:** 9 mock officer records removed from `GovtOfficerModel.defaultOfficers`.
- **Firestore Documents Removed:** 2 government officer documents deleted (`lXL56cvYhsa8CJhyW3qksgM0kon1`, `riC922waQ4SVX8QkcChywRmaP7f1`).
- **Citizen Accounts Touched:** **0** (All 7 active citizen Firestore documents and 10 citizen Auth accounts preserved 100%).

---

## 5. Firebase Auth Accounts Removed / Disabled

- **`lXL56cvYhsa8CJhyW3qksgM0kon1`** (`muma001001@civicfix.gov.in`): Disabled in Firebase Authentication.
- **`riC922waQ4SVX8QkcChywRmaP7f1`** (`mumhq00001@civicfix.gov.in`): Disabled in Firebase Authentication.
- No citizen auth accounts were modified or deleted.

---

## 6. Files Deleted / Archived to `legacy_backup/`

### Archived to `resources/Govt Data/legacy_backup/`:
1. `resources/Govt Data/government_officers.csv`
2. `resources/Govt Data/government_officers.json`
3. `resources/Govt Data/government_officers.xls`
4. `resources/Govt Data/government_officers.xlsx`
5. `resources/Govt Data/README.md` (Original legacy specification)

### Removed from Active Directory:
- The 4 legacy generated files (`government_officers.csv`, `government_officers.json`, `government_officers.xls`, `government_officers.xlsx`) were removed from active `resources/Govt Data/` to ensure no accidental runtime or build linkage.

---

## 7. Files Modified

1. **`resources/Govt Data/README.md`**: Updated to document directory structure, legacy backup location, active BMC metadata (`departments.json`, `wards.json`), and upcoming Phase 2 roles.
2. **`resources/Govt Data/legacy_government_schema_report.md`**: Created comprehensive schema report before cleanup.
3. **`civic_app/lib/Govt UI/models/department_model.dart`**: Removed hardcoded `defaultOfficers` array (`off_101`..`off_109`); added Phase 1 cleanup deprecation notice.
4. **`civic_app/lib/Govt UI/models/govt_user_model.dart`**: Added architectural roadmap comments for upcoming 6-tier Phase 2 BMC roles.
5. **`civic_app/lib/Govt UI/services/govt_complaint_repository.dart`**: Cleaned `MockGovtComplaintRepository.getOfficers()` to return `const []`.
6. **`civic_app/lib/core/repositories/offline_first_govt_complaint_repository.dart`**: Cleaned `OfflineFirstGovtComplaintRepository.getOfficers()` to return `const []`.
7. **`civic_app/lib/Govt UI/screens/complaints/govt_complaint_assignment_screen.dart`**: Updated assignment workflow to handle empty officer lists gracefully and assign directly to department crew without assuming legacy mock UIDs.
8. **`civic_app/firestore.rules`**: Cleaned `isGovernment()` helper function by removing legacy `admin` claim check while preserving all citizen security rules.

---

## 8. Complaint Fields Migrated / Cleared

- Live Firestore `complaints` collection was inspected: 0 orphaned complaints existed.
- In-memory/local mock complaints maintain clean `assignedTo` strings without referencing legacy officer UIDs.
- All complaint core attributes preserved: `id`, `citizenId`, `ticketNumber`, `title`, `description`, `category`, `status`, `priority`, `location`, `imageUrls`, `createdAt`, `updatedAt`, `timeline`, `upvotes`, `isHazard`, `aiAuthenticity`.

---

## 9. Security Rule Changes

- Cleaned `isGovernment()` helper in `firestore.rules`:
  ```javascript
  function isGovernment() {
    return isSignedIn() && (
      request.auth.token.role == 'government' ||
      (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'government')
    );
  }
  ```
- Legacy `request.auth.token.role == 'admin'` check removed.
- All citizen security rules, privilege escalation guards, and field-level validation rules remain 100% active and verified.

---

## 10. Remaining Government-Related Architecture

The project now maintains a clean, decoupled skeleton ready for Phase 2:
- **Routing & Shell Screens:** `GovtShellScreen`, `GovtDashboardScreen`, `GovtComplaintListScreen`, `GovtComplaintDetailsScreen`, `GovtComplaintAssignmentScreen`, `GovtHazardMapScreen`, `GovtAnalyticsScreen`, `GovtProfileScreen`.
- **Contracts & Repositories:** `GovtComplaintRepository`, `GovtUserRepository`, `AnalyticsRepository`, `OfflineFirstGovtComplaintRepository`.
- **Verified BMC Metadata:** `departments.json` (7 BMC Departments) and `wards.json` (24 BMC Administrative Wards).
- **Upcoming Phase 2 Roles Foundation:**
  1. `government_super_admin` (Apex Leadership: Municipal Commissioner & Addl. MC)
  2. `zonal_dmc` (Zonal Deputy Municipal Commissioners)
  3. `central_department_hod` (Department Chief Engineers / Heads)
  4. `ward_officer` (Assistant Municipal Commissioners / AMCs)
  5. `ward_department_lead` (Ward Departmental Leads / Executive Engineers)
  6. `department_crew` (Sub-Engineers & Field Crews)

---

## 11. Flutter Analyze Result

```text
Analyzing civic_app...
No issues found! (ran in 11.4s)
```

---

## 12. Test Results

```text
622 / 622 tests passed! (100% PASS)
- 0 failures
- 0 errors
- 0 regressions
```

---

## 13. Legacy Dependencies Intentionally Retained and Why

1. **`departments.json` & `wards.json`**: Retained in `resources/Govt Data/` because they contain authentic, verified Brihanmumbai Municipal Corporation geographic ward boundaries (Wards A–T) and 7 core municipal departments with SLAs. These will form the foundation for Phase 2 ward-to-department hierarchy mapping.
2. **`GovtOfficerModel` class declaration**: Retained as a clean Dart model shell (without hardcoded mock data) so that existing repository contracts compile cleanly until Phase 2 replaces it with the full hierarchical BMC staff entity.
3. **`GovtUserModel`**: Retained as the base government user profile model, cleanly prepared for Phase 2 6-tier role enums and custom claims.
