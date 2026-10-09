import 'knowledge_entry.dart';

/// Authoritative knowledge entries for Citizen workflows in CivicFix.
final List<KnowledgeEntry> citizenWorkflowsKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'citizen_report_flow',
    title: 'How to Report a Complaint (4-Step Workflow)',
    topic: 'workflows',
    audience: 'citizen',
    tags: [
      'how to report',
      'submit complaint',
      'report issue',
      'steps to report',
      'new complaint',
      'grievance submission',
    ],
    canonicalContent:
        'To report a civic issue in CivicFix:\n1. Step 1 (Issue Details): Tap "Report an Issue" on Home, enter a clear title and description, and select the relevant category (e.g. Roads, Water, Garbage).\n2. Step 2 (Evidence): Optionally attach up to 3 clear photos captured via Camera or selected from Gallery showing the hazard and surrounding context.\n3. Step 3 (Location): Confirm your location via automatic GPS detection or adjust the pin manually on the interactive map for high precision.\n4. Step 4 (Review & Submit): Review all complaint details and tap "Submit Issue". A unique ticket number (e.g., CF-2026-000042) is generated and SLA tracking begins immediately.',
    relatedTopics: [
      'evidence_citizen_rules',
      'lifecycle_reported',
      'complaint_categories_list',
    ],
    sourceReference: 'Brain.md - 4-Step Citizen Reporting Workflow',
  ),
  const KnowledgeEntry(
    id: 'citizen_track_flow',
    title: 'How to Track a Complaint',
    topic: 'workflows',
    audience: 'citizen',
    tags: [
      'how to track',
      'track complaint',
      'check status',
      'my complaints',
      'timeline',
      'progress',
    ],
    canonicalContent:
        'To track your submitted complaints:\n1. Tap the "My Complaints" tab in the bottom navigation bar.\n2. Tap any complaint card to open the detailed view.\n3. View the live 5-stage progress timeline (Reported -> Under Verification -> Assigned -> In Progress -> Resolved), assigned officer details, live status remarks, and before/after photo evidence.',
    relatedTopics: [
      'lifecycle_overview',
      'complaint_statuses_all',
    ],
    sourceReference: 'Brain.md - Citizen Complaints Screen',
  ),
  const KnowledgeEntry(
    id: 'citizen_rewards_points',
    title: 'Civic Points & Rewards Program',
    topic: 'workflows',
    audience: 'citizen',
    tags: [
      'rewards',
      'civic points',
      'points',
      'badges',
      'leaderboard',
      'gamification',
    ],
    canonicalContent:
        'CivicFix rewards active civic contributors. Citizens earn Civic Points when their reported issues are verified and resolved. Accumulated points unlock community badges (e.g., Civic Guardian, Street Scout) and showcase civic impact on the profile leaderboard.',
    relatedTopics: [
      'citizen_profile',
      'overview_citizen_side',
    ],
    sourceReference: 'Brain.md - Rewards & Gamification',
  ),
  const KnowledgeEntry(
    id: 'citizen_community_upvoting',
    title: 'Community Upvoting & Civic Feed',
    topic: 'workflows',
    audience: 'citizen',
    tags: [
      'upvote',
      'community',
      'public feed',
      'support issue',
      'nearby issues',
    ],
    canonicalContent:
        'Citizens can browse public issues in their ward or neighborhood on the Community Feed and Hazard Map. Upvoting existing complaints signals higher community impact to municipal engineers, preventing duplicate ticket submissions and prioritizing urgent cluster issues.',
    relatedTopics: [
      'map_gis_overview',
      'verification_duplicate_detection',
    ],
    sourceReference: 'Brain.md - Community Features',
  ),
];
