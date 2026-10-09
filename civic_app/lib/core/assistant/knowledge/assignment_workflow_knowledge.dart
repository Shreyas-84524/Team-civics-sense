import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix assignment and dispatch workflows.
final List<KnowledgeEntry> assignmentWorkflowKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'assignment_workflow',
    title: 'Ward & Department Assignment Architecture',
    topic: 'assignment',
    audience: 'all',
    tags: [
      'assignment',
      'how assignment works',
      'dispatch',
      'routing matrix',
      'ward department routing',
    ],
    canonicalContent:
        'Once a grievance passes Stage 2 verification, CivicFix uses an automated routing algorithm:\n'
        '1. Geographic Ward Scoping: The complaint GPS coordinates determine the exact BMC administrative Ward (e.g. Ward K/West).\n'
        '2. Department Allocation: The validated category maps to the responsible department (e.g. Roads & Maintenance).\n'
        '3. Least-Loaded Junior Engineer Assignment: The ticket is automatically routed to the Junior Engineer in that Ward × Department unit with the lowest active workload.\n'
        '4. Field Squad Allocation: The Junior Engineer reviews the ticket and assigns a dedicated Field Execution Officer for on-site physical repair.',
    relatedTopics: [
      'lifecycle_assigned',
      'roles_junior_engineer',
      'roles_field_officer',
      'wards_overview',
      'departments_overview',
    ],
    sourceReference: 'Brain.md - Assignment Engine Architecture',
  ),
];
