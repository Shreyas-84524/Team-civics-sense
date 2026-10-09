import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix resolution audit, rework workflows, and SLA preservation.
final List<KnowledgeEntry> resolutionReworkKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'resolution_rework_workflow',
    title: 'Quality Review & Rework Workflow',
    topic: 'rework',
    audience: 'all',
    tags: [
      'rework',
      'reopen complaint',
      'quality review',
      'defective fix',
      'audit',
      'incomplete repair',
      'what happens when a citizen marks rework on a complaint',
      'marks rework',
    ],
    canonicalContent:
        'When a complaint is marked "Resolved", it enters a Quality Review window overseen by the Ward Department Lead (Executive Engineer):\n'
        '1. Quality Audit: The Lead inspects the After-Work photo and completion notes against municipal standards.\n'
        '2. Approval: If the remediation is verified, the complaint is approved and moved to "Closed".\n'
        '3. Reopen for Rework: If the repair is defective, incomplete, or substandard, the Lead reopens the ticket with a documented rejection reason and reassigns the Field Officer for rework.\n'
        '4. SLA Preservation: The original SLA timer continues uninterrupted and does NOT reset when a complaint is reopened for rework.\n'
        '5. Side-by-Side Audit: The previous resolution photo and notes are preserved for historical audit comparison.',
    relatedTopics: [
      'lifecycle_resolved',
      'roles_ward_department_lead',
      'sla_rules_overview',
      'evidence_after_work',
    ],
    sourceReference: 'Brain.md - Supervisory Quality Audit & Rework Policy',
  ),
  const KnowledgeEntry(
    id: 'rework_sla_preservation',
    title: 'SLA Timer Continuity During Rework',
    topic: 'rework',
    audience: 'all',
    tags: [
      'sla during rework',
      'reopen sla reset',
      'sla continuity',
      'does sla reset',
      'does reopening a complaint for rework reset the sla timer',
    ],
    canonicalContent:
        'A critical integrity rule in CivicFix is SLA continuity. If a complaint is reopened because of poor-quality work or incomplete repair, the SLA clock preserves its original deadline and does NOT reset to zero. The department must complete the rework within the original SLA duration.',
    relatedTopics: [
      'resolution_rework_workflow',
      'sla_rules_overview',
    ],
    sourceReference: 'Brain.md - SLA Continuity Invariant',
  ),
  const KnowledgeEntry(
    id: 'rework_citizen_feedback',
    title: 'Citizen Reopen & Unsatisfactory Feedback',
    topic: 'rework',
    audience: 'citizen',
    tags: [
      'can a citizen reopen a complaint if work is unsatisfactory',
      'unsatisfactory work reopen',
      'citizen reopen complaint',
      'citizen marks rework',
    ],
    canonicalContent:
        'In CivicFix, if a citizen finds that a resolved repair is unsatisfactory, incomplete, or of poor quality, they can submit citizen feedback requesting rework during the resolution review period, prompting the Ward Lead to reopen the complaint.',
    relatedTopics: [
      'resolution_rework_workflow',
      'rework_sla_preservation',
    ],
    sourceReference: 'Brain.md - Citizen Rework Feedback Policy',
  ),
  const KnowledgeEntry(
    id: 'rework_common_rejection_reasons',
    title: 'Common Reasons for Reopening Complaints for Rework',
    topic: 'rework',
    audience: 'all',
    tags: [
      'what reasons cause a complaint to be reopened for rework',
      'reasons cause a complaint to be reopened',
      'rework reasons',
      'rejection reasons',
    ],
    canonicalContent:
        'Common reasons for reopening a complaint for rework include poor quality repairs, unclear photo proof, incomplete hazard remediation, incorrect site location, or recurring issues.',
    relatedTopics: [
      'resolution_rework_workflow',
      'evidence_after_work',
    ],
    sourceReference: 'Brain.md - Rework Rejection Categories',
  ),
];
