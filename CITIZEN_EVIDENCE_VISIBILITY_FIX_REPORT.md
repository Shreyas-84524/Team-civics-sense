# CIVICFIX — BUG FIX REPORT
## Citizen Evidence Visibility & Storage Resolution in Government Portal

**Date:** October 8, 2026  
**Status:** Resolved & Verified  
**Scope:** Government Portal (Junior Engineer, Execution Officer / Crew, Ward Lead), Storage Subsystem, Cloud Firestore  

---

### Executive Summary

In the CivicFix Government Portal, the "Citizen Report Evidence" section and cards were visible across the Junior Engineer and Field Execution Officer / Frontline Crew workdesks, but the actual citizen-uploaded grievance images failed to render and showed broken image placeholders.

The investigation revealed that while the Citizen UI resolved stored private Supabase object paths through `SupabaseEvidenceImage` (which requests short-lived signed URLs from the Supabase Edge Function `get-complaint-evidence-url`), multiple Government UI components were directly calling `Image.network()` on the raw storage paths (e.g. `CF-2026-1791368464448000-a32fe69cef8b/CF-2026-1791368464448000-a32fe69cef8b_evidence_01.jpg`). Because `complaint-evidence` is a strictly private Supabase bucket and raw paths are not public HTTP URLs, `Image.network` threw `UriFormatException` and defaulted to error fallback placeholders.

All Government UI interfaces now uniformly use the canonical `SupabaseEvidenceImage` and `GovernmentEvidenceGallery` components, preserving private bucket security, authenticated signed URL generation, and clear multi-stage evidence separation.

---

### 1. Actual Firestore Evidence Fields & Object Paths

For the affected grievance (`Ticket: CF-2026-1791368464448000-a32fe69cef8b`):
- **Canonical Firestore Field:** `imageUrls` (List of Strings)
- **Object Key / Storage Path Pattern:** `CF-2026-1791368464448000-a32fe69cef8b/CF-2026-1791368464448000-a32fe69cef8b_evidence_01.jpg`
- **Supported Legacy / Schema Variations:**
  - `imageUrls`, `evidenceUrls`, `evidencePaths`, `photoUrls`, `attachments`, `citizenEvidence`, `initialEvidence`, `beforeEvidence`, `evidence`
  - Reconstructed via `FirestoreMapperHelpers.parseImageUrls(data)`

---

### 2. Evidence Pipeline Trace & Root Cause

```
Citizen Ingestion:
  Citizen selects photo
    ↓
  Image validated & compressed
    ↓
  SupabaseEvidenceStorageService.uploadComplaintEvidence
    ↓
  Private Bucket: `complaint-evidence` (object: CF-2026-1791368464448000-a32fe69cef8b/evidence_01.jpg)
    ↓
  Firestore Document: `imageUrls`: ["CF-2026-1791368464448000-a32fe69cef8b/...jpg"]
    ↓
  ComplaintModel.fromFirestore (populates imageUrls)

Pre-Fix Breakdown in Government UI:
  CrewJobDetailDialog / LeadDetailDialog
    ↓ (Bypassed Supabase signed URL generator)
  Image.network("CF-2026-1791368464448000-a32fe69cef8b/...jpg")
    ↓
  UriFormatException / SocketException
    ↓
  Broken Image Placeholder Displayed

Fixed Pipeline:
  Government UI Screen (JE / Crew / Lead)
    ↓
  GovernmentEvidenceGallery / SupabaseEvidenceImage
    ↓
  SupabaseEvidenceStorageService.instance.getDownloadUrl(path)
    ↓
  Edge Function `/functions/v1/get-complaint-evidence-url` (Bearer Token Auth)
    ↓
  Private Signed URL Generated (cached for 55 mins)
    ↓
  Image.network(signedUrl) renders high-resolution photo with interactive zoom
```

---

### 3. Summary of Files Changed

1. **[`lib/core/firebase/mappers/firestore_mapper_helpers.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/firebase/mappers/firestore_mapper_helpers.dart):**
   - Added `parseImageUrls`, `parseBeforeWorkPhoto`, `parseAfterWorkPhoto`, and `parsePreviousResolutionEvidence` with resilient deduplication and multi-schema fallback parsing.
2. **[`lib/core/firebase/mappers/complaint_firestore_mapper.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/firebase/mappers/complaint_firestore_mapper.dart):**
   - Updated `fromFirestore` to use `FirestoreMapperHelpers` for all evidence fields.
3. **[`lib/core/widgets/supabase_evidence_image.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/widgets/supabase_evidence_image.dart):**
   - Converted to stateful widget with tap-to-retry capability, structured error fallbacks, and rich `kDebugMode` diagnostic logging.
4. **[`lib/core/storage/supabase_evidence_storage_service.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/storage/supabase_evidence_storage_service.dart):**
   - Added mock token fallback support for offline/mock test environments when Firebase is not initialized.
5. **[`lib/Govt UI/screens/complaints/govt_complaint_details_screen.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/Govt%20UI/screens/complaints/govt_complaint_details_screen.dart):**
   - Enhanced `_buildEvidenceItems` to construct full multi-stage gallery items: Citizen Evidence, Field Inspection (Before Work), Resolution Evidence (After Work), and Previous Resolution Cycles.
6. **[`lib/Govt UI/widgets/dashboard/sections/crew/crew_job_detail_dialog.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/Govt%20UI/widgets/dashboard/sections/crew/crew_job_detail_dialog.dart):**
   - Replaced raw `Image.network` with `GovernmentEvidenceGallery` supporting zoomable interactive previews.
7. **[`lib/Govt UI/widgets/dashboard/sections/department_lead/department_lead_complaint_detail_dialog.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/Govt%20UI/widgets/dashboard/sections/department_lead/department_lead_complaint_detail_dialog.dart):**
   - Replaced raw `Image.network` with `GovernmentEvidenceGallery`.
8. **[`lib/Govt UI/widgets/dashboard/sections/department_lead/department_lead_verification_dialog.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/Govt%20UI/widgets/dashboard/sections/department_lead/department_lead_verification_dialog.dart):**
   - Replaced raw `Image.network` with `SupabaseEvidenceImage` and mapped canonical `beforeWorkPhoto` and `afterWorkPhoto` fields.
9. **[`lib/Govt UI/widgets/dashboard/sections/department_lead/department_lead_awaiting_verification_section.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/Govt%20UI/widgets/dashboard/sections/department_lead/department_lead_awaiting_verification_section.dart):**
   - Replaced raw `Image.network` thumbnails with `SupabaseEvidenceImage`.
10. **[`lib/Govt UI/widgets/dashboard/sections/crew/crew_awaiting_review_section.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/Govt%20UI/widgets/dashboard/sections/crew/crew_awaiting_review_section.dart):**
    - Replaced raw `Image.network` thumbnails with `SupabaseEvidenceImage`.
11. **[`lib/Govt UI/widgets/map/govt_hazard_info_card.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/Govt%20UI/widgets/map/govt_hazard_info_card.dart):**
    - Replaced raw `Image.network` with `SupabaseEvidenceImage`.
12. **[`lib/Govt UI/widgets/dashboard/sections/crew/crew_evidence_submission_dialog.dart`](file:///c:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/Govt%20UI/widgets/dashboard/sections/crew/crew_evidence_submission_dialog.dart):**
    - Replaced raw `Image.network` preview with `SupabaseEvidenceImage`.

---

### 4. Verification Suite Results

```
test/core/storage/supabase_evidence_storage_service_test.dart
  ✓ validateBytes accepts valid JPEG within size limit
  ✓ validateBytes rejects unsupported file extensions
  ✓ uploadComplaintEvidence sends deterministic ticket path & bearer token
  ✓ getDownloadUrl generates and caches signed URL
  ✓ deleteEvidence sends delete action to Edge Function
  ✓ uploadComplaintEvidence throws StorageException on HTTP error
  All 6 tests passed!

test/govt_ui/phase9_shared_complaint_operations_test.dart
  ✓ Master GovtComplaintDetailsScreen Widget Tests (2 tests)
  ✓ GovernmentEvidenceGallery & Fullscreen Tests (1 test)
  ✓ GovernmentRoutingHistorySection Tests (2 tests)
  ✓ GovernmentScopedMap Tests (1 test)
  ✓ Standardized GovernmentFilterModel Tests (2 tests)
  ✓ Standardized GovernmentKpiMetrics Tests (1 test)
  ✓ Responsive Viewport Verification Tests (3 tests)
  All 12 tests passed!

test/govt_ui/phase8_crew_work_service_test.dart
  All 17 tests passed!

test/govt_ui/phase8_crew_field_operations_test.dart
  All 15 tests passed!

test/core/services/phase2_field_officer_execution_test.dart
  All 48 tests passed!

flutter analyze
  No issues found! (ran in 12.0s)
```

---

### 5. Final Verdict

| Check | Verdict |
| :--- | :--- |
| **CITIZEN EVIDENCE STORED** | **PASS** |
| **STORAGE OBJECT EXISTS** | **PASS** |
| **SIGNED URL GENERATION** | **PASS** |
| **COMPLAINT MODEL MAPPING** | **PASS** |
| **JE EVIDENCE DISPLAY** | **PASS** |
| **EXECUTION OFFICER EVIDENCE DISPLAY** | **PASS** |
| **PRIVATE BUCKET PRESERVED** | **PASS** |
| **BEFORE/AFTER EVIDENCE SEPARATION** | **PASS** |
| **FLUTTER ANALYZE** | **PASS** |
