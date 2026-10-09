import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix complaint status definitions.
final List<KnowledgeEntry> complaintStatusesKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'complaint_statuses_all',
    title: 'CivicFix Complaint Status Definitions',
    topic: 'statuses',
    audience: 'all',
    tags: [
      'status',
      'statuses',
      'meaning of status',
      'complaint status list',
      'status explanation',
    ],
    canonicalContent:
        'CivicFix complaints use standard canonical statuses:\n'
        '- "reported": The complaint has been submitted and registered with a unique ticket ID; continuous SLA tracking is active.\n'
        '- "underVerification": AI checks and municipal engineers are reviewing evidence, confirming jurisdiction, and validating category.\n'
        '- "assigned": The ticket is assigned to the Ward Junior Engineer and allocated to a Field Execution Officer.\n'
        '- "inProgress": Field Officer has reached the site and is actively executing physical on-ground remediation.\n'
        '- "resolved": Repair is completed, mandatory After-Work photo is uploaded, and citizen is notified.\n'
        '- "closed": Final administrative closure following supervisory quality review.\n'
        '- "blocked" (Modifier): Temporary hold during In Progress state due to logged physical obstacles (traffic, weather, access).\n'
        '- "reopened" (Modifier): Reopened by Ward Department Lead during quality review for required rework.',
    relatedTopics: [
      'lifecycle_overview',
      'field_execution_obstacles',
      'resolution_rework_workflow',
    ],
    sourceReference: 'Brain.md - Status Definitions',
  ),
  const KnowledgeEntry(
    id: 'status_reported',
    title: 'What "Reported" Means',
    topic: 'statuses',
    audience: 'citizen',
    tags: [
      'what does the reported status mean',
      'what does reported status mean',
      'what does reported mean',
      'reported status',
      'stage 1 reported',
    ],
    canonicalContent:
        'In CivicFix, Reported (Stage 1) means your complaint has been officially submitted and registered with a unique ticket ID in the system. The continuous SLA countdown clock begins immediately upon submission, and the ticket moves into Verification.',
    relatedTopics: [
      'lifecycle_reported',
      'sla_clock_start_policy',
    ],
    sourceReference: 'Brain.md - Reported Status Specification',
  ),
  const KnowledgeEntry(
    id: 'status_under_verification',
    title: 'What "Under Verification" Means',
    topic: 'statuses',
    audience: 'citizen',
    tags: [
      'what does under verification mean',
      'under verification',
      'verification status',
      'why is my complaint under verification',
      'stage 2 verification',
    ],
    canonicalContent:
        'In CivicFix, "Under Verification" is Stage 2 of the lifecycle. It means your complaint is currently being processed for verification of photo evidence, duplicate detection within the area, and routing to the Junior Engineer in the responsible BMC department.',
    relatedTopics: [
      'lifecycle_under_verification',
      'verification_ai_pipeline',
    ],
    sourceReference: 'Brain.md - Verification Stage Specification',
  ),
  const KnowledgeEntry(
    id: 'status_assigned',
    title: 'What "Assigned" Means',
    topic: 'statuses',
    audience: 'citizen',
    tags: [
      'what does assigned status mean',
      'what does assigned mean',
      'assigned status',
      'assigned to officer',
      'stage 3 assigned',
    ],
    canonicalContent:
        'In CivicFix, "Assigned" (Stage 3) means the complaint has been received by the Ward Junior Engineer and assigned to a dedicated Field Execution Officer (Field Officer / Field Squad) who will visit the site for physical repairs.',
    relatedTopics: [
      'lifecycle_assigned',
      'roles_junior_engineer',
      'roles_field_officer',
    ],
    sourceReference: 'Brain.md - Assigned Status Specification',
  ),
  const KnowledgeEntry(
    id: 'status_in_progress',
    title: 'What "In Progress" Means',
    topic: 'statuses',
    audience: 'citizen',
    tags: [
      'what does in progress mean',
      'in progress status',
      'work ongoing',
      'on-ground work',
      'stage 4 in progress',
    ],
    canonicalContent:
        'In CivicFix, "In Progress" (Stage 4) means the assigned Field Execution Officer has arrived on site, started on-ground repair work, and is actively executing physical remediation of the civic defect.',
    relatedTopics: [
      'lifecycle_in_progress',
      'field_execution_start_work',
    ],
    sourceReference: 'Brain.md - Field Execution Specification',
  ),
  const KnowledgeEntry(
    id: 'status_resolved',
    title: 'What "Resolved" Means',
    topic: 'statuses',
    audience: 'citizen',
    tags: [
      'what does resolved mean',
      'resolved status',
      'issue fixed',
      'completion',
      'stage 5 resolved',
    ],
    canonicalContent:
        'In CivicFix, "Resolved" (Stage 5) means the physical repair is complete and the Field Execution Officer has uploaded photographic proof of the finished work. The complaint enters a quality review audit before administrative closure.',
    relatedTopics: [
      'lifecycle_resolved',
      'evidence_after_work',
      'resolution_rework_workflow',
    ],
    sourceReference: 'Brain.md - Resolution Specification',
  ),
  const KnowledgeEntry(
    id: 'status_blocked',
    title: 'What "Blocked" Means',
    topic: 'statuses',
    audience: 'citizen',
    tags: [
      'what does blocked status mean',
      'blocked status',
      'blocked mean',
      'why is work blocked',
      'obstacle hold',
    ],
    canonicalContent:
        'In CivicFix, "Blocked" status indicates that repair work is temporarily paused due to a logged on-ground physical obstacle (such as heavy monsoon flooding, police clearance, or traffic obstruction). The documented obstacle reason is logged and the SLA timer continues.',
    relatedTopics: [
      'complaint_statuses_all',
      'sla_obstacle_pause_policy',
    ],
    sourceReference: 'Brain.md - Blocked Status Specification',
  ),
  const KnowledgeEntry(
    id: 'status_reopened',
    title: 'What "Reopened" Means',
    topic: 'statuses',
    audience: 'citizen',
    tags: [
      'what does reopened status mean',
      'reopened status',
      'reopened mean',
      'why is complaint reopened',
      'rework required',
    ],
    canonicalContent:
        'In CivicFix, "Reopened" status means a previously resolved complaint was rejected during supervisory Quality Review due to unsatisfactory, defective, or incomplete repair, and returned to the Field Officer for mandatory rework without resetting the SLA timer.',
    relatedTopics: [
      'resolution_rework_workflow',
      'rework_sla_preservation',
    ],
    sourceReference: 'Brain.md - Reopened Status Specification',
  ),
];
