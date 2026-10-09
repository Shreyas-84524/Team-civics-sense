import '../models/assistant_language.dart';

/// Centralized CivicFix Multilingual Domain Lexicon.
///
/// Maps core municipal terminology, complaint lifecycle concepts, roles, and UI terms
/// across English, Hindi, and Marathi (including Devanagari and common Romanized transliterations).
///
/// Used for:
/// 1. Multilingual query normalization and RAG token expansion (Retrieval Bridge).
/// 2. Terminology consistency across conversational responses.
class CivicAssistantLexicon {
  /// Standard concept dictionary mapping canonical concept keys to localized terms and variations.
  static const Map<String, Map<AssistantLanguage, String>> _canonicalDisplayTerms = {
    // Lifecycle States
    'reported': {
      AssistantLanguage.english: 'Reported',
      AssistantLanguage.hindi: 'दर्ज (Reported)',
      AssistantLanguage.marathi: 'नोंदणीकृत (Reported)',
    },
    'underVerification': {
      AssistantLanguage.english: 'Under Verification',
      AssistantLanguage.hindi: 'सत्यापनाधीन (Under Verification)',
      AssistantLanguage.marathi: 'पडताळणीमध्ये (Under Verification)',
    },
    'assigned': {
      AssistantLanguage.english: 'Assigned',
      AssistantLanguage.hindi: 'असाइन किया गया (Assigned)',
      AssistantLanguage.marathi: 'नियुक्त (Assigned)',
    },
    'inProgress': {
      AssistantLanguage.english: 'In Progress',
      AssistantLanguage.hindi: 'कार्य प्रगति पर (In Progress)',
      AssistantLanguage.marathi: 'काम प्रगतीपथावर (In Progress)',
    },
    'resolved': {
      AssistantLanguage.english: 'Resolved',
      AssistantLanguage.hindi: 'समाधान किया गया (Resolved)',
      AssistantLanguage.marathi: 'निवारण झाले (Resolved)',
    },
    'closed': {
      AssistantLanguage.english: 'Closed',
      AssistantLanguage.hindi: 'बंद (Closed)',
      AssistantLanguage.marathi: 'बंद (Closed)',
    },
    'blocked': {
      AssistantLanguage.english: 'Blocked (Obstacle)',
      AssistantLanguage.hindi: 'अवरुद्ध / बाधा (Blocked)',
      AssistantLanguage.marathi: 'अडथळा / थांबलेले (Blocked)',
    },
    'reopened': {
      AssistantLanguage.english: 'Reopened (Rework)',
      AssistantLanguage.hindi: 'पुनः खोला गया (Rework)',
      AssistantLanguage.marathi: 'पुन्हा उघडले (Rework)',
    },

    // Administrative Roles
    'juniorEngineer': {
      AssistantLanguage.english: 'Junior Engineer',
      AssistantLanguage.hindi: 'कनिष्ठ अभियंता (Junior Engineer)',
      AssistantLanguage.marathi: 'कनिष्ठ अभियंता (Junior Engineer)',
    },
    'fieldOfficer': {
      AssistantLanguage.english: 'Field Execution Officer',
      AssistantLanguage.hindi: 'क्षेत्रीय निष्पादन अधिकारी (Field Execution Officer)',
      AssistantLanguage.marathi: 'क्षेत्रीय अंमलबजावणी अधिकारी (Field Execution Officer)',
    },
    'wardDepartmentLead': {
      AssistantLanguage.english: 'Ward Department Lead',
      AssistantLanguage.hindi: 'वॉर्ड विभाग प्रमुख (Ward Department Lead)',
      AssistantLanguage.marathi: 'प्रभाग विभाग प्रमुख (Ward Department Lead)',
    },

    // Domain Entities
    'complaint': {
      AssistantLanguage.english: 'Complaint',
      AssistantLanguage.hindi: 'शिकायत',
      AssistantLanguage.marathi: 'तक्रार',
    },
    'ward': {
      AssistantLanguage.english: 'Ward',
      AssistantLanguage.hindi: 'वॉर्ड / प्रभाग',
      AssistantLanguage.marathi: 'प्रभाग (Ward)',
    },
    'department': {
      AssistantLanguage.english: 'Department',
      AssistantLanguage.hindi: 'विभाग (Department)',
      AssistantLanguage.marathi: 'विभाग (Department)',
    },
    'evidence': {
      AssistantLanguage.english: 'Evidence / Photo',
      AssistantLanguage.hindi: 'प्रमाण / फोटो',
      AssistantLanguage.marathi: 'पुरावा / फोटो',
    },
    'sla': {
      AssistantLanguage.english: 'SLA (Service Level Agreement)',
      AssistantLanguage.hindi: 'समय सीमा (SLA)',
      AssistantLanguage.marathi: 'सेवा मुदत (SLA)',
    },
    'map': {
      AssistantLanguage.english: 'Hazard Map',
      AssistantLanguage.hindi: 'हैज़र्ड मैप',
      AssistantLanguage.marathi: 'धोका नकाशा (Hazard Map)',
    },
    'sync': {
      AssistantLanguage.english: 'Offline Sync Queue',
      AssistantLanguage.hindi: 'ऑफ़लाइन सिंक कतार',
      AssistantLanguage.marathi: 'ऑफलाइन सिंक रांग',
    },
  };

  /// Multilingual token mapping for query normalization.
  /// Maps words in Devanagari (Hindi/Marathi) and transliterated roman script to canonical English tokens.
  static const Map<String, List<String>> _multilingualTokenBridge = {
    // Complaint / Grievance
    'सिविकफिक्स': ['civicfix', 'overview_platform', 'platform', 'what_is_civicfix'],
    'तक्रार': ['complaint', 'grievance', 'issue', 'ticket'],
    'तक्रारी': ['complaint', 'grievance', 'issue', 'complaints'],
    'तक्रारीचे': ['complaint', 'grievance', 'issue'],
    'तक्रारींची': ['complaint', 'grievance', 'complaints'],
    'शिकायत': ['complaint', 'grievance', 'issue', 'ticket'],
    'शिकायतें': ['complaint', 'grievance', 'complaints'],
    'शिकायतों': ['complaint', 'grievance', 'complaints'],
    'समस्या': ['issue', 'problem', 'grievance', 'complaint'],
    'अडचण': ['issue', 'problem', 'grievance'],

    // Verification
    'पडताळणी': ['verification', 'under_verification', 'lifecycle_under_verification'],
    'पडताळणीमध्ये': ['under_verification', 'status_under_verification', 'verification'],
    'पडताळणीत': ['under_verification', 'verification'],
    'सत्यापन': ['verification', 'under_verification', 'lifecycle_under_verification'],
    'सत्यापनाधीन': ['under_verification', 'status_under_verification', 'verification'],
    'जांच': ['verification', 'audit', 'check'],

    // Status / Progress / Lifecycle
    'स्थिती': ['status', 'lifecycle', 'stage'],
    'अवस्था': ['status', 'stage'],
    'प्रगती': ['in_progress', 'progress'],
    'प्रगतीपथावर': ['in_progress', 'status_in_progress', 'work_started'],
    'सुरू': ['in_progress', 'start_work', 'started'],
    'झाले': ['status', 'completed', 'resolved'],
    'झाली': ['status', 'completed', 'resolved'],
    'सुरुवात': ['start_work', 'in_progress'],
    'शुरू': ['in_progress', 'start_work', 'started'],
    'समाधान': ['resolved', 'status_resolved', 'resolution'],
    'निवारण': ['resolved', 'status_resolved', 'resolution'],
    'पूर्ण': ['resolved', 'closed', 'completed'],
    'निकाली': ['resolved', 'closed'],
    'बंद': ['closed', 'status_closed'],

    // Rework / Reopening
    'पुन्हा': ['reopen', 'rework', 'quality_audit', 'sla'],
    'दोबारा': ['reopen', 'rework', 'quality_audit', 'sla'],
    'उघडली': ['reopen', 'reopened', 'rework'],
    'खोली': ['reopen', 'reopened', 'rework'],
    'दुरुस्ती': ['rework', 'repair', 'field_execution'],
    'सुधारणा': ['rework', 'repair'],

    // Obstacle / Blocked
    'अडथळा': ['blocked', 'obstacle', 'delay'],
    'थांबले': ['blocked', 'obstacle', 'paused'],
    'बाधा': ['blocked', 'obstacle', 'delay'],
    'रुका': ['blocked', 'obstacle', 'delay'],
    'अटका': ['blocked', 'obstacle'],

    // Roles & Assignment
    'अभियंता': ['junior_engineer', 'engineer', 'role'],
    'अधिकारी': ['officer', 'field_officer', 'lead'],
    'कर्मचारी': ['crew', 'department_crew', 'officer'],
    'प्रमुख': ['lead', 'ward_department_lead'],
    'नियुक्ती': ['assigned', 'crew', 'junior_engineer', 'field_officer', 'roles_junior_engineer'],
    'नियुक्त': ['assigned', 'crew', 'junior_engineer', 'field_officer', 'roles_junior_engineer'],
    'असाइन': ['assigned', 'crew', 'junior_engineer', 'field_officer', 'roles_junior_engineer'],
    'सोपवले': ['assigned', 'crew', 'junior_engineer'],

    // Map & Location
    'नकाशा': ['map', 'gis', 'basemap', 'location', 'hazard_map', 'map_gis_overview'],
    'नकाशावर': ['map', 'gis', 'hazard_map', 'map_gis_overview'],
    'नक्शा': ['map', 'gis', 'basemap', 'location', 'hazard_map', 'map_gis_overview'],
    'मैप': ['map', 'gis', 'basemap', 'location', 'hazard_map', 'map_gis_overview'],
    'धोका': ['hazard', 'hazard_map', 'map_gis_overview', 'map'],
    'खतरा': ['hazard', 'hazard_map', 'map_gis_overview', 'map'],
    'स्थान': ['location', 'gps', 'pin'],
    'पत्ता': ['address', 'location'],
    'दिशानिर्देश': ['navigation', 'location'],
    'वापरायचा': ['map', 'gis', 'help'],
    'इस्तेमाल': ['map', 'gis', 'help'],

    // Photos & Evidence
    'फोटो': ['photo', 'evidence', 'picture', 'upload'],
    'छायाचित्र': ['photo', 'evidence', 'picture'],
    'पुरावा': ['evidence', 'photo', 'proof'],
    'प्रमाण': ['evidence', 'proof'],
    'प्रतिमा': ['photo', 'image', 'picture'],

    // Departments / Categories
    'रस्ता': ['roads', 'maintenance_roads', 'pothole'],
    'रस्ते': ['roads', 'maintenance_roads'],
    'खड्डा': ['pothole', 'maintenance_roads', 'roads'],
    'खड्डे': ['pothole', 'potholes', 'maintenance_roads'],
    'कचरा': ['garbage', 'solid_waste_management', 'waste'],
    'पाणी': ['water', 'water_works', 'leakage'],
    'गळती': ['leakage', 'water_works'],
    'प्रभाग': ['ward', 'wards_overview'],
    'वॉर्ड': ['ward', 'wards_overview'],
    'विभाग': ['department', 'departments_overview'],

    // SLA & Time
    'वेळ': ['sla', 'timeline', 'turnaround'],
    'मुदत': ['sla', 'timeline', 'turnaround'],
    'कालावधी': ['sla', 'timeline', 'turnaround'],
    'समय': ['sla', 'timeline', 'turnaround'],
    'किती': ['timeline', 'sla'],
    'कधी': ['timeline', 'sla'],
    'कब': ['timeline', 'sla'],

    // Sync & Offline
    'सिंक': ['sync', 'offline', 'queue'],
    'ऑफलाइन': ['offline', 'pending', 'queue'],

    // Romanized / Transliterated Terms (Hinglish & Marathlish)
    'mazi': ['complaint', 'my'],
    'mera': ['complaint', 'my'],
    'meri': ['complaint', 'my'],
    'aage': ['next', 'lifecycle', 'workflow'],
    'pudhe': ['next', 'lifecycle', 'workflow'],
    'shuru': ['in_progress', 'start_work'],
    'suru': ['in_progress', 'start_work'],
    'zala': ['status', 'completed'],
    'hua': ['status', 'completed'],
    'kaise': ['how_to', 'help'],
    'kasa': ['how_to', 'help'],
    'kashi': ['how_to', 'help'],
    'kaha': ['where', 'navigation'],
    'kuthe': ['where', 'navigation'],
    'kyu': ['why', 'reason'],
    'ka': ['why', 'reason'],
    'kyun': ['why', 'reason'],
    'paani': ['water', 'water_works'],
    'pani': ['water', 'water_works'],
    'rasta': ['roads', 'maintenance_roads'],
    'nakasha': ['map', 'gis'],
  };

  /// Returns canonical display name for a concept key in the requested language.
  static String getLocalizedTerm(String conceptKey, AssistantLanguage language) {
    final termMap = _canonicalDisplayTerms[conceptKey];
    if (termMap != null) {
      return termMap[language] ?? termMap[AssistantLanguage.english] ?? conceptKey;
    }
    return conceptKey;
  }

  /// Extracts canonical English search tokens from multilingual (Devanagari or Romanized) query tokens.
  static Set<String> getCanonicalBridgeTokens(Iterable<String> rawTokens) {
    final bridgeTokens = <String>{};
    for (final raw in rawTokens) {
      final clean = raw.trim().toLowerCase();
      final mapped = _multilingualTokenBridge[clean];
      if (mapped != null) {
        bridgeTokens.addAll(mapped);
      }
    }
    return bridgeTokens;
  }
}
