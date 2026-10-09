import 'knowledge_entry.dart';

/// Authoritative knowledge entries for CivicFix GIS, Hazard Map, and spatial features.
final List<KnowledgeEntry> mapGisKnowledgeEntries = [
  const KnowledgeEntry(
    id: 'map_gis_overview',
    title: 'CivicFix Interactive Hazard Map',
    topic: 'map_gis',
    audience: 'all',
    tags: [
      'map',
      'hazard map',
      'gis',
      'maplibre',
      'pins',
      'markers',
      'satellite view',
      'nearby issues',
      'what features are on the map screen',
      'how does the interactive map work',
    ],
    canonicalContent:
        'The CivicFix Hazard Map is an interactive GIS interface powered by MapLibre GL:\n'
        '- Interactive Basemaps: Switch between crisp vector street maps and high-resolution satellite imagery.\n'
        '- Color-Coded Hazard Pins: Easily identify open geotagged complaints (Red/Orange = Reported/Assigned, Yellow = In Progress, Green = Resolved).\n'
        '- Dynamic Spatial Clustering: When zoomed out, nearby issues group into numbered cluster circles.\n'
        '- Filter Options: Filter pins by category (Roads, Water, Waste), status, and distance radius from your current location.\n'
        '- Tap to Inspect: Tapping any pin opens a preview card showing ticket summary, photos, and current status.',
    relatedTopics: [
      'citizen_track_flow',
      'citizen_community_upvoting',
      'overview_citizen_side',
    ],
    sourceReference: 'Brain.md - MapLibre GIS Integration',
  ),
  const KnowledgeEntry(
    id: 'map_pin_status_colors',
    title: 'Hazard Map Pin Colors & Severity Markers',
    topic: 'map_gis',
    audience: 'all',
    tags: [
      'what do the different color pins on the map mean',
      'different color pins on the map',
      'map pin colors',
      'pin status colors',
    ],
    canonicalContent:
        'On the CivicFix Hazard Map, pins are color-coded by status and priority:\n'
        '- Red/Orange Pins: Reported and Under Verification or Emergency severe hazards.\n'
        '- Yellow Pins: In Progress with field crew on site.\n'
        '- Green Pins: Resolved repairs with uploaded after-work evidence.',
    relatedTopics: [
      'map_gis_overview',
      'complaint_statuses_all',
    ],
    sourceReference: 'Brain.md - Map Pin Styling Guide',
  ),
  const KnowledgeEntry(
    id: 'map_clustering_behavior',
    title: 'Dynamic Map Spatial Clustering',
    topic: 'map_gis',
    audience: 'all',
    tags: [
      'why do map pins merge into numbers when zooming out',
      'map pins merge into numbers',
      'map clustering',
      'zoom out map pins',
    ],
    canonicalContent:
        'On the CivicFix Hazard Map, when zooming out or viewing dense concentrations of civic complaints, individual geotagged pins automatically group into numbered cluster circles. Zooming in expands clusters into individual complaint locations.',
    relatedTopics: [
      'map_gis_overview',
    ],
    sourceReference: 'Brain.md - Map Clustering Engine',
  ),
];
