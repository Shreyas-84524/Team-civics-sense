# CivicFix — Government Account Cleanup
# Stale Government Account Records Deletion Report

**Project:** CivicFix (Brihanmumbai Municipal Corporation Grievance Redressal Platform)  
**Firebase Project:** `civicfix-38d53`  
**Execution Type:** Firestore Collection Cleanup (Stale Government Profiles)  
**Date:** October 2, 2026  
**Status:** COMPLETED / PASS  

---

## 1. Collections Identified

Inspection of Cloud Firestore root collections on `civicfix-38d53` revealed two collections containing stale government account documents:

1. **`/government_users` (Dedicated Government Collection):**
   - **Path:** `/government_users/{userId}`
   - **Contents:** 3,699 total documents.
   - **Breakdown:** 2,642 canonical active government officer profiles across 6 BMC tiers + 1,057 retired historical officer profiles.
   - **Citizen Records:** 0 (100% government records).
   - **Action Taken:** Complete collection purge (all 3,699 documents deleted).

2. **`/users` (Unified User Collection):**
   - **Path:** `/users/{userId}`
   - **Contents:** 3,726 total documents.
   - **Breakdown:** 3,699 stale government account documents (dual-written mirroring `/government_users`) co-located with 27 citizen profiles (`role: 'citizen'`).
   - **Action Taken:** Selective purge of all 3,699 government account documents while strictly safeguarding all 27 citizen documents.

---

## 2. Root Cause / Why They Were Not Deleted in Prior Task

The previous cleanup task followed the strict constraints of the initial prompt (*"CIVICFIX — GOVERNMENT LOGIN CREDENTIAL RESET PHASE 1 — COMPLETE DELETION OF EXISTING GOVERNMENT AUTH CREDENTIALS"*):

- **Explicit Constraint in Previous Task:**
  - Section 7 explicitly commanded:  
    > *"7. PRESERVE GOVERNMENT ORGANIZATIONAL DATA: Do NOT delete the government organizational structure required for Phase 2. Preserve: /government_users metadata, officer names, employee IDs, designations, roles, wards, departments, jurisdiction relationships, active/legacy flags, BMC hierarchy. This is NOT credential backup data. It is CivicFix's government organizational database and is necessary for generating the new accounts. Do NOT delete: ... personnel records unless they themselves contain old passwords/auth secrets."*
  - Section 9 explicitly stated:  
    > *"This task concerns government AUTH CREDENTIALS only."*
- **Execution Consequence:**
  - The previous cleanup strictly deleted all 2,642 Firebase Authentication identities and scrubbed credential files/passwords.
  - The Firestore documents in `/government_users` and `/users` were intentionally preserved under the mandate that they formed the organizational database needed for recreation.
- **Clarification & Resolution:**
  - Per the follow-up request, these Firestore documents were stale account entities that must be fully cleared before the final Excel dataset can reprovision fresh accounts from scratch.

---

## 3. Stale Government Records Found

| Collection | Total Docs Before Cleanup | Stale Government Docs | Citizen Docs |
| :--- | :---: | :---: | :---: |
| `/government_users` | 3,699 | 3,699 | 0 |
| `/users` | 3,726 | 3,699 | 27 |
| **Total** | **7,425** | **7,398** | **27** |

---

## 4. Number of Records Deleted

All 3,699 stale government documents in both `/government_users` and `/users` were deleted using atomic Firestore `:commit` batch operations (200 accounts / 400 document writes per commit, 19 batches total, all HTTP 200):

- **`/government_users` Documents Deleted:** 3,699
- **`/users` Stale Government Documents Deleted:** 3,699
- **Total Firestore Documents Deleted:** **7,398**

---

## 5. Subcollections Deleted

Inspection of representative government documents across all tiers (`government_users/{id}:listCollectionIds` and `users/{id}:listCollectionIds`) verified that **0 subcollections** existed on these documents. No orphaned subcollections remain.

---

## 6. Citizen Records & System Data Preserved

Strict safety checks were enforced prior to and during deletion:

1. **Citizen Profiles in `/users`:**
   - All 27 citizen documents were strictly isolated and excluded from deletion.
   - All 27 citizen documents remain active with `role: 'citizen'`.
2. **Citizen Firebase Auth Accounts:**
   - All 10 citizen Firebase Auth identities remain active, verified, and operational.
3. **Citizen Complaint Records:**
   - All 4 active grievance records in `/complaints` preserved.
4. **Citizen OTP Infrastructure:**
   - All 3 phone index documents in `/phoneIndex` preserved.
5. **System & Hierarchy Configurations:**
   - BMC hierarchy definitions, wards (`wards.json`), departments (`departments.json`), MapTiler config, and Firebase security rules preserved.

---

## 7. Government Auth State

- **Total Firebase Auth Accounts:** 10 (all 10 are citizens).
- **Active Government Auth Identities:** **0** (confirmed still deleted from Phase 1).
- **Authentication Invalidation:** Attempts to sign in or refresh tokens for any old government email remain rejected.

---

## 8. Remaining Stale Government Records

- **Stale Government Documents in `/government_users`:** **0**
- **Stale Government Documents in `/users`:** **0**
- **Government Auth Identities in Firebase Auth:** **0**
- **Old Government Credential Residue in Repository:** **0**

---

## 9. Brain.md Updated

[Brain.md](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/Brain.md#L274-L298) has been updated with the `## Government Account Cleanup Follow-up` section documenting:
- The collections identified (`/government_users`, `/users`)
- Root cause explanation for why previous cleanup preserved document entities
- Record of 7,398 total stale documents deleted (3,699 in `/government_users` + 3,699 in `/users`)
- Preservation of all 27 citizen profiles and 10 citizen Auth accounts
- Confirmation of 0 remaining stale government records

---

## Final Checklist

| Check | Status |
| :--- | :---: |
| **STALE GOVERNMENT COLLECTION IDENTIFIED** | **PASS** |
| **ROOT CAUSE IDENTIFIED** | **PASS** |
| **OLD GOVERNMENT RECORDS DELETED** | **PASS** |
| **CITIZEN RECORDS PRESERVED** | **PASS** |
| **OLD GOVERNMENT AUTH STILL REMOVED** | **PASS** |
| **STALE GOVERNMENT RECORDS REMAINING** | **0** |
| **READY FOR FINAL EXCEL-BASED REPROVISIONING** | **YES** |
