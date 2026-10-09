import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix citizen troubleshooting and technical help.
final List<KnowledgeEntry> troubleshootingKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'troubleshoot_offline_queue',
    title: 'Offline Complaint Reporting & Sync Pending',
    topic: 'troubleshooting',
    audience: 'citizen',
    tags: [
      'offline',
      'no internet',
      'sync pending',
      'report offline',
      'queued complaint',
      'can i file a complaint when i dont have internet connection',
      'offline reporting',
    ],
    canonicalContent:
        'If you report a civic issue while offline or without internet connection, CivicFix automatically queues and stores your report in a secure local device queue. As soon as you reconnect to the internet, it automatically syncs to municipal servers.',
    relatedTopics: [
      'citizen_report_flow',
      'troubleshoot_upload_failure',
    ],
    sourceReference: 'Brain.md - Offline Sync Architecture',
  ),
  const KnowledgeEntry(
    id: 'offline_storage_hive',
    title: 'Where is my offline complaint saved on my device? (Local Hive Storage)',
    topic: 'troubleshooting',
    audience: 'all',
    tags: [
      'where is my offline complaint saved on my device',
      'where is my offline complaint saved',
      'offline complaint saved on my device',
      'saved on my device',
      'offline storage',
      'hive storage',
      'hive',
    ],
    canonicalContent:
        'In CivicFix, when reporting offline, complaints and photos are saved in secure local storage using Hive encrypted boxes on your device until network connection is available for upload.',
    relatedTopics: [
      'troubleshoot_offline_queue',
      'offline_autosync_policy',
    ],
    sourceReference: 'Brain.md - Local Hive Storage Architecture',
  ),
  const KnowledgeEntry(
    id: 'offline_autosync_policy',
    title: 'Automatic Offline-to-Online Sync Policy',
    topic: 'troubleshooting',
    audience: 'all',
    tags: [
      'will my complaint upload automatically when internet reconnects',
      'upload automatically when internet reconnects',
      'autosync',
      'reconnect sync',
    ],
    canonicalContent:
        'CivicFix monitors network connectivity. When your device reconnects to the internet, the background sync service automatically uploads all pending queued complaints to the server without requiring manual resubmission.',
    relatedTopics: [
      'troubleshoot_offline_queue',
      'offline_pending_sync_status',
    ],
    sourceReference: 'Brain.md - Background Sync Service',
  ),
  const KnowledgeEntry(
    id: 'offline_pending_sync_status',
    title: 'Pending Sync Status for Queued Complaints',
    topic: 'troubleshooting',
    audience: 'citizen',
    tags: [
      'what status is displayed for pending offline complaints',
      'status is displayed for pending offline complaints',
      'pending sync status',
      'offline status',
    ],
    canonicalContent:
        'For complaints created while offline, CivicFix displays a "Pending Sync" status badge in "My Complaints", indicating that the report is stored locally and waiting for an active internet connection to submit.',
    relatedTopics: [
      'troubleshoot_offline_queue',
      'citizen_track_flow',
    ],
    sourceReference: 'Brain.md - Offline State UI',
  ),
  const KnowledgeEntry(
    id: 'troubleshoot_location_gps',
    title: 'Troubleshooting GPS & Location Accuracy',
    topic: 'troubleshooting',
    audience: 'citizen',
    tags: [
      'gps not working',
      'wrong location',
      'location permission',
      'accuracy error',
    ],
    canonicalContent:
        'If your location is inaccurate or not detecting:\n1. Ensure "Location Services" (GPS) is turned ON in your device settings.\n2. Ensure CivicFix has "Precise Location" permission.\n3. In Step 3 of reporting, you can manually drag the pin on the interactive map to place it at the exact street defect spot.',
    relatedTopics: [
      'citizen_report_flow',
      'map_gis_overview',
    ],
    sourceReference: 'Brain.md - Location Guidance',
  ),
  const KnowledgeEntry(
    id: 'troubleshoot_upload_failure',
    title: 'Troubleshooting Photo Upload Failures',
    topic: 'troubleshooting',
    audience: 'citizen',
    tags: [
      'upload failed',
      'photo error',
      'retry upload',
      'image error',
    ],
    canonicalContent:
        'If photo upload fails during submission:\n1. Check your internet connection.\n2. Ensure the image is a standard JPG or PNG format under 15MB.\n3. Tap the "Retry" button on the submission screen. Your form inputs remain safely preserved.',
    relatedTopics: [
      'evidence_citizen_rules',
      'troubleshoot_offline_queue',
    ],
    sourceReference: 'Brain.md - Upload Resilience Guide',
  ),
  const KnowledgeEntry(
    id: 'troubleshoot_stuck_complaint',
    title: 'What to Do If a Complaint Seems Delayed',
    topic: 'troubleshooting',
    audience: 'citizen',
    tags: [
      'delayed complaint',
      'complaint not moving',
      'stuck in verification',
      'escalation',
    ],
    canonicalContent:
        'Complaints are monitored against strict category SLAs. If work is temporarily delayed, check the ticket timeline for any logged "Blocked" obstacles (such as monsoon waterlogging or traffic clearance). When an SLA is near breach or overdue, automated escalations notify Ward Officers and Zonal DMCs to accelerate action.',
    relatedTopics: [
      'sla_rules_overview',
      'field_execution_obstacles',
    ],
    sourceReference: 'Brain.md - Escalation Management',
  ),
];
