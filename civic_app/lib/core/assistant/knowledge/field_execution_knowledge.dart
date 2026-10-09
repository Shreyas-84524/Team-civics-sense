import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix ground field execution and obstacle handling.
final List<KnowledgeEntry> fieldExecutionKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'field_execution_start_work',
    title: 'Ground Execution & "Start Work" Action',
    topic: 'field_execution',
    audience: 'all',
    tags: [
      'start work',
      'field execution',
      'ground work',
      'repair execution',
    ],
    canonicalContent:
        'When the assigned Field Execution Officer arrives at the physical site, they inspect the hazard and tap "Start Work" in their field interface. This transitions the ticket from "Assigned" to "In Progress" and logs a precise start timestamp visible to the citizen on their live timeline.',
    relatedTopics: [
      'lifecycle_in_progress',
      'roles_field_officer',
      'field_execution_obstacles',
    ],
    sourceReference: 'Brain.md - Field Execution Protocol',
  ),
  const KnowledgeEntry(
    id: 'field_execution_obstacles',
    title: 'Physical Obstacles & Blocked State Handling',
    topic: 'field_execution',
    audience: 'all',
    tags: [
      'obstacles',
      'blocked status',
      'work delay',
      'monsoon delay',
      'traffic permission',
      'why is work paused',
    ],
    canonicalContent:
        'If the field crew encounters physical obstacles preventing remediation (such as intense monsoon waterlogging, heavy traffic requiring police clearance, or locked private access), the officer marks the ticket as "Blocked" and records the specific reason. The citizen and Ward Lead can view the explanation. Once the obstacle is cleared, the crew resumes work without restarting the SLA clock.',
    relatedTopics: [
      'lifecycle_in_progress',
      'sla_rules_overview',
      'roles_field_officer',
    ],
    sourceReference: 'Brain.md - Obstacle Handling Protocol',
  ),
];
