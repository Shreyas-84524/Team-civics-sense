import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix 2-stage verification pipeline and AI fallback mechanisms.
final List<KnowledgeEntry> verificationWorkflowKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'verification_ai_pipeline',
    title: '2-Stage Verification Pipeline',
    topic: 'verification',
    audience: 'all',
    tags: [
      'verification process',
      'how is complaint verified',
      'ai verification',
      'validation pipeline',
      'duplicate check',
    ],
    canonicalContent:
        'CivicFix uses a 2-Stage Verification Pipeline:\n'
        '- Stage 1 (Automated AI Verification): The system scans the submitted photo for authenticity (detecting stock images or AI hallucinations), checks for duplicate complaints within a 50-meter radius, filters inappropriate content, and validates category accuracy.\n'
        '- Stage 2 (Departmental Validation): The complaint details and spatial boundary are validated to ensure exact Ward and BMC Department assignment.\n'
        '- Verification Outcome: Verified complaints automatically move to "Assigned" status for Junior Engineer dispatch.',
    relatedTopics: [
      'lifecycle_under_verification',
      'verification_fallback',
      'verification_duplicate_detection',
    ],
    sourceReference: 'Brain.md - Verification Architecture',
  ),
  const KnowledgeEntry(
    id: 'verification_duplicate_detection',
    title: 'Duplicate Complaint Detection & Spatial Clustering',
    topic: 'verification',
    audience: 'all',
    tags: [
      'duplicate complaints',
      'same issue reported twice',
      'clustering',
      'spatial deduplication',
      'how does civicfix detect duplicate complaints within a radius',
      'duplicate complaints within a radius',
      'duplicate detection',
      'spatial clustering',
      'duplicate radius',
    ],
    canonicalContent:
        'To prevent municipal crews from being dispatched multiple times for the same road hazard or garbage pile, CivicFix uses spatial deduplication. If a similar issue is already open within a close radius (e.g. 50 meters), the new report is linked to the primary ticket and the citizen is subscribed to status updates for that ticket.',
    relatedTopics: [
      'verification_ai_pipeline',
      'citizen_community_upvoting',
    ],
    sourceReference: 'Brain.md - Spatial Deduplication Engine',
  ),
  const KnowledgeEntry(
    id: 'verification_fallback',
    title: 'AI Verification Outage Fallback Mechanism',
    topic: 'verification',
    audience: 'all',
    tags: [
      'ai failure',
      'ai outage',
      'verification fallback',
      'manual verification',
      'what if ai fails',
    ],
    canonicalContent:
        'If the automated AI verification service is temporarily unreachable or times out, CivicFix uses a resilient graceful fallback: the complaint is placed into the manual verification queue where the Ward Department Lead reviews and approves it directly. The citizen\'s submission is never rejected due to AI downtime.',
    relatedTopics: [
      'verification_ai_pipeline',
      'roles_ward_department_lead',
    ],
    sourceReference: 'Brain.md - Fallback & Resiliency Policy',
  ),
  const KnowledgeEntry(
    id: 'verification_ai_evidence_rejection',
    title: 'AI-Generated & Manipulated Evidence Rejection Policy',
    topic: 'verification',
    audience: 'citizen',
    tags: [
      'ai image',
      'fake image',
      'ai generated photo',
      'why was my complaint rejected',
      'manipulated evidence',
      'synthetic photo',
      'evidence rejected',
    ],
    canonicalContent:
        'CivicFix requires authentic, real-world photographic evidence captured at the location of the grievance. If the automated evidence verification system detects that an uploaded photo is AI-generated, synthetic, or digitally manipulated, the complaint is rejected at Step 1 and does not proceed to department verification or field assignment. Citizens can tap "Report Again" to resubmit with an authentic, non-manipulated photograph of the civic defect.',
    relatedTopics: [
      'verification_ai_pipeline',
      'evidence_rules_overview',
      'evidence_citizen_rules',
    ],
    sourceReference: 'Brain.md - Authenticity Verification Policy',
  ),
];
