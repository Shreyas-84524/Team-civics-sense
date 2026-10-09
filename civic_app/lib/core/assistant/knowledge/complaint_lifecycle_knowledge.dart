import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix 5-stage complaint lifecycle and rework workflow.
final List<KnowledgeEntry> complaintLifecycleKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'lifecycle_overview',
    title: 'CivicFix 5-Stage Complaint Lifecycle',
    topic: 'lifecycle',
    audience: 'all',
    tags: [
      'lifecycle',
      'stages',
      'process',
      'workflow',
      'what happens after submit',
      'complaint steps',
      'workflow from start to finish',
      'stages of a complaint in civicfix',
      'start to finish',
    ],
    canonicalContent:
        'After you submit a complaint, it goes through a 5-stage workflow:\n'
        '1. Reported: Your grievance is logged with a unique ticket number and SLA tracking begins.\n'
        '2. Under Verification: The evidence is reviewed, duplicates are checked, and routed to the correct BMC department.\n'
        '3. Assigned: A Junior Engineer in your Ward assigns a Field Execution Officer (Field Officer).\n'
        '4. In Progress: The Field Officer begins on-site repair work.\n'
        '5. Resolved: The repair is completed with mandatory after-work photo evidence and proof.\n'
        'Following resolution, the Ward Department Lead audits the repair in Quality Review; if defective, it is reopened for rework without resetting the SLA timer.',
    relatedTopics: [
      'lifecycle_reported',
      'lifecycle_under_verification',
      'lifecycle_assigned',
      'lifecycle_in_progress',
      'lifecycle_resolved',
      'resolution_rework_workflow',
      'sla_rules_overview',
    ],
    sourceReference: 'Brain.md - 5-Stage Lifecycle Architecture',
  ),
  const KnowledgeEntry(
    id: 'lifecycle_reported',
    title: 'Stage 1 — Reported',
    topic: 'lifecycle',
    audience: 'all',
    tags: [
      'reported',
      'stage 1',
      'ticket created',
      'sla start',
      'submission',
    ],
    canonicalContent:
        'Stage 1 (Reported): The complaint is received by the system. A unique reference ticket (e.g. CF-2026-000042) is generated, geotagged location coordinates and timestamps are recorded, and the continuous SLA countdown begins immediately upon submission.',
    relatedTopics: [
      'citizen_report_flow',
      'sla_rules_overview',
    ],
    sourceReference: 'Brain.md - Lifecycle Stage 1',
  ),
  const KnowledgeEntry(
    id: 'lifecycle_under_verification',
    title: 'Stage 2 — Under Verification',
    topic: 'lifecycle',
    audience: 'all',
    tags: [
      'under verification',
      'stage 2',
      'verification',
      'ai check',
      'department check',
      'validating',
      'what occurs during the under verification stage',
    ],
    canonicalContent:
        'Stage 2 (Under Verification): The complaint undergoes validation to ensure image authenticity, check for duplicate reports within the geographic radius, filter inappropriate content, and route to the Junior Engineer in the responsible BMC department.',
    relatedTopics: [
      'verification_ai_pipeline',
      'verification_fallback',
    ],
    sourceReference: 'Brain.md - Lifecycle Stage 2',
  ),
  const KnowledgeEntry(
    id: 'lifecycle_assigned',
    title: 'Stage 3 — Assigned',
    topic: 'lifecycle',
    audience: 'all',
    tags: [
      'assigned',
      'stage 3',
      'junior engineer',
      'field officer',
      'dispatch',
      'allocation',
      'what happens during the assigned stage',
    ],
    canonicalContent:
        'Stage 3 (Assigned): The complaint is routed to the least-loaded Junior Engineer (JE) in the designated Ward and Department. The Junior Engineer reviews the grievance and dispatches a dedicated Field Execution Officer (Field Officer / Field Squad) for ground remediation.',
    relatedTopics: [
      'roles_junior_engineer',
      'roles_field_officer',
      'assignment_workflow',
    ],
    sourceReference: 'Brain.md - Lifecycle Stage 3',
  ),
  const KnowledgeEntry(
    id: 'lifecycle_in_progress',
    title: 'Stage 4 — In Progress',
    topic: 'lifecycle',
    audience: 'all',
    tags: [
      'in progress',
      'stage 4',
      'remediation',
      'ground repair',
      'field work',
      'obstacles',
      'blocked',
    ],
    canonicalContent:
        'Stage 4 (In Progress): The assigned Field Execution Officer arrives on site, verifies conditions, and taps "Start Work". Physical on-ground remediation begins. If physical blockers occur (e.g. heavy rain, traffic, access issues), the officer marks the status as Blocked with a documented reason, and resumes once cleared.',
    relatedTopics: [
      'field_execution_start_work',
      'field_execution_obstacles',
    ],
    sourceReference: 'Brain.md - Lifecycle Stage 4',
  ),
  const KnowledgeEntry(
    id: 'lifecycle_resolved',
    title: 'Stage 5 — Resolved',
    topic: 'lifecycle',
    audience: 'all',
    tags: [
      'resolved',
      'stage 5',
      'completion',
      'after photo',
      'evidence',
      'fixed',
      'what happens when a complaint is marked resolved',
      'marked resolved',
    ],
    canonicalContent:
        'Stage 5 (Resolved): The Field Execution Officer completes the physical repair and uploads mandatory After-Work photographic proof and evidence along with completion notes. The citizen receives a resolution notification with side-by-side comparison, and the ticket enters quality review.',
    relatedTopics: [
      'evidence_after_work',
      'resolution_rework_workflow',
    ],
    sourceReference: 'Brain.md - Lifecycle Stage 5',
  ),
];
