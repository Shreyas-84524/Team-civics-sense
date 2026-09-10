# CivicFix — Cloud Storage Architecture & Evidence Management Specification

> **Version**: 1.0  
> **Status**: Approved Foundation  
> **Target Project**: `civicfix-38d53` (CivicFix)  
> **Architecture Principle**: Cloud Storage provides authoritative cloud persistence for photographic evidence and user avatars, while Hive stores local draft file paths and offline synchronization queues.

---

## 1. System Overview

CivicFix photographic evidence operations follow an **offline-first, layered architecture**. Citizen users capture or select grievance photos on their mobile devices, which are validated locally, cached in local device storage/Hive, and uploaded to Firebase Cloud Storage.

```text
[ Citizen App / Govt Web UI ]
            ↓
  [ EvidenceService (Local Media Capture) ]
            ↓
  [ ComplaintDraft / Hive Local Persistence ]
            ↓
  [ EvidenceStorageService (Validation & Progress) ]
     ├── MockEvidenceStorageService (Fast Local / CI Mock)
     └── FirebaseEvidenceStorageService (Production Cloud Storage)
            ↓
  [ Firebase Cloud Storage (GCS Bucket: civicfix-38d53.appspot.com) ]
```

---

## 2. Storage Directory Hierarchy & Path Conventions

To guarantee deterministic, non-conflicting namespaces and prevent directory traversal vulnerabilities, all files are stored under structured prefixes:

| Category | Storage Path Pattern | Description |
| :--- | :--- | :--- |
| **Complaint Evidence** | `complaint_evidence/{complaintId}/{sanitizedFileName}` | Primary path for citizen complaint photographic evidence. |
| **Structured Evidence** | `complaints/{complaintId}/images/{sanitizedFileName}` | Secondary structured path for complaint attachments. |
| **Citizen Avatars** | `user_avatars/{userId}/{sanitizedFileName}` | Profile avatar photos for citizen accounts. |
| **Officer Avatars** | `govt_avatars/{officerId}/{sanitizedFileName}` | Official avatar photos for municipal staff accounts. |

### File Name Sanitization
Before storing or uploading any file, file names are sanitized:
* Path separators (`/`, `\`) are stripped.
* Characters outside `[a-zA-Z0-9._-]` are replaced with underscores.
* Hidden file prefixes (leading `.`) are prefixed with `file`.
* Empty filenames default to `upload_{timestamp}.jpg`.

---

## 3. Media Validation & Constraints

All uploaded files are subjected to strict client-side and server-side verification:

| Parameter | Evidence Photos | User Avatars |
| :--- | :--- | :--- |
| **Maximum File Size** | 10 MB (`10 * 1024 * 1024` bytes) | 5 MB (`5 * 1024 * 1024` bytes) |
| **Minimum File Size** | 100 bytes (prevents empty/corrupt files) | 100 bytes |
| **Allowed MIME Types** | `image/jpeg`, `image/jpg`, `image/png`, `image/webp` | `image/jpeg`, `image/jpg`, `image/png`, `image/webp` |
| **Allowed Extensions** | `.jpg`, `.jpeg`, `.png`, `.webp` | `.jpg`, `.jpeg`, `.png`, `.webp` |
| **Inspection Method** | Magic byte inspection (file header signature) | Magic byte inspection |

### Magic Byte Header Signatures
* **JPEG**: `0xFF 0xD8 0xFF`
* **PNG**: `0x89 0x50 0x4E 0x47`
* **WEBP**: `RIFF....WEBP` (`0x52 0x49 0x46 0x46` and offset 8: `0x57 0x45 0x42 0x50`)

---

## 4. Security Rules Specification (`storage.rules`)

Cloud Storage Security Rules enforce least-privilege, authentication requirements, and MIME/size boundaries:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    function isAuthenticated() {
      return request.auth != null && request.auth.uid != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isValidEvidenceImage() {
      return request.resource != null
        && request.resource.size > 0
        && request.resource.size <= 10 * 1024 * 1024
        && request.resource.contentType.matches('image/(jpeg|jpg|png|webp)');
    }

    function isValidAvatarImage() {
      return request.resource != null
        && request.resource.size > 0
        && request.resource.size <= 5 * 1024 * 1024
        && request.resource.contentType.matches('image/(jpeg|jpg|png|webp)');
    }

    // Complaint evidence read/write
    match /complaint_evidence/{complaintId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow create, update: if isAuthenticated() && isValidEvidenceImage();
      allow delete: if isAuthenticated();
    }

    match /complaints/{complaintId}/images/{allPaths=**} {
      allow read: if isAuthenticated();
      allow create, update: if isAuthenticated() && isValidEvidenceImage();
      allow delete: if isAuthenticated();
    }

    // Avatar read/write
    match /user_avatars/{userId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow create, update: if isOwner(userId) && isValidAvatarImage();
      allow delete: if isOwner(userId);
    }

    match /govt_avatars/{officerId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow create, update: if isOwner(officerId) && isValidAvatarImage();
      allow delete: if isOwner(officerId);
    }

    // Default deny
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 5. Storage Metadata Schema

Every uploaded evidence object contains attached custom metadata for auditability, traceability, and downstream backend processes:

```json
{
  "contentType": "image/jpeg",
  "customMetadata": {
    "complaintId": "cmp_2026_0908_001",
    "uploaderId": "usr_citizen_842",
    "category": "cat_roads_pothole",
    "isHazard": "true",
    "latitude": "12.9716",
    "longitude": "77.5946",
    "uploadedAt": "2026-09-08T10:30:00.000Z"
  }
}
```

---

## 6. Error Handling Taxonomy

The `StorageErrorHandler` translates all platform and network exceptions into typed `StorageException` instances:

| Error Code | Recoverable? | User-Facing Message | Description |
| :--- | :---: | :--- | :--- |
| `object-not-found` | No | The requested image could not be found. | File does not exist at the given path. |
| `unauthenticated` | No | Please sign in to upload or access evidence photos. | Missing or expired auth credentials. |
| `unauthorized` | No | You do not have permission to perform this media action. | Rejected by Storage security rules. |
| `quota-exceeded` | No | Storage capacity temporarily exceeded. Please try again later. | Project GCS storage quota limit reached. |
| `retry-limit-exceeded` | Yes | Upload connection was unstable. Please check your network and retry. | Max retry timeout elapsed on slow link. |
| `invalid-checksum` | Yes | Image integrity verification failed during upload. Please retry. | MD5 hash mismatch during transfer. |
| `canceled` | No | Upload was canceled. | User canceled upload task. |
| `invalid-file` | No | File failed validation checks: [reason] | Size or MIME constraint violation. |
| `network-unavailable` | Yes | Unable to reach the server. Please check your internet connection. | Socket or connection failure. |
| `timeout` | Yes | The upload timed out. Please check your connection and try again. | Request timeout exceeded. |

---

## 7. Service Layer Structure

The storage implementation is located under `lib/core/firebase/storage/`:

```text
lib/core/firebase/storage/
├── evidence_storage_models.dart       // EvidenceFileValidation, EvidenceMetadata, EvidenceUploadResult, EvidenceUploadProgress
├── evidence_storage_service.dart      // Abstract service interface
├── firebase_evidence_storage_service.dart // Production Firebase Cloud Storage implementation
├── mock_evidence_storage_service.dart     // In-memory test & simulation service
└── storage_error_handler.dart         // Typed StorageException & error translator
```

---

## 8. Integration Lifecycle with Offline Sync

1. **Local Media Selection**: Citizen captures photo via camera or picks from gallery -> local file URI saved in `EvidenceItem` / `ComplaintDraft`.
2. **Offline Queuing**: When offline, draft is stored in Hive box `pending_sync` with local media references.
3. **Synchronization Trigger**: When network is restored, `SyncManager` executes `FirebaseSyncProvider` (to be implemented in subsequent prompts).
4. **Cloud Media Upload**: `EvidenceStorageService.uploadComplaintEvidence()` uploads the file, retrieves the download URL, and replaces local references with remote Storage URLs in the Firestore `ComplaintModel.imageUrls` array.
