import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix evidence guidelines, media validation, and storage rules.
final List<KnowledgeEntry> evidenceRulesKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'evidence_rules_overview',
    title: 'CivicFix Photographic Evidence Architecture',
    topic: 'evidence',
    audience: 'all',
    tags: [
      'evidence',
      'photos',
      'pictures',
      'camera',
      'gallery',
      'proof',
      'image rules',
    ],
    canonicalContent:
        'CivicFix requires rigorous photographic evidence across the complaint lifecycle:\n'
        '1. Citizen Evidence: 1 to 3 photos submitted by the citizen showcasing the civic defect and surrounding context.\n'
        '2. Before-Work Evidence: Captured on arrival by the Field Officer if site conditions have altered.\n'
        '3. After-Work Evidence: Mandatory photograph showing completed physical remediation before the issue can be marked "Resolved".\n'
        '4. Previous Resolution Evidence: Preserved when a complaint is reopened for rework to allow side-by-side quality comparison.\n'
        'All media is securely stored in private cloud storage and accessed exclusively via short-lived signed URLs.',
    relatedTopics: [
      'evidence_citizen_rules',
      'evidence_after_work',
      'resolution_rework_workflow',
    ],
    sourceReference: 'Brain.md - Evidence Subsystem Specification',
  ),
  const KnowledgeEntry(
    id: 'evidence_citizen_rules',
    title: 'Citizen Photo Evidence Rules',
    topic: 'evidence',
    audience: 'citizen',
    tags: [
      'photo guidelines',
      'how many photos',
      'take photo',
      'camera rules',
      'upload photo',
    ],
    canonicalContent:
        'When reporting an issue:\n'
        '- Citizens can attach up to 3 clear photos.\n'
        '- Photos can be captured live in real-time using the in-app Camera or selected from the device Gallery.\n'
        '- Best Practice: Capture one close-up photo showing the defect (e.g. pothole depth) and one wide-angle shot showing landmarks to assist the field crew.\n'
        '- Photos are automatically compressed and scanned for appropriate civic content during Stage 2 verification.',
    relatedTopics: [
      'citizen_report_flow',
      'verification_ai_pipeline',
    ],
    sourceReference: 'Brain.md - Citizen Reporting Guidelines',
  ),
  const KnowledgeEntry(
    id: 'evidence_live_camera',
    title: 'Live Camera Capture vs. Gallery Upload',
    topic: 'evidence',
    audience: 'citizen',
    tags: [
      'can i upload photos from the camera in real-time',
      'live camera',
      'real-time camera',
      'camera upload',
    ],
    canonicalContent:
        'In CivicFix, citizens can capture photos directly in real-time using the built-in live camera during Step 2 of reporting, or select pre-captured photos from their device gallery. Live camera capture automatically validates timestamp and GPS coordinates.',
    relatedTopics: [
      'evidence_citizen_rules',
      'evidence_exif_metadata',
    ],
    sourceReference: 'Brain.md - Live Camera Specification',
  ),
  const KnowledgeEntry(
    id: 'evidence_exif_metadata',
    title: 'Anti-Fraud EXIF & GPS Metadata Validation',
    topic: 'evidence',
    audience: 'all',
    tags: [
      'how does civicfix detect photo tampering and gps fraud',
      'photo tampering',
      'gps fraud',
      'exif metadata',
      'tamper detection',
    ],
    canonicalContent:
        'CivicFix detects photo tampering and GPS fraud by inspecting embedded EXIF metadata, timestamp validity, and spatial coordinates. Photos submitted outside the reporting radius or detected as spoofed/manipulated are flagged during Stage 2 Verification.',
    relatedTopics: [
      'verification_ai_pipeline',
      'evidence_rules_overview',
    ],
    sourceReference: 'Brain.md - Anti-Fraud & Metadata Validation',
  ),
  const KnowledgeEntry(
    id: 'evidence_duplicate_detection',
    title: 'Spatial Duplicate Detection Within Radius',
    topic: 'evidence',
    audience: 'all',
    tags: [
      'how does civicfix detect duplicate complaints within a radius',
      'duplicate complaints within a radius',
      'duplicate detection',
      'spatial clustering',
      'duplicate radius',
    ],
    canonicalContent:
        'CivicFix detects duplicate complaints by calculating spatial proximity across existing active complaints within a geographic cluster radius (e.g. 50 meters for road potholes). Similar category reports in the same radius are linked to prevent duplicate dispatch.',
    relatedTopics: [
      'verification_ai_pipeline',
      'lifecycle_under_verification',
    ],
    sourceReference: 'Brain.md - Spatial Deduplication Engine',
  ),
  const KnowledgeEntry(
    id: 'evidence_officer_proof',
    title: 'Field Officer Mandatory Completion Proof',
    topic: 'evidence',
    audience: 'all',
    tags: [
      'what proof must a field officer provide after completing work',
      'field officer provide after completing work',
      'officer completion proof',
      'after work proof',
    ],
    canonicalContent:
        'After completing physical work on site, the Field Execution Officer must provide mandatory After-Work photographic proof with accurate timestamp and location metadata showing the rectified defect before marking the complaint Resolved.',
    relatedTopics: [
      'evidence_after_work',
      'roles_field_officer',
      'lifecycle_resolved',
    ],
    sourceReference: 'Brain.md - Officer Completion Evidence',
  ),
  const KnowledgeEntry(
    id: 'evidence_after_work',
    title: 'Mandatory After-Work Resolution Evidence',
    topic: 'evidence',
    audience: 'all',
    tags: [
      'after photo',
      'resolution photo',
      'proof of fix',
      'mandatory evidence',
    ],
    canonicalContent:
        'A complaint cannot be transitioned to "Resolved" without an After-Work photo. The Field Execution Officer must capture a clear photograph of the completed repair at the exact location. This proof is sent to the citizen and reviewed by the Ward Department Lead during quality audit.',
    relatedTopics: [
      'lifecycle_resolved',
      'roles_field_officer',
      'resolution_rework_workflow',
    ],
    sourceReference: 'Brain.md - Resolution Evidence Invariant',
  ),
];
