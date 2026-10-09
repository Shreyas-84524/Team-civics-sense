import 'account_help_knowledge.dart';
import 'assignment_workflow_knowledge.dart';
import 'citizen_workflows_knowledge.dart';
import 'civicfix_overview_knowledge.dart';
import 'complaint_categories_knowledge.dart';
import 'complaint_lifecycle_knowledge.dart';
import 'complaint_statuses_knowledge.dart';
import 'departments_knowledge.dart';
import 'evidence_rules_knowledge.dart';
import 'faq_knowledge.dart';
import 'field_execution_knowledge.dart';
import 'government_roles_knowledge.dart';
import 'knowledge_entry.dart';
import 'map_gis_knowledge.dart';
import 'resolution_rework_knowledge.dart';
import 'sla_rules_knowledge.dart';
import 'troubleshooting_knowledge.dart';
import 'verification_workflow_knowledge.dart';
import 'wards_knowledge.dart';

/// Central authoritative CivicFix Knowledge Repository.
///
/// Serves as the single source of truth for all verified CivicFix product knowledge,
/// complaint lifecycles, government hierarchies, BMC departments, wards, evidence rules,
/// SLAs, and citizen troubleshooting.
class CivicAssistantKnowledge {
  /// Unmodifiable aggregated collection of all canonical knowledge entries.
  static final List<KnowledgeEntry> allEntries = List<KnowledgeEntry>.unmodifiable([
    ...overviewKnowledgeEntries,
    ...citizenWorkflowsKnowledgeEntries,
    ...complaintLifecycleKnowledgeEntries,
    ...complaintStatusesKnowledgeEntries,
    ...complaintCategoriesKnowledgeEntries,
    ...departmentsKnowledgeEntries,
    ...wardsKnowledgeEntries,
    ...governmentRolesKnowledgeEntries,
    ...evidenceRulesKnowledgeEntries,
    ...assignmentWorkflowKnowledgeEntries,
    ...fieldExecutionKnowledgeEntries,
    ...resolutionReworkKnowledgeEntries,
    ...slaRulesKnowledgeEntries,
    ...verificationWorkflowKnowledgeEntries,
    ...mapGisKnowledgeEntries,
    ...accountHelpKnowledgeEntries,
    ...faqKnowledgeEntries,
    ...troubleshootingKnowledgeEntries,
  ]);

  /// Fast indexed lookup map by entry ID.
  static final Map<String, KnowledgeEntry> _entriesById = {
    for (final entry in allEntries) entry.id: entry,
  };

  /// Retrieves a knowledge entry by its unique ID.
  static KnowledgeEntry? getById(String id) => _entriesById[id];

  /// Retrieves all knowledge entries belonging to a given topic.
  static List<KnowledgeEntry> getByTopic(String topic) {
    final cleanTopic = topic.trim().toLowerCase();
    return allEntries.where((e) => e.topic.toLowerCase() == cleanTopic).toList();
  }

  /// Searches the knowledge repository by ranking matches across tags, titles, and content.
  static List<KnowledgeEntry> search(String query, {int limit = 5}) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return const [];

    final tokens = clean.split(RegExp(r'\s+')).where((t) => t.length > 1).toList();
    if (tokens.isEmpty) return const [];

    final scored = <KnowledgeEntry, int>{};

    for (final entry in allEntries) {
      int score = 0;
      final titleLower = entry.title.toLowerCase();
      final contentLower = entry.canonicalContent.toLowerCase();

      // Exact phrase matches
      if (titleLower.contains(clean)) score += 50;
      if (contentLower.contains(clean)) score += 20;

      // Tag matches
      for (final tag in entry.tags) {
        final tagLower = tag.toLowerCase();
        if (tagLower == clean) {
          score += 40;
        } else if (tagLower.contains(clean) || clean.contains(tagLower)) {
          score += 25;
        }
      }

      // Token matches
      for (final token in tokens) {
        if (titleLower.contains(token)) score += 10;
        if (entry.tags.any((t) => t.toLowerCase().contains(token))) score += 8;
        if (contentLower.contains(token)) score += 2;
      }

      if (score > 0) {
        scored[entry] = score;
      }
    }

    final sorted = scored.keys.toList()
      ..sort((a, b) => scored[b]!.compareTo(scored[a]!));

    return sorted.take(limit).toList();
  }

  /// Map of verified canonical explanations for quick direct response synthesis.
  static final Map<String, String> verifiedExplanations = {
    'what_is_civicfix':
        getById('faq_what_is_civicfix')?.canonicalContent ??
            'CivicFix is Greater Mumbai\'s official municipal grievance redressal, spatial AI verification, and ground execution platform for the Brihanmumbai Municipal Corporation (BMC / MCGM).',
    'post_submission_lifecycle':
        getById('lifecycle_overview')?.canonicalContent ??
            'After submitting a complaint, it goes through 5 stages: 1. Reported, 2. Under Verification, 3. Assigned, 4. In Progress, 5. Resolved.',
    'under_verification_meaning':
        getById('status_under_verification')?.canonicalContent ??
            '"Under Verification" (Stage 2) means your complaint is being reviewed for photo authenticity, duplicate check, and department routing.',
    'who_handles_complaint':
        getById('faq_who_handles_my_complaint')?.canonicalContent ??
            'Your complaint is routed to the Junior Engineer in your Ward\'s relevant department, who assigns a dedicated Field Execution Officer for physical repairs.',
    'junior_engineer_role':
        getById('roles_junior_engineer')?.canonicalContent ??
            'A Junior Engineer (JE) is the technical supervisor and dispatcher for your Ward\'s department.',
    'execution_officer_role':
        getById('roles_field_officer')?.canonicalContent ??
            'A Field Execution Officer is the municipal technician or squad who performs the physical repair work on the ground and captures after-work photos.',
    'reopen_workflow':
        getById('resolution_rework_workflow')?.canonicalContent ??
            'If a resolved repair is substandard, the Ward Department Lead reopens the ticket for rework without resetting the SLA timer.',
    'ai_verification_fallback':
        getById('verification_fallback')?.canonicalContent ??
            'If automated AI verification is temporarily unavailable, complaints are safely placed in the manual review queue for the Ward Department Lead.',
    'how_to_report':
        getById('citizen_report_flow')?.canonicalContent ??
            'To report an issue: Tap "Report an Issue" on Home, provide details, attach up to 3 photos, confirm GPS pin, and submit.',
    'how_to_track':
        getById('citizen_track_flow')?.canonicalContent ??
            'To track your complaint: Tap "My Complaints" in bottom navigation to view the live 5-stage timeline.',
    'edit_complaint_rule':
        getById('faq_edit_complaint')?.canonicalContent ??
            'Once submitted, core complaint details cannot be edited to preserve audit integrity.',
    'map_explanation':
        getById('map_gis_overview')?.canonicalContent ??
            'The Hazard Map displays interactive color-coded pins for reported issues in your area with category and radius filtering.',
    'departments_overview':
        getById('departments_overview')?.canonicalContent ?? '',
    'wards_overview':
        getById('wards_overview')?.canonicalContent ?? '',
    'sla_rules_overview':
        getById('sla_rules_overview')?.canonicalContent ?? '',
  };

  /// Consolidated verified knowledge text for system prompt grounding.
  static String get consolidatedVerifiedText => _buildConsolidatedText();

  static String _buildConsolidatedText() {
    final buffer = StringBuffer();

    buffer.writeln('=== CIVICFIX AUTHORITATIVE CANONICAL KNOWLEDGE ===\n');

    buffer.writeln('1. PLATFORM OVERVIEW & JURISDICTION:');
    for (final e in getByTopic('overview')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }

    buffer.writeln('\n2. CITIZEN WORKFLOWS & REPORTING:');
    for (final e in getByTopic('workflows')) {
      buffer.writeln('• ${e.title}:\n${e.canonicalContent}');
    }

    buffer.writeln('\n3. 5-STAGE COMPLAINT LIFECYCLE & STATUSES:');
    for (final e in getByTopic('lifecycle')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }
    for (final e in getByTopic('statuses')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }

    buffer.writeln('\n4. 6-TIER GOVERNMENT ROLES & SEPARATION OF DUTIES:');
    for (final e in getByTopic('roles')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }

    buffer.writeln('\n5. 18 CANONICAL BMC DEPARTMENTS:');
    for (final e in getByTopic('departments')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }

    buffer.writeln('\n6. 24 CANONICAL BMC WARDS (A TO T):');
    for (final e in getByTopic('wards')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }

    buffer.writeln('\n7. SLA RULES & REWORK POLICY:');
    for (final e in getByTopic('sla')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }
    for (final e in getByTopic('rework')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }

    buffer.writeln('\n8. EVIDENCE & VERIFICATION PIPELINE:');
    for (final e in getByTopic('evidence')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }
    for (final e in getByTopic('verification')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }

    buffer.writeln('\n9. MAP GIS & TROUBLESHOOTING:');
    for (final e in getByTopic('map_gis')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }
    for (final e in getByTopic('troubleshooting')) {
      buffer.writeln('• ${e.title}: ${e.canonicalContent}');
    }

    return buffer.toString();
  }

  /// Rejection message when a query is outside CivicFix domain or unsupported.
  static const String strictHallucinationBoundaryMessage =
      "I don't have verified CivicFix information to answer that accurately. I can only assist with verified CivicFix workflows, complaint reporting, BMC departments, wards, and tracking.";
}
