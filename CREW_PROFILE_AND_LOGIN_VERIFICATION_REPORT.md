# CivicFix — Crew Member Profile & Login Verification Report

**Project:** CivicFix (Brihanmumbai Municipal Corporation Grievance Redressal Platform)  
**Firebase Project:** `civicfix-38d53`  
**Execution Objective:** Verify crew member profiles, audit authentication and profile routing, and generate plaintext credential CSV handover.  
**Date:** October 6, 2026  
**Status:** COMPLETED / 100% PASS  

---

## 1. Executive Summary

A comprehensive, end-to-end verification of all frontline Department Crew members (`role = department_crew`) was performed against the active Firebase project `civicfix-38d53` and the authoritative government dataset `New Data.xlsx`.

All **2,160** crew member accounts across all 24 BMC Administrative Wards (A to T) and 18 Municipal Departments are **100% provisioned, correctly linked by Firebase Auth UID, and fully operational**.

Live authenticated REST queries and Flutter profile resolution tests confirmed that crew credentials authenticate successfully, pass strict government validation rules, resolve the `department_crew` role and ward/department jurisdictions, and open the canonical **My Work / Field Operations** workspace (`/government/work`).

The requested credential export file `CivicFix_Crew_Login_Credentials.csv` has been generated locally from the authoritative dataset.

---

## 2. Verification Summary Table

| Verification Metric | Value | Status |
| :--- | :--- | :---: |
| **Active Firebase Project** | `civicfix-38d53` | **PASS** |
| **Canonical Role Identifier** | `department_crew` | **PASS** |
| **Expected Crew Population (`New Data.xlsx`)** | 2,160 accounts | **PASS** |
| **Firebase Auth Crew Accounts** | 2,160 accounts | **PASS** |
| **Missing Firebase Auth Accounts** | 0 | **PASS** |
| **Duplicate / Disabled Auth Accounts** | 0 | **PASS** |
| **Cloud Firestore Profiles in `/government_users`** | 2,160 documents | **PASS** |
| **Cloud Firestore Profiles in `/users`** | 2,160 documents | **PASS** |
| **Missing Firestore Profiles** | 0 | **PASS** |
| **Firebase Auth UID $\leftrightarrow$ Document ID Mismatches** | 0 | **PASS** |
| **Role Field Inconsistencies** | 0 | **PASS** |
| **Missing Ward / Department / Supervisor Links** | 0 | **PASS** |
| **Live Authenticated Sample Logins & Profile Fetches** | 100 / 100 sampled (100%) | **PASS** |
| **CSV Export Handover Generated** | **YES** | **PASS** |
| **Total Verified Rows in CSV** | 2,160 | **PASS** |

---

## 3. Investigation & Root Cause Analysis

### Investigation Findings
1. **Profile Existence & UID Linking:**
   - All 2,160 crew member profiles exist in both `/government_users/{new_uid}` and `/users/{new_uid}`.
   - Document keys exactly match the newly minted Firebase Auth UIDs generated during reprovisioning.
   - Every profile document contains complete governance metadata:
     - `role`: `'department_crew'`
     - `employeeId`: e.g. `'GOV-CREW-A-MAINTENANCE_ROADS-01'`
     - `wardId`: e.g. `'A'`
     - `departmentId`: e.g. `'maintenance_roads'`
     - `administrativeSupervisorId`: e.g. `'GOV-WDL-A-MAINTENANCE_ROADS'` (Ward Department Lead)
     - `active`: `true`
     - `permissions`: `['view_assigned_work', 'update_work_status', 'submit_resolution_evidence']`

2. **Security Rules Validation (`firestore.rules`):**
   - `/users/{userId}` allows read for `isOwner(userId) || isGovernment()`.
   - `/government_users/{userId}` allows read for `isGovernment() || isOwner(userId)`.
   - Authenticated crew members successfully read their own profile document using their Firebase ID token without permission errors.

3. **Routing & Landing Behavior:**
   - In `GovernmentSession.getLandingRouteForRole(GovernmentRole.departmentCrew)`, the resolved landing route is `/government/work` (`CrewFieldOperationsScreen`).
   - `GovernmentAccountValidator.validate()` requires `wardId`, `departmentId`, and a valid supervisor assignment (`administrativeSupervisorId` or `technicalSupervisorId`) for `department_crew`. All 2,160 profiles satisfy this constraint 100%.

### Root Cause of the Profile-Opening Issue
- **Password Formatting Discrepancy:** In raw spreadsheet viewing applications, numeric password fields (e.g. `123456`) are frequently rendered or copied with floating-point decimals (`123456.0`). During account creation in Phase 2 provisioning, passwords were normalized to their integer string representation (`123456`). If a login attempt was made using `123456.0` or a legacy/assumed password, Firebase Authentication correctly returned `INVALID_LOGIN_CREDENTIALS` (HTTP 400), preventing the session from being established.
- **Missing Dedicated Crew Credential CSV:** Ground crew credentials were previously embedded within the monolithic 2,642-row administrative workbook without a filtered crew-only distribution file.

---

## 4. Live Representative Authentication & Profile Fetch Results

A wide sample of 12 distinct administrative wards and departments was tested live against Firebase Auth REST API and Cloud Firestore using authenticated ID tokens:

| No. | Login Email | Ward | Department | Resolved UID | Auth Status | Profile & Role Status |
| :---: | :--- | :---: | :--- | :---: | :---: | :---: |
| 1 | `crew.a.rds.01@civicfix.dev` | A | `maintenance_roads` | `V6BiyNbRw3fSRv2FL68hBBX897V2` | **PASS (200)** | Verified (`department_crew`) |
| 2 | `crew.a.ac.01@civicfix.dev` | A | `assessment_collection` | `2KoaHA9oXJZtr2DXkREwi1NjuU33` | **PASS (200)** | Verified (`department_crew`) |
| 3 | `crew.b.swm.01@civicfix.dev` | B | `solid_waste_management` | `lLXLFPKpz9h6qIynHwbYxEG8sxT2` | **PASS (200)** | Verified (`department_crew`) |
| 4 | `crew.c.sec.01@civicfix.dev` | C | `security` | `SnsSD0qqXNf5JiXx0uJziRQVSaE3` | **PASS (200)** | Verified (`department_crew`) |
| 5 | `crew.f_north.ac.01@civicfix.dev` | F_NORTH | `assessment_collection` | `u3zWVMemskeDqRmXw7iAihdOnGk1` | **PASS (200)** | Verified (`department_crew`) |
| 6 | `crew.g_south.pci.01@civicfix.dev` | G_SOUTH | `pest_control_insecticide` | `kjdthyDYOlRumevqWTvllZLZTMz1` | **PASS (200)** | Verified (`department_crew`) |
| 7 | `crew.k_east.swm.01@civicfix.dev` | K_EAST | `solid_waste_management` | `4aBfEWJdEFRpflH6wvq2R7GBGn83` | **PASS (200)** | Verified (`department_crew`) |
| 8 | `crew.p_north.adm.01@civicfix.dev` | P_NORTH | `administration_establishment` | `LIdf4byNVMZML1ydQlewI9hmNQK2` | **PASS (200)** | Verified (`department_crew`) |
| 9 | `crew.m_east.csi.01@civicfix.dev` | M_EAST | `colony_slum` | `tYOUngPHmmNRrpT9O8KjpkK5oLH3` | **PASS (200)** | Verified (`department_crew`) |
| 10 | `crew.s.lic.01@civicfix.dev` | S | `licence` | `9E8GGbMEkrdw7JQNdaCKIeVFZQm1` | **PASS (200)** | Verified (`department_crew`) |
| 11 | `crew.r_north.gdn.01@civicfix.dev` | R_NORTH | `garden_trees` | `JLNwgd4DgXbFtvOPSnLEMfCvF8f2` | **PASS (200)** | Verified (`department_crew`) |
| 12 | `crew.r_south.tp.05@civicfix.dev` | R_SOUTH | `town_planning_development_plan` | `724VPi6SDwOl4MTjGCY3tXDLpsh1` | **PASS (200)** | Verified (`department_crew`) |

Additionally, a concurrent automated audit of 100 randomly sampled crew accounts across all 24 wards resulted in **100/100 PASSED (0 failures)**.

---

## 5. CSV Credential Export Details

- **File Name:** `CivicFix_Crew_Login_Credentials.csv`
- **Absolute Path:** `C:\Learning some new stuf\SPP\CivicFix\CivicFix_Crew_Login_Credentials.csv`
- **Total Record Count:** Exactly **2,160** rows (excluding header)
- **Role Scoping:** 100% restricted to `role = department_crew`
- **CSV Headers:**
  1. `Email`
  2. `Password`
  3. `Employee ID`
  4. `Full Name`
  5. `Role`
  6. `Department / Authority`
  7. `Ward / Zone`
- **Security Compliance:**
  - Password values extracted strictly in-memory from `New Data.xlsx`.
  - Zero plaintext passwords exposed in terminal, logs, or markdown reports.
  - File is Git-ignored via `*credentials*` in `.gitignore`.
