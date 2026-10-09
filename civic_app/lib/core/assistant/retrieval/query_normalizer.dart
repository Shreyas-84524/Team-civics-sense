import '../knowledge/civic_assistant_lexicon.dart';

/// Utility for normalizing user queries, stripping stop words, preserving Devanagari script,
/// and applying domain and multilingual token aliases.
class QueryNormalizer {
  /// Standard stop words in English, Hindi, and Marathi that add little retrieval value in domain searches.
  static const Set<String> _stopWords = {
    // English Stop Words
    'a',
    'an',
    'the',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
    'have',
    'has',
    'had',
    'do',
    'does',
    'did',
    'will',
    'would',
    'shall',
    'should',
    'can',
    'could',
    'may',
    'might',
    'must',
    'in',
    'on',
    'at',
    'to',
    'for',
    'of',
    'with',
    'by',
    'from',
    'up',
    'about',
    'into',
    'over',
    'after',
    'my',
    'your',
    'his',
    'her',
    'its',
    'our',
    'their',
    'this',
    'that',
    'these',
    'those',
    'i',
    'you',
    'he',
    'she',
    'it',
    'we',
    'they',
    'me',
    'him',
    'us',
    'them',
    'what',
    'which',
    'who',
    'whom',
    'whose',
    'where',
    'when',
    'why',
    'how',
    'please',
    'tell',
    'know',
    'want',
    'give',
    'show',
    'explain',
    'help',

    // Hindi Stop Words
    'का',
    'की',
    'के',
    'को',
    'है',
    'हैं',
    'था',
    'थी',
    'थे',
    'हो',
    'होगा',
    'होगी',
    'होंगे',
    'कर',
    'रहा',
    'रही',
    'रहे',
    'से',
    'में',
    'पर',
    'ने',
    'और',
    'या',
    'तो',
    'भी',
    'ही',
    'एक',
    'यह',
    'वह',
    'इस',
    'उस',
    'कि',
    'सकता',
    'सकती',
    'सकते',
    'चाहिए',
    'बताएं',
    'बताओ',
    'बताइए',
    'दीजिए',
    'दीजिये',

    // Marathi Stop Words
    'आहे',
    'आहेत',
    'नाही',
    'नाहीत',
    'होते',
    'होती',
    'होता',
    'आणि',
    'किंवा',
    'तर',
    'पण',
    'हे',
    'ते',
    'त्या',
    'नी',
    'शी',
    'वर',
    'वरून',
    'खाली',
    'साठी',
    'मध्ये',
    'च्या',
    'ची',
    'चा',
    'चे',
    'करा',
    'करावे',
    'सांगा',
    'बघा',
    'द्या',
  };

  /// Domain-specific synonyms and acronym mappings to enrich query tokens.
  static const Map<String, List<String>> _domainAliases = {
    'je': ['junior', 'engineer', 'dispatcher'],
    'jr': ['junior', 'engineer'],
    'fo': ['field', 'officer', 'execution', 'squad'],
    'squad': ['field', 'officer', 'execution'],
    'contractor': ['field', 'officer', 'execution'],
    'ee': ['ward', 'department', 'lead', 'executive', 'engineer'],
    'swm': ['solid', 'waste', 'management', 'garbage'],
    'kachra': ['garbage', 'waste', 'solid_waste_management'],
    'pothole': ['potholes', 'roads', 'maintenance_roads', 'paver'],
    'potholes': ['pothole', 'roads', 'maintenance_roads'],
    'tat': ['sla', 'turnaround', 'timeline'],
    'tat/sla': ['sla', 'turnaround', 'timeline'],
    'mcgm': ['bmc', 'brihanmumbai', 'municipal', 'corporation'],
    'bmc': ['mcgm', 'brihanmumbai', 'municipal', 'corporation'],
    'reopen': ['reopened', 'rework', 'quality', 'audit'],
    'reopened': ['reopen', 'rework', 'quality', 'audit'],
    'reworking': ['rework', 'reopen'],
    'blocked': ['obstacle', 'delay', 'weather', 'traffic'],
    'offline': ['sync', 'pending', 'queue', 'local'],
    'gps': ['location', 'pin', 'map', 'coordinates'],
    'maplibre': ['map', 'gis', 'basemap', 'satellite'],
    'report': ['submit', 'complaint', 'lifecycle', 'reporting'],
    'issue': ['complaint', 'grievance', 'problem', 'hazard'],
    'issues': ['complaint', 'grievance', 'problem', 'hazard', 'complaints'],
    'photo': ['photos', 'evidence', 'image', 'picture', 'upload', 'resolution'],
    'photos': ['photo', 'evidence', 'image', 'picture', 'upload', 'resolution'],
    'resolution': ['resolved', 'after_work', 'fix', 'completion', 'evidence'],
    'repair': ['field_execution', 'execution', 'maintenance', 'fix', 'resolution'],
    'closed': ['closure', 'completed', 'status_closed', 'lifecycle_closed'],
  };

  /// Normalizes a query into a clean, lowercased string preserving Devanagari script,
  /// ward names, slashes, and hyphens.
  static String cleanText(String query) {
    var text = query.trim().toLowerCase();
    // Normalize special characters but preserve Devanagari (\u0900-\u097F), ward slashes (e.g. 'f/north', 'k/west') and hyphens
    text = text.replaceAll(RegExp(r"[^\w\u0900-\u097F\s\/\-]"), ' ');
    // Collapse multi-spaces
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Extracts meaningful non-stopword tokens from the query.
  static List<String> extractTokens(String query) {
    final cleaned = cleanText(query);
    if (cleaned.isEmpty) return const [];

    final rawTokens = cleaned.split(' ');
    final tokens = <String>[];

    for (final raw in rawTokens) {
      final token = raw.trim();
      if (token.length > 1 && !_stopWords.contains(token)) {
        tokens.add(token);
      }
    }

    return tokens;
  }

  /// Expands tokens with domain aliases and multilingual lexicon bridge tokens,
  /// returning a unified token set for RAG retrieval scoring.
  static Set<String> getExpandedTokenSet(String query) {
    final tokens = extractTokens(query);
    final expanded = <String>{...tokens};

    // 1. English domain aliases
    for (final token in tokens) {
      final aliases = _domainAliases[token];
      if (aliases != null) {
        expanded.addAll(aliases);
      }
    }

    // 2. Multilingual Lexicon Bridge (Devanagari Hindi/Marathi & Transliterations -> Canonical Tokens)
    final bridgeTokens = CivicAssistantLexicon.getCanonicalBridgeTokens(tokens);
    expanded.addAll(bridgeTokens);

    return expanded;
  }
}
