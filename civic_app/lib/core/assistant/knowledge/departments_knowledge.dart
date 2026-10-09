import 'knowledge_entry.dart';

/// Authoritative knowledge entries for all 18 canonical BMC departments.
/// Sourced from `supabase/functions/_shared/departments.ts`.
final List<KnowledgeEntry> departmentsKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'departments_overview',
    title: '18 Canonical BMC Municipal Departments',
    topic: 'departments',
    audience: 'all',
    tags: [
      'departments',
      'bmc departments',
      '18 departments',
      'mcgm departments',
      'department list',
    ],
    canonicalContent:
        'CivicFix coordinates operations across all 18 canonical Brihanmumbai Municipal Corporation (BMC) departments:\n'
        '1. Maintenance (Roads, Pavements & Traffic) [code: maintenance_roads]\n'
        '2. Water Works & Supply [code: water_works]\n'
        '3. Solid Waste Management [code: solid_waste_management]\n'
        '4. Building & Factory [code: building_factory]\n'
        '5. Gardens & Trees [code: garden_trees]\n'
        '6. Public Health [code: public_health]\n'
        '7. Pest Control & Insecticide [code: pest_control_insecticide]\n'
        '8. Encroachment Removal [code: encroachment]\n'
        '9. Licence Department [code: licence]\n'
        '10. Shops & Establishments [code: shops_establishments]\n'
        '11. Assessment & Collection [code: assessment_collection]\n'
        '12. Estate Department [code: estate]\n'
        '13. Colony & Slum Improvement [code: colony_slum]\n'
        '14. Education & Municipal Schools [code: education_schools]\n'
        '15. Security Force [code: security] (Administrative / internal)\n'
        '16. Legal Department [code: legal] (Administrative / internal)\n'
        '17. Administration & Establishment [code: administration_establishment] (Administrative / internal)\n'
        '18. Town Planning & Development Plan [code: town_planning_development_plan]',
    relatedTopics: [
      'dept_maintenance_roads',
      'dept_water_works',
      'dept_solid_waste_management',
      'roles_hierarchy',
    ],
    sourceReference: 'supabase/functions/_shared/departments.ts - CANONICAL_DEPARTMENTS',
  ),
  const KnowledgeEntry(
    id: 'dept_maintenance_roads',
    title: 'Maintenance (Roads, Pavement & Traffic)',
    topic: 'departments',
    audience: 'all',
    tags: [
      'which department fixes potholes on roads',
      'which department clears choked storm water drains and flooding',
      'which department fixes faulty street lights',
      'maintenance_roads',
      'maintenance',
      'roads',
      'potholes',
      'pothole',
      'pavements',
      'traffic signals',
      'streetlights',
      'street lighting',
      'drainage',
      'drain',
    ],
    canonicalContent:
        'Department Code: `maintenance_roads`. Responsible for Maintenance (Roads) including asphalt and concrete road repairs, pothole filling, pedestrian footpath maintenance, traffic island upkeep, road markings, storm water drain covers on roads, and street lighting infrastructure.',
    relatedTopics: ['category_pothole_reporting', 'departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_water_works',
    title: 'Water Works & Supply Department',
    topic: 'departments',
    audience: 'all',
    tags: [
      'which department fixes burst water pipelines',
      'water_works',
      'water works',
      'water supply',
      'water leaks',
      'pipelines',
      'burst pipelines',
      'water quality',
    ],
    canonicalContent:
        'Department Code: `water_works`. Responsible for Water Works & Supply including municipal potable water distribution, trunk mains, distribution networks, pipe bursts, leak detection, contaminated water supply resolution, water meter checks, and municipal valve operations.',
    relatedTopics: ['category_water_leak_reporting', 'departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_solid_waste_management',
    title: 'Solid Waste Management (SWM)',
    topic: 'departments',
    audience: 'all',
    tags: [
      'which department handles garbage overflow and uncleared bins',
      'solid_waste_management',
      'solid waste management',
      'swm',
      'garbage',
      'trash',
      'debris',
      'waste collection',
      'overflowing bins',
    ],
    canonicalContent:
        'Department Code: `solid_waste_management`. Responsible for Solid Waste Management (SWM) including primary door-to-door waste collection, street sweeping, community dustbin clearance, debris removal, segregation compliance, and transfer station logistics.',
    relatedTopics: ['category_garbage_reporting', 'departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_building_factory',
    title: 'Building & Factory Department',
    topic: 'departments',
    audience: 'all',
    tags: ['building_factory', 'unauthorized construction', 'building safety', 'structural hazard'],
    canonicalContent:
        'Department Code: `building_factory`. Responsible for monitoring authorized construction, investigating illegal alterations, inspecting structurally dangerous buildings (C1/C2 notices), and factory safety regulations.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_garden_trees',
    title: 'Gardens & Trees Department',
    topic: 'departments',
    audience: 'all',
    tags: [
      'which department prunes dangerous tree branches',
      'garden_trees',
      'gardens and trees',
      'tree trimming',
      'dangerous tree branches',
      'pruning',
      'fallen trees',
      'parks',
      'gardens',
    ],
    canonicalContent:
        'Department Code: `garden_trees`. Responsible for Gardens & Trees Department operations including municipal park maintenance, botanical gardens, dangerous tree trimming before monsoon, clearing fallen trees from roadways, and afforestation initiatives.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_public_health',
    title: 'Public Health Department',
    topic: 'departments',
    audience: 'all',
    tags: ['public_health', 'health', 'sanitation', 'clinics', 'epidemic control', 'public toilets'],
    canonicalContent:
        'Department Code: `public_health`. Responsible for municipal dispensaries, maternity homes, public sanitation inspections, communicable disease surveillance, dead animal removal, and public toilet cleanliness standards.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_pest_control_insecticide',
    title: 'Pest Control & Insecticide Department',
    topic: 'departments',
    audience: 'all',
    tags: [
      'which department conducts mosquito fogging for dengue',
      'pest_control_insecticide',
      'pest control',
      'insecticide',
      'mosquito fogging',
      'mosquitoes',
      'fogging',
      'malaria',
      'dengue',
    ],
    canonicalContent:
        'Department Code: `pest_control_insecticide`. Responsible for Pest Control & Insecticide Department operations including vector-borne disease control, mosquito breeding spot elimination, thermal fogging, larvicide spraying, rat control, and insecticide treatment.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_encroachment',
    title: 'Encroachment Removal Department',
    topic: 'departments',
    audience: 'all',
    tags: [
      'which department removes illegal footpath hawkers',
      'encroachment',
      'encroachment removal',
      'illegal hawkers',
      'footpath obstruction',
      'unauthorized stalls',
    ],
    canonicalContent:
        'Department Code: `encroachment`. Responsible for Encroachment Removal including clearing unauthorized commercial hawking from footpaths, removing illegal temporary structures obstructing pedestrian pathways, and confiscating unauthorized goods.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_licence',
    title: 'Licence Department',
    topic: 'departments',
    audience: 'all',
    tags: ['licence', 'trade licence', 'hoardings', 'banners', 'commercial permits'],
    canonicalContent:
        'Department Code: `licence`. Responsible for issuing and auditing trade licenses, advertisement hoardings, sky signs, projection permits, and illegal banner removal.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_shops_establishments',
    title: 'Shops & Establishments Department',
    topic: 'departments',
    audience: 'all',
    tags: ['shops_establishments', 'gumasta', 'working hours', 'commercial establishments'],
    canonicalContent:
        'Department Code: `shops_establishments`. Responsible for the Maharashtra Shops and Establishments Act (Gumasta) registration, operational hours enforcement, and worker welfare compliance in retail/commercial units.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_assessment_collection',
    title: 'Assessment & Collection Department',
    topic: 'departments',
    audience: 'all',
    tags: ['assessment_collection', 'property tax', 'tax assessment', 'water tax'],
    canonicalContent:
        'Department Code: `assessment_collection`. Responsible for municipal property tax assessment, billing, collection, capital value revisions, and water charges recovery.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_estate',
    title: 'Estate Department',
    topic: 'departments',
    audience: 'all',
    tags: ['estate', 'municipal property', 'bmc land', 'lease management'],
    canonicalContent:
        'Department Code: `estate`. Responsible for municipal property administration, leased BMC lands, rent collection on municipal buildings, and recovery of municipal real estate.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_colony_slum',
    title: 'Colony & Slum Improvement Department',
    topic: 'departments',
    audience: 'all',
    tags: ['colony_slum', 'slum improvement', 'informal settlements', 'slum amenities'],
    canonicalContent:
        'Department Code: `colony_slum`. Responsible for basic civic infrastructure in notified slums, community walkways, community taps, drainage in informal settlements, and civic amenities under slum development schemes.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_education_schools',
    title: 'Education & Municipal Schools Department',
    topic: 'departments',
    audience: 'all',
    tags: ['education_schools', 'bmc schools', 'municipal schools', 'school infrastructure'],
    canonicalContent:
        'Department Code: `education_schools`. Responsible for BMC-run primary and secondary municipal schools, classroom facilities, drinking water, midday meals, and student education infrastructure.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_security',
    title: 'Security Force Department',
    topic: 'departments',
    audience: 'government',
    tags: ['security', 'bmc security', 'municipal guards', 'internal security'],
    canonicalContent:
        'Department Code: `security`. Internal municipal security division protecting BMC head offices, ward offices, hospitals, water reservoirs, and municipal installations. Not open for general citizen grievance reporting.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_legal',
    title: 'Legal Department',
    topic: 'departments',
    audience: 'government',
    tags: ['legal', 'bmc legal', 'court cases', 'litigation'],
    canonicalContent:
        'Department Code: `legal`. Internal legal division representing BMC in civil, high court, supreme court litigations, municipal contract reviews, and statutory compliance. Not open for general citizen grievance reporting.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_administration_establishment',
    title: 'Administration & Establishment Department',
    topic: 'departments',
    audience: 'government',
    tags: ['administration_establishment', 'hr', 'personnel', 'establishment'],
    canonicalContent:
        'Department Code: `administration_establishment`. Internal human resources and administrative governance body managing municipal employee payroll, recruitment, postings, and service records. Not open for general citizen grievance reporting.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
  const KnowledgeEntry(
    id: 'dept_town_planning_development_plan',
    title: 'Town Planning & Development Plan Department',
    topic: 'departments',
    audience: 'all',
    tags: ['town_planning_development_plan', 'dp', 'zoning', 'development plan', 'master plan'],
    canonicalContent:
        'Department Code: `town_planning_development_plan`. Responsible for Greater Mumbai Development Plan (DP 2034) implementation, land reservations, zoning regulations, and master planning approvals.',
    relatedTopics: ['departments_overview'],
    sourceReference: 'supabase/functions/_shared/departments.ts',
  ),
];
