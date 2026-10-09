import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix SLA rules, calculation principles, and escalation policies.
final List<KnowledgeEntry> slaRulesKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'sla_rules_overview',
    title: 'CivicFix SLA Rules & Timelines',
    topic: 'sla',
    audience: 'all',
    tags: [
      'sla',
      'service level agreement',
      'resolution time',
      'how long does it take',
      'deadlines',
      'turnaround time',
    ],
    canonicalContent:
        'CivicFix enforces strict municipal Service Level Agreements (SLAs):\n'
        '- SLA Clock Start: The countdown begins the precise instant a citizen submits a complaint (Stage 1: Reported).\n'
        '- Priority Timelines: SLAs are configured per category severity (e.g., Critical/Emergency hazards like live wires or major water bursts: 6 hours to 24 hours; High priority like major potholes: 48 hours; Garbage overflow: 12 hours; Water leak: 24 hours).\n'
        '- Absolute Timer Invariance: The SLA countdown is continuous and immutable. It does NOT pause or reset during reassignments between officers or reopens during supervisory rework.\n'
        '- Escalation Tracking: When an SLA reaches 80% duration or breaches, it triggers automatic color-coded alerts on Ward Officer and Zonal DMC dashboards.',
    relatedTopics: [
      'lifecycle_reported',
      'rework_sla_preservation',
      'field_execution_obstacles',
    ],
    sourceReference: 'Brain.md - SLA Rules & Escalation Policies',
  ),
  const KnowledgeEntry(
    id: 'sla_clock_start_policy',
    title: 'When Does the SLA Clock Start?',
    topic: 'sla',
    audience: 'all',
    tags: [
      'when does sla start',
      'sla start time',
      'clock start',
      'does the sla clock wait until an engineer is assigned',
      'sla start policy',
    ],
    canonicalContent:
        'In CivicFix, the SLA clock starts immediately at the moment of submission (Stage 1: Reported), NOT when an engineer assigns it or when work begins. This ensures true citizen-centric turnaround measurement.',
    relatedTopics: [
      'sla_rules_overview',
      'lifecycle_reported',
    ],
    sourceReference: 'Brain.md - SLA Start Protocol',
  ),
  const KnowledgeEntry(
    id: 'sla_potholes',
    title: 'SLA for Potholes & Road Repairs (48 Hours)',
    topic: 'sla',
    audience: 'all',
    tags: [
      'sla for fixing a major pothole',
      'pothole sla',
      'major pothole sla',
      'how long to fix pothole',
      'pothole hours',
      'pothole 48 hours',
    ],
    canonicalContent:
        'In CivicFix, the municipal SLA for fixing a major pothole and damaged road surface is 48 hours from submission. The Junior Engineer assigns a field squad to execute bituminous or cold-mix asphalt remediation.',
    relatedTopics: [
      'dept_maintenance_roads',
      'sla_rules_overview',
    ],
    sourceReference: 'Brain.md - Pothole SLA Policy',
  ),
  const KnowledgeEntry(
    id: 'sla_garbage',
    title: 'SLA for Solid Waste & Garbage Overflow (12 Hours)',
    topic: 'sla',
    audience: 'all',
    tags: [
      'resolution sla for overflowing garbage',
      'garbage sla',
      'garbage overflow sla',
      'solid waste sla',
      'garbage 12 hours',
      'waste clearance deadline',
    ],
    canonicalContent:
        'In CivicFix, the resolution SLA for overflowing garbage bins and uncollected solid waste is 12 hours from submission. The Solid Waste Management (SWM) department dispatches collection compactors for prompt clearance.',
    relatedTopics: [
      'dept_solid_waste_management',
      'sla_rules_overview',
    ],
    sourceReference: 'Brain.md - Garbage SLA Policy',
  ),
  const KnowledgeEntry(
    id: 'sla_water_leakage',
    title: 'SLA for Water Pipeline Leaks & Contamination (24 Hours)',
    topic: 'sla',
    audience: 'all',
    tags: [
      'sla for repairing a water pipeline burst',
      'water leak sla',
      'water burst sla',
      'pipeline burst sla',
      'water 24 hours',
    ],
    canonicalContent:
        'In CivicFix, the SLA for repairing a water pipeline burst and contaminated water supply is 24 hours from submission. The BMC Water Works department conducts isolation and underground line repair.',
    relatedTopics: [
      'dept_water_works',
      'sla_rules_overview',
    ],
    sourceReference: 'Brain.md - Water Works SLA Policy',
  ),
  const KnowledgeEntry(
    id: 'sla_emergency',
    title: 'SLA for Emergency & Severe Hazards (6 Hours)',
    topic: 'sla',
    audience: 'all',
    tags: [
      'sla for emergency severe hazards',
      'emergency sla',
      'critical hazard sla',
      'live wire sla',
      'emergency 6 hours',
    ],
    canonicalContent:
        'In CivicFix, the SLA for emergency severe hazards (such as live exposed electric wires, collapsed trees blocking main roads, or open manholes) is 6 hours from submission for immediate rapid-response intervention.',
    relatedTopics: [
      'sla_rules_overview',
      'roles_ward_department_lead',
    ],
    sourceReference: 'Brain.md - Emergency SLA Policy',
  ),
  const KnowledgeEntry(
    id: 'sla_obstacle_pause_policy',
    title: 'Do On-Ground Obstacles Pause the SLA Clock?',
    topic: 'sla',
    audience: 'all',
    tags: [
      'does an on-ground obstacle pause the sla clock',
      'obstacle pause sla',
      'on-ground obstacle pause',
      'blocked sla policy',
    ],
    canonicalContent:
        'In CivicFix, an on-ground physical obstacle does NOT pause or stop the SLA clock. When an obstacle is encountered and marked Blocked, the reason is logged, but the original SLA countdown continues to maintain civic accountability.',
    relatedTopics: [
      'sla_rules_overview',
      'status_blocked',
    ],
    sourceReference: 'Brain.md - Obstacle SLA Policy',
  ),
];
