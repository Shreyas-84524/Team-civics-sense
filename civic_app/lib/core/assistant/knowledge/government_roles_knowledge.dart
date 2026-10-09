import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix 6 Government Roles and technical invariants.
final List<KnowledgeEntry> governmentRolesKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'roles_hierarchy',
    title: 'CivicFix 6-Tier Government Role Hierarchy',
    topic: 'roles',
    audience: 'all',
    tags: [
      'roles',
      'government roles',
      'who handles my complaint',
      'hierarchy',
      'officers',
      'municipal staff',
    ],
    canonicalContent:
        'CivicFix defines a 6-tier administrative role hierarchy:\n'
        '1. Government Super Admin: Municipal Commissioner / IT administrator with full system-wide city oversight.\n'
        '2. Zonal DMC: Deputy Municipal Commissioner supervising multiple Wards within a geographic zone.\n'
        '3. Central Department HOD: Head of Department overseeing a municipal discipline across all 24 Wards.\n'
        '4. Ward Officer: Assistant Commissioner leading all administrative and civic operations in a specific Ward.\n'
        '5. Ward Department Lead (Executive Engineer): Executive Engineer managing a specific department within a Ward, conducting Quality Audits and managing reworks.\n'
        '6. Department Crew (Operational level with dual roles):\n'
        '   - Junior Engineer (JE): Technical owner and dispatcher in the Ward.\n'
        '   - Field Execution Officer: On-site technician/squad performing physical repairs.\n'
        '   Invariant: The Junior Engineer dispatcher and the Field Execution Officer must be distinct individuals (assignedJuniorEngineerId != assignedFieldOfficerId).',
    relatedTopics: [
      'roles_junior_engineer',
      'roles_field_officer',
      'roles_ward_department_lead',
      'assignment_workflow',
    ],
    sourceReference: 'Brain.md - 6-Tier Government Role Hierarchy',
  ),
  const KnowledgeEntry(
    id: 'roles_junior_engineer',
    title: 'Junior Engineer (JE) Role & Responsibilities',
    topic: 'roles',
    audience: 'all',
    tags: [
      'junior engineer',
      'je',
      'technical owner',
      'dispatcher',
      'engineer',
      'who assigns field squad',
      'what is the role of a junior engineer',
    ],
    canonicalContent:
        'A Junior Engineer (JE) is the technical supervisor and dispatcher for a specific department in a BMC Ward. Once a complaint passes verification, it is routed to the least-loaded Junior Engineer. The JE inspects the technical scope of the grievance and assigns a dedicated Field Execution Officer (Field Squad) for on-site remediation.',
    relatedTopics: [
      'roles_hierarchy',
      'roles_field_officer',
      'assignment_workflow',
    ],
    sourceReference: 'Brain.md - Junior Engineer Role Definition',
  ),
  const KnowledgeEntry(
    id: 'roles_field_officer',
    title: 'What does a Field Execution Officer do? (Field Execution Officer)',
    topic: 'roles',
    audience: 'all',
    tags: [
      'what does a field execution officer do',
      'field execution officer',
      'field execution officer do',
      'field officer',
      'field squad',
      'contractor',
      'on-site worker',
      'repair team',
    ],
    canonicalContent:
        'A Field Execution Officer (Field Officer / Field Squad) is the on-ground physical technician or contractor team assigned to fix the issue on site. They are responsible for tapping "Start Work" upon arrival, recording physical obstacles, performing physical repair execution, and uploading mandatory After-Work photo and photographic proof before resolving the ticket.',
    relatedTopics: [
      'roles_hierarchy',
      'roles_junior_engineer',
      'field_execution_start_work',
      'evidence_after_work',
    ],
    sourceReference: 'Brain.md - Field Execution Officer Role Definition',
  ),
  const KnowledgeEntry(
    id: 'roles_ward_department_lead',
    title: 'Ward Department Lead (Executive Engineer)',
    topic: 'roles',
    audience: 'all',
    tags: [
      'ward department lead',
      'executive engineer',
      'quality review',
      'rework',
      'supervisory engineer',
      'what is the responsibility of a ward department lead',
    ],
    canonicalContent:
        'A Ward Department Lead (Executive Engineer) provides departmental supervision and oversight in a Ward. They monitor SLA compliance, handle manual verification fallbacks if AI services are down, and conduct Quality Reviews on resolved grievances. If a repair is substandard, the Lead reopens the complaint for mandatory rework without resetting the SLA countdown.',
    relatedTopics: [
      'roles_hierarchy',
      'resolution_rework_workflow',
      'verification_fallback',
    ],
    sourceReference: 'Brain.md - Ward Department Lead Role Definition',
  ),
  const KnowledgeEntry(
    id: 'roles_executive_engineer',
    title: 'Executive Engineer Responsibilities',
    topic: 'roles',
    audience: 'all',
    tags: [
      'what does the executive engineer oversee',
      'executive engineer',
      'ee oversight',
      'ward lead engineer',
    ],
    canonicalContent:
        'The Executive Engineer (Ward Department Lead) oversees departmental operations across the Ward, handles escalations for overdue grievances, monitors SLA breach warnings, and supervises quality audit reviews and rework approvals.',
    relatedTopics: [
      'roles_ward_department_lead',
      'roles_hierarchy',
    ],
    sourceReference: 'Brain.md - Executive Engineer Specification',
  ),
  const KnowledgeEntry(
    id: 'roles_citizen',
    title: 'Citizen Role in CivicFix',
    topic: 'roles',
    audience: 'all',
    tags: [
      'what can a citizen do in civicfix',
      'citizen role',
      'what can i do as a citizen',
      'citizen actions',
    ],
    canonicalContent:
        'As a Citizen in CivicFix, you can report civic issues with geotagged photos, track complaint progress across all 5 stages in real time, view nearby issues on the interactive Hazard Map, upvote community issues, and provide feedback or request rework upon resolution.',
    relatedTopics: [
      'overview_citizen_side',
      'citizen_report_flow',
      'citizen_track_flow',
    ],
    sourceReference: 'Brain.md - Citizen Capabilities',
  ),
  const KnowledgeEntry(
    id: 'roles_invariant_je_vs_field_officer',
    title: 'Dual Role Invariant: Junior Engineer vs. Field Execution Officer',
    topic: 'roles',
    audience: 'all',
    tags: [
      'invariant',
      'je vs field officer',
      'separation of duties',
      'assignedJuniorEngineerId',
      'assignedFieldOfficerId',
      'can a junior engineer also be the field execution officer',
      'can a junior engineer also be the field officer on the same ticket',
    ],
    canonicalContent:
        'In CivicFix, the dispatching Junior Engineer and the physical Field Execution Officer represent two strictly distinct and separate responsibilities. Under the database invariant (`assignedJuniorEngineerId != assignedFieldOfficerId`), an engineer cannot dispatch and self-certify their own field execution, ensuring independent accountability and audit integrity.',
    relatedTopics: [
      'roles_hierarchy',
      'roles_junior_engineer',
      'roles_field_officer',
    ],
    sourceReference: 'Brain.md - Role Segregation & Invariants',
  ),
];
