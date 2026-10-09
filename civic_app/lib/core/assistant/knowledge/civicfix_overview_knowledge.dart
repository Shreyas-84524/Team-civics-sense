import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix overview, purpose, and platform architecture.
final List<KnowledgeEntry> overviewKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'overview_platform',
    title: 'CivicFix Platform Overview',
    topic: 'overview',
    audience: 'all',
    tags: [
      'civicfix',
      'what is civicfix',
      'overview',
      'about',
      'bmc',
      'mcgm',
      'mumbai',
      'municipal',
      'grievance',
    ],
    canonicalContent:
        'CivicFix is Greater Mumbai\'s official municipal grievance redressal, spatial AI verification, and ground execution platform for the Brihanmumbai Municipal Corporation (BMC / MCGM). It bridges citizens and civic administration across all 24 administrative Wards (A to T) to streamline reporting, automated routing, field remediation, and transparent status tracking for urban infrastructure issues.',
    relatedTopics: [
      'overview_citizen_side',
      'overview_government_side',
      'lifecycle_overview',
      'wards_overview',
    ],
    sourceReference: 'Brain.md - Core Architecture',
  ),
  const KnowledgeEntry(
    id: 'overview_citizen_side',
    title: 'CivicFix Citizen Features',
    topic: 'overview',
    audience: 'citizen',
    tags: [
      'citizen',
      'features',
      'reporting',
      'tracking',
      'points',
      'rewards',
      'map',
    ],
    canonicalContent:
        'For citizens, CivicFix provides an intuitive 4-step grievance reporting flow (details, photo evidence, GPS location, review), real-time 5-stage ticket tracking with SLA visibility, an interactive Hazard Map showing nearby issues, community upvoting, and a Civic Points reward system for active civic participation.',
    relatedTopics: [
      'citizen_report_flow',
      'citizen_track_flow',
      'citizen_rewards',
      'map_gis_overview',
    ],
    sourceReference: 'Brain.md - Citizen App Capabilities',
  ),
  const KnowledgeEntry(
    id: 'overview_government_side',
    title: 'CivicFix Government & Municipal Administration',
    topic: 'overview',
    audience: 'government',
    tags: [
      'government',
      'bmc admin',
      'ward admin',
      'junior engineer',
      'field officer',
      'sla',
      'verification',
    ],
    canonicalContent:
        'For municipal administration, CivicFix provides role-based access for 6 administrative levels (Super Admin, Zonal DMC, Central HOD, Ward Officer, Ward Department Lead, and Department Crew). It features automated AI-driven verification, least-loaded Junior Engineer dispatch, dedicated Field Execution Officer mobile tools, and supervisory quality audit review workflows.',
    relatedTopics: [
      'roles_hierarchy',
      'assignment_workflow',
      'resolution_rework_workflow',
    ],
    sourceReference: 'Brain.md - Government Portal & Workflow Rules',
  ),
  const KnowledgeEntry(
    id: 'overview_bmc_governance',
    title: 'BMC / MCGM Jurisdiction & Coverage',
    topic: 'overview',
    audience: 'all',
    tags: [
      'bmc',
      'mcgm',
      'jurisdiction',
      'wards',
      'mumbai municipal corporation',
      'coverage',
    ],
    canonicalContent:
        'CivicFix covers the entire Brihanmumbai Municipal Corporation (BMC / MCGM) jurisdiction across Mumbai Island City, Western Suburbs, and Eastern Suburbs spanning all 24 administrative Wards (A through T) and coordinating 18 canonical municipal departments.',
    relatedTopics: [
      'wards_overview',
      'departments_overview',
    ],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
];
