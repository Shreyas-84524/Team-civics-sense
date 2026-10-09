import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/assistant/knowledge/civic_assistant_knowledge.dart';
import 'package:civic_app/User UI/services/assistant_service.dart';

void main() {
  group('CivicFix Chatbot Phase 3 — Authoritative Knowledge Base Tests', () {
    test('Knowledge repository has no duplicate IDs and no empty contents', () {
      final entries = CivicAssistantKnowledge.allEntries;
      expect(entries, isNotEmpty);

      final seenIds = <String>{};
      for (final entry in entries) {
        expect(entry.id, isNotEmpty);
        expect(entry.title, isNotEmpty);
        expect(entry.topic, isNotEmpty);
        expect(entry.canonicalContent, isNotEmpty);
        expect(entry.tags, isNotEmpty);
        expect(entry.sourceReference, isNotEmpty);

        expect(seenIds.contains(entry.id), isFalse,
            reason: 'Duplicate entry ID found: ${entry.id}');
        seenIds.add(entry.id);
      }
    });

    test('Contains exactly 18 canonical BMC departments with correct codes', () {
      final deptEntries = CivicAssistantKnowledge.getByTopic('departments');
      // 1 overview + 18 departments = 19 entries in topic
      expect(deptEntries.length, equals(19));

      final expectedDepartmentCodes = [
        'maintenance_roads',
        'water_works',
        'solid_waste_management',
        'building_factory',
        'garden_trees',
        'public_health',
        'pest_control_insecticide',
        'encroachment',
        'licence',
        'shops_establishments',
        'assessment_collection',
        'estate',
        'colony_slum',
        'education_schools',
        'security',
        'legal',
        'administration_establishment',
        'town_planning_development_plan',
      ];

      for (final code in expectedDepartmentCodes) {
        final entry = CivicAssistantKnowledge.getById('dept_$code');
        expect(entry, isNotNull, reason: 'Missing canonical department: $code');
        expect(entry!.canonicalContent, contains(code));
      }

      // Verify internal/administrative departments are scoped to government audience
      expect(CivicAssistantKnowledge.getById('dept_security')!.audience, equals('government'));
      expect(CivicAssistantKnowledge.getById('dept_legal')!.audience, equals('government'));
      expect(CivicAssistantKnowledge.getById('dept_administration_establishment')!.audience,
          equals('government'));
    });

    test('Contains all 24 canonical BMC administrative wards (A to T)', () {
      final wardEntries = CivicAssistantKnowledge.getByTopic('wards');
      // 1 overview + 24 wards = 25 entries in topic
      expect(wardEntries.length, equals(25));

      final expectedWardIds = [
        'ward_a',
        'ward_b',
        'ward_c',
        'ward_d',
        'ward_e',
        'ward_f_north',
        'ward_f_south',
        'ward_g_north',
        'ward_g_south',
        'ward_h_east',
        'ward_h_west',
        'ward_k_east',
        'ward_k_west',
        'ward_l',
        'ward_m_east',
        'ward_m_west',
        'ward_n',
        'ward_p_north',
        'ward_p_south',
        'ward_r_central',
        'ward_r_north',
        'ward_r_south',
        'ward_s',
        'ward_t',
      ];

      for (final wardId in expectedWardIds) {
        final entry = CivicAssistantKnowledge.getById(wardId);
        expect(entry, isNotNull, reason: 'Missing canonical ward: $wardId');
      }

      final overview = CivicAssistantKnowledge.getById('wards_overview');
      expect(overview!.canonicalContent, contains('24 administrative Wards'));
      expect(overview.canonicalContent, contains('Island City'));
      expect(overview.canonicalContent, contains('Western Suburbs'));
      expect(overview.canonicalContent, contains('Eastern Suburbs'));
    });

    test('Defines 6 government roles with Junior Engineer != Field Officer invariant', () {
      final roleEntries = CivicAssistantKnowledge.getByTopic('roles');
      expect(roleEntries, isNotEmpty);

      final jeEntry = CivicAssistantKnowledge.getById('roles_junior_engineer');
      expect(jeEntry, isNotNull);
      expect(jeEntry!.canonicalContent, contains('dispatcher'));

      final fieldOfficerEntry = CivicAssistantKnowledge.getById('roles_field_officer');
      expect(fieldOfficerEntry, isNotNull);
      expect(fieldOfficerEntry!.canonicalContent, contains('physical'));

      final invariantEntry = CivicAssistantKnowledge.getById('roles_invariant_je_vs_field_officer');
      expect(invariantEntry, isNotNull);
      expect(invariantEntry!.canonicalContent,
          contains('assignedJuniorEngineerId != assignedFieldOfficerId'));

      final leadEntry = CivicAssistantKnowledge.getById('roles_ward_department_lead');
      expect(leadEntry, isNotNull);
      expect(leadEntry!.canonicalContent, contains('Quality Review'));
    });

    test('Validates 5-stage complaint lifecycle and rework SLA preservation', () {
      final lifecycleOverview = CivicAssistantKnowledge.getById('lifecycle_overview');
      expect(lifecycleOverview, isNotNull);
      expect(lifecycleOverview!.canonicalContent, contains('1. Reported'));
      expect(lifecycleOverview.canonicalContent, contains('2. Under Verification'));
      expect(lifecycleOverview.canonicalContent, contains('3. Assigned'));
      expect(lifecycleOverview.canonicalContent, contains('4. In Progress'));
      expect(lifecycleOverview.canonicalContent, contains('5. Resolved'));

      final reworkEntry = CivicAssistantKnowledge.getById('rework_sla_preservation');
      expect(reworkEntry, isNotNull);
      expect(reworkEntry!.canonicalContent, contains('does NOT reset'));

      final slaStartEntry = CivicAssistantKnowledge.getById('sla_clock_start_policy');
      expect(slaStartEntry, isNotNull);
      expect(slaStartEntry!.canonicalContent, contains('starts immediately at the moment of submission'));
    });

    test('Validates evidence rules and mandatory After-Work photo requirement', () {
      final citizenEvidence = CivicAssistantKnowledge.getById('evidence_citizen_rules');
      expect(citizenEvidence, isNotNull);
      expect(citizenEvidence!.canonicalContent, contains('up to 3 clear photos'));

      final afterWorkEvidence = CivicAssistantKnowledge.getById('evidence_after_work');
      expect(afterWorkEvidence, isNotNull);
      expect(afterWorkEvidence!.canonicalContent, contains('After-Work photo'));
      expect(afterWorkEvidence.canonicalContent, contains('photograph'));
    });

    test('Validates AI verification fallback to Ward Lead manual review', () {
      final fallbackEntry = CivicAssistantKnowledge.getById('verification_fallback');
      expect(fallbackEntry, isNotNull);
      expect(fallbackEntry!.canonicalContent, contains('Ward Department Lead'));
    });

    test('Validates offline queue and GIS MapLibre knowledge', () {
      final offlineEntry = CivicAssistantKnowledge.getById('troubleshoot_offline_queue');
      expect(offlineEntry, isNotNull);
      expect(offlineEntry!.canonicalContent, contains('local device queue'));

      final mapEntry = CivicAssistantKnowledge.getById('map_gis_overview');
      expect(mapEntry, isNotNull);
      expect(mapEntry!.canonicalContent, contains('MapLibre GL'));
    });

    test('Search ranking returns top matching canonical knowledge entries', () {
      final potholeResults = CivicAssistantKnowledge.search('pothole road damage');
      expect(potholeResults, isNotEmpty);
      expect(potholeResults.any((e) => e.tags.contains('pothole') || e.tags.contains('roads')), isTrue);

      final wardResults = CivicAssistantKnowledge.search('Ward K West Bandra');
      expect(wardResults, isNotEmpty);
      expect(wardResults.any((e) => e.id.contains('ward')), isTrue);

      final slaResults = CivicAssistantKnowledge.search('SLA turnaround deadline');
      expect(slaResults, isNotEmpty);
      expect(slaResults.any((e) => e.topic == 'sla'), isTrue);
    });

    test('Consolidated prompt text contains all authoritative knowledge sections', () {
      final promptText = CivicAssistantKnowledge.consolidatedVerifiedText;
      expect(promptText, contains('1. PLATFORM OVERVIEW & JURISDICTION'));
      expect(promptText, contains('2. CITIZEN WORKFLOWS & REPORTING'));
      expect(promptText, contains('3. 5-STAGE COMPLAINT LIFECYCLE & STATUSES'));
      expect(promptText, contains('4. 6-TIER GOVERNMENT ROLES & SEPARATION OF DUTIES'));
      expect(promptText, contains('5. 18 CANONICAL BMC DEPARTMENTS'));
      expect(promptText, contains('6. 24 CANONICAL BMC WARDS (A TO T)'));
      expect(promptText, contains('7. SLA RULES & REWORK POLICY'));
      expect(promptText, contains('8. EVIDENCE & VERIFICATION PIPELINE'));
      expect(promptText, contains('9. MAP GIS & TROUBLESHOOTING'));
    });

    test('Hallucination boundary message is strictly defined', () {
      expect(CivicAssistantKnowledge.strictHallucinationBoundaryMessage,
          contains("I don't have verified CivicFix information"));
    });

    test('Conversational assistant service accurately retrieves Phase 3 knowledge', () async {
      final service = CivicAssistantService();

      // Test department inquiry
      final deptReply = await service.processQuery(
        query: 'What are the BMC departments?',
        languageCode: 'en',
      );
      expect(deptReply.text, contains('18 canonical Brihanmumbai Municipal Corporation'));

      // Test ward inquiry
      final wardReply = await service.processQuery(
        query: 'What are the 24 wards in Mumbai?',
        languageCode: 'en',
      );
      expect(wardReply.text, contains('24 administrative Wards'));

      // Test SLA inquiry
      final slaReply = await service.processQuery(
        query: 'When does the SLA clock start?',
        languageCode: 'en',
      );
      expect(slaReply.text, contains('starts immediately'));

      // Test SLA reset on rework
      final reworkSlaReply = await service.processQuery(
        query: 'Does the SLA reset on rework?',
        languageCode: 'en',
      );
      expect(reworkSlaReply.text, contains('does NOT reset'));
    });
  });
}
