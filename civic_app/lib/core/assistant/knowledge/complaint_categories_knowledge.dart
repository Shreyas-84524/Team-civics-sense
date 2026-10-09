import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix citizen complaint categories and department mappings.
final List<KnowledgeEntry> complaintCategoriesKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'complaint_categories_list',
    title: 'CivicFix Grievance Categories',
    topic: 'categories',
    audience: 'all',
    tags: [
      'categories',
      'types of issues',
      'what can i report',
      'complaint types',
      'issues list',
    ],
    canonicalContent:
        'CivicFix supports all major civic issue categories:\n- Roads & Footpaths: Potholes, broken pavements, damaged medians, road cave-ins.\n- Water Supply & Leakage: Pipeline bursts, contaminated water, low water pressure, broken hydrants.\n- Solid Waste & Garbage: Overflowing community bins, uncleared garbage dumps, debris burning.\n- Street Lighting & Electrical: Non-functional streetlights, open junction boxes, hanging wires.\n- Drainage & Storm Water: Clogged storm drains, manhole covers missing, monsoon waterlogging.\n- Gardens & Trees: Fallen trees, broken dangerous branches, park maintenance.\n- Public Health & Sanitation: Unhygienic public toilets, dead animal removal, stagnant foul water.\n- Pest Control: Mosquito breeding sites, fogging requests, rodent infestation.\n- Encroachment & Footpath Obstruction: Unauthorized hawkers, blocked pedestrian walkways.\n- Building & Structures: Unauthorized alterations, dangerous building cracks.',
    relatedTopics: [
      'departments_overview',
      'citizen_report_flow',
    ],
    sourceReference: 'Brain.md - Grievance Categories Matrix',
  ),
  const KnowledgeEntry(
    id: 'category_pothole_reporting',
    title: 'How to Report a Pothole or Road Damage',
    topic: 'categories',
    audience: 'citizen',
    tags: [
      'pothole',
      'road damage',
      'broken road',
      'paver block',
      'how to report pothole',
    ],
    canonicalContent:
        'To report a pothole:\n1. Tap "Report an Issue" on the home screen.\n2. Choose "Roads & Footpaths" category.\n3. Take a photo showing the pothole and nearby surroundings for context.\n4. Ensure your GPS location accurately points to the road spot.\n5. Tap "Submit". It routes automatically to the Maintenance (Roads) department of your BMC Ward.',
    relatedTopics: [
      'citizen_report_flow',
      'dept_maintenance_roads',
    ],
    sourceReference: 'Brain.md - Road Maintenance Reporting Guide',
  ),
  const KnowledgeEntry(
    id: 'category_garbage_reporting',
    title: 'How to Report Garbage Overflow or Waste Dumps',
    topic: 'categories',
    audience: 'citizen',
    tags: [
      'garbage',
      'waste',
      'overflowing bin',
      'trash',
      'solid waste',
      'how to report garbage',
    ],
    canonicalContent:
        'To report uncollected garbage or overflow:\n1. Tap "Report an Issue".\n2. Select "Solid Waste & Garbage".\n3. Capture 1 to 3 photos of the waste dump or overflowing bin.\n4. Verify the location pin on the map and submit.\n5. It is routed directly to the Solid Waste Management (SWM) Junior Engineer in your Ward.',
    relatedTopics: [
      'citizen_report_flow',
      'dept_solid_waste_management',
    ],
    sourceReference: 'Brain.md - Solid Waste Reporting Guide',
  ),
  const KnowledgeEntry(
    id: 'category_water_leak_reporting',
    title: 'How to Report Water Pipeline Leaks & Shortages',
    topic: 'categories',
    audience: 'citizen',
    tags: [
      'water leak',
      'pipeline burst',
      'dirty water',
      'no water',
      'water supply',
    ],
    canonicalContent:
        'To report a water pipeline burst or contamination:\n1. Tap "Report an Issue".\n2. Select "Water Supply & Leakage".\n3. Attach photo or video evidence of the leaking pipe or contaminated supply.\n4. Confirm GPS coordinates and submit for immediate routing to the BMC Water Works Department.',
    relatedTopics: [
      'citizen_report_flow',
      'dept_water_works',
    ],
    sourceReference: 'Brain.md - Water Works Reporting Guide',
  ),
];
