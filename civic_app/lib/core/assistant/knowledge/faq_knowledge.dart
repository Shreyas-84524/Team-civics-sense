import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix frequently asked questions (FAQs).
final List<KnowledgeEntry> faqKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'faq_what_is_civicfix',
    title: 'What is CivicFix?',
    topic: 'faq',
    audience: 'all',
    tags: ['what is civicfix', 'about civicfix', 'faq what is'],
    canonicalContent:
        'CivicFix is Greater Mumbai\'s municipal grievance redressal platform (BMC / MCGM). It allows citizens to report civic issues like potholes, garbage overflow, water leaks, and broken streetlights with GPS tagging and track repairs through a 5-stage verification and resolution workflow.',
    relatedTopics: ['overview_platform'],
    sourceReference: 'Brain.md - FAQ 1',
  ),
  const KnowledgeEntry(
    id: 'faq_how_to_report',
    title: 'How do I report or submit a complaint?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['how to report', 'how do i submit', 'report problem', 'file complaint'],
    canonicalContent:
        'To report an issue: Tap "Report an Issue" on the Home screen. Fill in the title, choose a category, optionally attach up to 3 photos in Evidence, confirm your GPS location on the map, and submit.',
    relatedTopics: ['citizen_report_flow'],
    sourceReference: 'Brain.md - FAQ 2',
  ),
  const KnowledgeEntry(
    id: 'faq_what_happens_after_submit',
    title: 'What happens after I submit a complaint?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['what happens after submit', 'after submission', 'next steps after reporting'],
    canonicalContent:
        'After you submit a complaint, it goes through a 5-stage workflow:\n1. Reported: Your grievance is logged with a unique ticket number and SLA tracking begins.\n2. Under Verification: The evidence is reviewed and routed to the correct BMC department.\n3. Assigned: A Junior Engineer in your Ward assigns a Field Execution Officer.\n4. In Progress: The Field Officer begins on-site repair work.\n5. Resolved: The repair is completed with mandatory after-work photo evidence.',
    relatedTopics: ['lifecycle_overview'],
    sourceReference: 'Brain.md - FAQ 3',
  ),
  const KnowledgeEntry(
    id: 'faq_under_verification_meaning',
    title: 'What does "Under Verification" mean?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['under verification meaning', 'why under verification', 'verification status'],
    canonicalContent:
        '"Under Verification" (Stage 2) means your complaint is being reviewed to confirm the issue details, verify photo evidence authenticity, and route it to the correct BMC Ward and Department engineer.',
    relatedTopics: ['status_under_verification', 'verification_ai_pipeline'],
    sourceReference: 'Brain.md - FAQ 4',
  ),
  const KnowledgeEntry(
    id: 'faq_who_handles_my_complaint',
    title: 'Who handles my complaint?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['who handles complaint', 'who fixes it', 'which officer', 'who is responsible'],
    canonicalContent:
        'Your complaint is routed to the Junior Engineer in your Ward\'s relevant department (e.g. Roads, Water, Waste). The Junior Engineer assigns a dedicated Field Execution Officer who performs the actual repair on site.',
    relatedTopics: ['roles_hierarchy', 'roles_junior_engineer', 'roles_field_officer'],
    sourceReference: 'Brain.md - FAQ 5',
  ),
  const KnowledgeEntry(
    id: 'faq_junior_engineer_role',
    title: 'What is the role of a Junior Engineer (JE)?',
    topic: 'faq',
    audience: 'all',
    tags: ['junior engineer role', 'what does je do', 'who is junior engineer'],
    canonicalContent:
        'A Junior Engineer (JE) is the technical owner and dispatcher for your Ward\'s department. They review incoming verified grievances, allocate field squads, and oversee work execution.',
    relatedTopics: ['roles_junior_engineer'],
    sourceReference: 'Brain.md - FAQ 6',
  ),
  const KnowledgeEntry(
    id: 'faq_field_officer_role',
    title: 'What is the role of a Field Execution Officer?',
    topic: 'faq',
    audience: 'all',
    tags: ['field officer role', 'execution officer', 'who fixes on site'],
    canonicalContent:
        'An Execution Officer (Field Officer) is the on-site municipal technician or contractor squad responsible for physical repair work on the ground and uploading completion photos.',
    relatedTopics: ['roles_field_officer'],
    sourceReference: 'Brain.md - FAQ 7',
  ),
  const KnowledgeEntry(
    id: 'faq_edit_complaint',
    title: 'Can I edit my complaint after submitting?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['can i edit complaint', 'modify report', 'change complaint details'],
    canonicalContent:
        'Once submitted, the core complaint details cannot be directly edited to preserve official audit integrity. However, you can track progress in real-time or submit additional information if an officer requests clarification.',
    relatedTopics: ['citizen_track_flow'],
    sourceReference: 'Brain.md - FAQ 8',
  ),
  const KnowledgeEntry(
    id: 'faq_how_to_track',
    title: 'How do I track my complaint progress?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['how to track', 'where to track', 'check complaint status'],
    canonicalContent:
        'To track your complaint: Tap "My Complaints" in the bottom navigation. Tap any ticket to view its live 5-stage progress tracker and assigned officer details.',
    relatedTopics: ['citizen_track_flow'],
    sourceReference: 'Brain.md - FAQ 9',
  ),
  const KnowledgeEntry(
    id: 'faq_resolution_timeline_sla',
    title: 'How long will it take to resolve my complaint?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['how long does it take', 'sla resolution time', 'expected completion time'],
    canonicalContent:
        'Resolution time depends on category severity under BMC SLA standards: Emergency/Safety hazards (e.g. live wires, major water main bursts) are targeted within 24 hours; critical road potholes and sewer overflows within 48 hours; routine waste and streetlights within 72 hours; and complex civil works within 7 days.',
    relatedTopics: ['sla_rules_overview'],
    sourceReference: 'Brain.md - FAQ 10',
  ),
  const KnowledgeEntry(
    id: 'faq_when_sla_starts',
    title: 'When does the SLA clock start?',
    topic: 'faq',
    audience: 'all',
    tags: ['when does sla start', 'sla countdown start'],
    canonicalContent:
        'In CivicFix, the SLA clock starts immediately at the moment of submission (Stage 1: Reported), NOT when an engineer assigns it or when work begins. This ensures true citizen-centric turnaround measurement.',
    relatedTopics: ['sla_clock_start_policy'],
    sourceReference: 'Brain.md - FAQ 11',
  ),
  const KnowledgeEntry(
    id: 'faq_rework_defective_repair',
    title: 'What happens if a complaint is not repaired properly?',
    topic: 'faq',
    audience: 'all',
    tags: ['defective repair', 'reopen issue', 'poor work', 'not fixed properly'],
    canonicalContent:
        'If a resolved issue is found incomplete or defective, the Ward Department Lead reopens the complaint for rework. The SLA timer remains continuous and does not reset.',
    relatedTopics: ['resolution_rework_workflow', 'rework_sla_preservation'],
    sourceReference: 'Brain.md - FAQ 12',
  ),
  const KnowledgeEntry(
    id: 'faq_does_sla_reset_on_rework',
    title: 'Does the SLA timer reset when a complaint is reopened for rework?',
    topic: 'faq',
    audience: 'all',
    tags: ['does sla reset', 'sla reset on rework', 'reopen timer'],
    canonicalContent:
        'No. Under CivicFix municipal policy, the SLA timer is strictly continuous and never resets upon rework. The department remains bound by the original submission deadline.',
    relatedTopics: ['rework_sla_preservation'],
    sourceReference: 'Brain.md - FAQ 13',
  ),
  const KnowledgeEntry(
    id: 'faq_ai_failure_fallback',
    title: 'What happens if AI verification goes offline?',
    topic: 'faq',
    audience: 'all',
    tags: ['ai down', 'ai failure', 'verification offline', 'system error'],
    canonicalContent:
        'If automated AI verification is temporarily unavailable, complaints are safely placed in the municipal queue where Ward Department Leads review and verify them manually without delay.',
    relatedTopics: ['verification_fallback'],
    sourceReference: 'Brain.md - FAQ 14',
  ),
  const KnowledgeEntry(
    id: 'faq_photo_requirements',
    title: 'How many photos can I attach to a complaint?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['photo limit', 'how many photos', 'maximum pictures'],
    canonicalContent:
        'You can attach up to 3 photos per complaint, either captured via camera or selected from your gallery. We recommend 1 close-up of the hazard and 1 wide shot showing surrounding landmarks.',
    relatedTopics: ['evidence_citizen_rules'],
    sourceReference: 'Brain.md - FAQ 15',
  ),
  const KnowledgeEntry(
    id: 'faq_rewards_points',
    title: 'How do Civic Points and badges work?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['civic points', 'earn points', 'how rewards work', 'badges'],
    canonicalContent:
        'You earn Civic Points when your reported issues are verified and remediated. Accumulating points unlocks civic achievement badges and elevates your standing on the community leaderboard.',
    relatedTopics: ['citizen_rewards_points'],
    sourceReference: 'Brain.md - FAQ 16',
  ),
  const KnowledgeEntry(
    id: 'faq_how_map_works',
    title: 'How does the Hazard Map work?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['how map works', 'hazard map usage', 'maplibre map'],
    canonicalContent:
        'The Hazard Map displays interactive color-coded pins for reported issues around your area, including potholes, water leaks, broken streetlights, and garbage spots.',
    relatedTopics: ['map_gis_overview'],
    sourceReference: 'Brain.md - FAQ 17',
  ),
  const KnowledgeEntry(
    id: 'faq_jurisdiction_coverage',
    title: 'Which municipal corporation and areas does CivicFix cover?',
    topic: 'faq',
    audience: 'all',
    tags: ['jurisdiction', 'which city', 'coverage', 'bmc coverage'],
    canonicalContent:
        'CivicFix covers the entire Brihanmumbai Municipal Corporation (BMC / MCGM) jurisdiction across Mumbai Island City, Western Suburbs, and Eastern Suburbs spanning all 24 administrative Wards (A through T) and coordinating 18 canonical municipal departments.',
    relatedTopics: ['overview_bmc_governance', 'wards_overview'],
    sourceReference: 'Brain.md - FAQ 18',
  ),
  const KnowledgeEntry(
    id: 'faq_privacy_protection',
    title: 'Is my phone number visible to the public?',
    topic: 'faq',
    audience: 'citizen',
    tags: ['is phone number visible', 'privacy', 'public profile'],
    canonicalContent:
        'No. Your mobile number and personal contact details are completely hidden from public map markers and feeds. Only authorized BMC engineers handling your specific grievance have access to official contact records.',
    relatedTopics: ['account_privacy_security'],
    sourceReference: 'Brain.md - FAQ 19',
  ),
];
