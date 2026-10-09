# CivicFix Chatbot Rollout: Phase 3 Report
## Authoritative CivicFix Knowledge Base

**Date:** October 8, 2026  
**Status:** Completed & Verified  
**Static Analysis:** 0 issues found (`flutter analyze`)  
**Automated Tests:** 30 / 30 tests passing (`flutter test test/core/assistant/`)  
**Target Platform:** Flutter (Citizen Mobile App) / Brihanmumbai Municipal Corporation (BMC / MCGM)

---

### 1. Executive Summary

Phase 2 established the conversational personality, semantic intent routing, conversation memory, and prompt foundation. **Phase 3** has now constructed the **Authoritative CivicFix Knowledge Base**—a structured, canonical source of truth for the CivicFix citizen chatbot.

The chatbot no longer depends on loosely embedded or scattered product strings. All domain facts, municipal workflows, administrative roles, department codes, ward divisions, evidence protocols, and SLA rules are codified in a modular, strongly typed knowledge repository (`lib/core/assistant/knowledge/`).

```
                              ┌────────────────────────────────────────┐
                              │       CivicFix Assistant Chatbot       │
                              └───────────────────┬────────────────────┘
                                                  │
                                                  ▼
                              ┌────────────────────────────────────────┐
                              │  CivicAssistantKnowledge Central Core  │
                              │  - Indexed Lookup Map (_entriesById)   │
                              │  - Topic Filter (getByTopic)           │
                              │  - Multi-field Search (search)         │
                              │  - System Prompt Formatter             │
                              │  - Strict Hallucination Boundary       │
                              └───────────────────┬────────────────────┘
                                                  │
         ┌───────────────────┬────────────────────┼───────────────────┬───────────────────┐
         ▼                   ▼                    ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ Platform & Flow │ │  18 BMC Depts   │ │  24 BMC Wards   │ │ 6 Gov Hierarchy │ │ Lifecycle & SLA │
│ - Overview      │ │ - Canonical     │ │ - Island City   │ │ - Super Admin   │ │ - 5-Stage Flow  │
│ - 4-Step Report │ │   Codes (18)    │ │ - West Suburbs  │ │ - Zonal DMC     │ │ - Invariant SLA │
│ - Map & GIS     │ │ - Descriptions  │ │ - East Suburbs  │ │ - Central HOD   │ │ - Quality Audit │
│ - Rewards & OTP │ │ - Public/Admin  │ │ - Coordinates   │ │ - Ward Lead     │ │ - Rework Policy │
│ - Evidence Rules│ │   Scoping       │ │ - Pincodes      │ │ - JE vs Squad   │ │ - AI Fallback   │
└─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘
```

---

### 2. Knowledge Source Precedence & Audit Record

To eliminate conflicting or outdated product information, strict precedence rules were enforced:

| Priority | Source | Description | Authority Level |
| :--- | :--- | :--- | :--- |
| **1 (Highest)** | Production Code Constants | `supabase/functions/_shared/departments.ts` (18 canonical BMC departments, 24 BMC Wards A to T, coordinates, zones) | **Absolute Canonical** |
| **2** | Service & Workflow Code | Ingestion, JE auto-routing, Field Officer dispatch, SLA preservation, signed URL evidence | **Absolute Canonical** |
| **3** | Firestore Schema & Invariants | `assignedJuniorEngineerId != assignedFieldOfficerId`, immutable SLA clocks (`slaStartedAt`), before/after photos | **Absolute Canonical** |
| **4** | Project Documentation | `Brain.md`, `TeamCivicSense/Brain.md` (6-tier role hierarchy, offline queue, MapLibre basemaps) | **Authoritative** |
| **5** | UI Localization Copy | `app_en.arb`, `app_hi.arb`, `app_mr.arb` | **Presentation Layer** |
| **6 (Lowest)** | Legacy Hardcoded Strings | Phase 1 canned responses | **Superseded / Deprecated** |

---

### 3. Modular Knowledge Architecture (`lib/core/assistant/knowledge/`)

The knowledge module is decomposed into 19 specialized, single-responsibility files under `TeamCivicSense/civic_app/lib/core/assistant/knowledge/`:

| Module File | Purpose | Key Knowledge Represented |
| :--- | :--- | :--- |
| [`knowledge_entry.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/knowledge_entry.dart) | Data Model | Strongly typed `KnowledgeEntry` (`id`, `title`, `topic`, `audience`, `tags`, `canonicalContent`, `relatedTopics`, `sourceReference`). |
| [`civicfix_overview_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/civicfix_overview_knowledge.dart) | Platform Overview | Purpose, citizen & government dual portal capabilities, BMC / MCGM governance. |
| [`citizen_workflows_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/citizen_workflows_knowledge.dart) | Citizen Flows | 4-step reporting workflow, 5-stage live timeline tracking, Civic Points & badges, community upvoting. |
| [`complaint_lifecycle_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/complaint_lifecycle_knowledge.dart) | Lifecycle Stages | 5-stage standard lifecycle (Reported -> Under Verification -> Assigned -> In Progress -> Resolved) + Quality Review. |
| [`complaint_statuses_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/complaint_statuses_knowledge.dart) | Status Definitions | Detailed citizen-facing meanings for `reported`, `underVerification`, `assigned`, `inProgress`, `resolved`, `closed`, `blocked`, and `reopened`. |
| [`complaint_categories_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/complaint_categories_knowledge.dart) | Grievance Categories | Potholes, Water Leaks, Garbage, Streetlights, Encroachment, etc., mapped to municipal departments. |
| [`departments_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/departments_knowledge.dart) | BMC Departments | **All 18 canonical BMC departments** with exact system codes, responsibilities, and public vs. administrative scoping. |
| [`wards_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/wards_knowledge.dart) | BMC Wards | **All 24 administrative Wards (A through T)** spanning Island City, Western Suburbs, and Eastern Suburbs. |
| [`government_roles_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/government_roles_knowledge.dart) | 6 Gov Roles & Invariant | 6 administrative tiers + Junior Engineer dispatcher vs Field Officer executor distinction (`assignedJuniorEngineerId != assignedFieldOfficerId`). |
| [`evidence_rules_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/evidence_rules_knowledge.dart) | Evidence Subsystem | Citizen evidence (up to 3 photos), mandatory After-Work photo before resolution, rework photo audit, short-lived signed URLs. |
| [`assignment_workflow_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/assignment_workflow_knowledge.dart) | Auto-Assignment | Spatial Ward scoping, department mapping, least-loaded Junior Engineer auto-routing, and field squad dispatch. |
| [`field_execution_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/field_execution_knowledge.dart) | Ground Remediation | "Start Work" action, physical obstacle logging (`isBlocked = true`, weather/traffic/access), work resumption. |
| [`resolution_rework_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/resolution_rework_knowledge.dart) | Quality Audit & Rework | Ward Department Lead quality review, defective repair reopening, and immutable SLA continuity. |
| [`sla_rules_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/sla_rules_knowledge.dart) | SLA & Turnaround | Immediate clock start at Stage 1 (Reported), severity tiers (24h/48h/72h/7d), non-resetting timers on rework/obstacles. |
| [`verification_workflow_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/verification_workflow_knowledge.dart) | 2-Stage Verification | AI photo authenticity, 50m spatial deduplication/clustering, and graceful manual review fallback to Ward Lead. |
| [`map_gis_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/map_gis_knowledge.dart) | Map & Spatial GIS | MapLibre GL Native, vector/satellite layers, color-coded hazard markers, dynamic zoom clustering, and radius filtering. |
| [`account_help_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/account_help_knowledge.dart) | Authentication & Privacy | Phone number + 6-digit OTP login, profile settings, and strict PII privacy shielding on public feeds. |
| [`faq_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/faq_knowledge.dart) | 19 Canonical FAQs | Curated Q&As answering reporting, tracking, editing immutability, SLAs, rework, AI fallback, points, and coverage. |
| [`troubleshooting_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/troubleshooting_knowledge.dart) | Troubleshooting | Local SQLite offline queue, sync pending, GPS precision tips, upload recovery, and SLA escalation policies. |
| [`civic_assistant_knowledge.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/lib/core/assistant/knowledge/civic_assistant_knowledge.dart) | Central Registry | Aggregator of all entries, indexed lookup, multi-field search engine, prompt grounding text, and hallucination boundary. |

---

### 4. Authoritative Canonical Matrix

#### A. The 18 Canonical BMC Municipal Departments
Derived from `TeamCivicSense/supabase/functions/_shared/departments.ts`:

1. `maintenance_roads`: Maintenance (Roads, Pavement & Traffic) — Asphalt/concrete repairs, potholes, footpath pavers, traffic islands.
2. `water_works`: Water Works & Supply — Potable water distribution, trunk mains, pipe bursts, leak detection, contamination.
3. `solid_waste_management`: Solid Waste Management (SWM) — Door-to-door collection, street sweeping, community bins, debris.
4. `building_factory`: Building & Factory — Unauthorized construction monitoring, C1/C2 structural hazard notices.
5. `garden_trees`: Gardens & Trees — Park maintenance, pre-monsoon tree trimming, road clearance for fallen trees.
6. `public_health`: Public Health — Municipal dispensaries, public sanitation, disease surveillance, public toilets.
7. `pest_control_insecticide`: Pest Control & Insecticide — Mosquito breeding spot elimination, fogging, larvicide spraying.
8. `encroachment`: Encroachment Removal — Unauthorized hawker removal, pedestrian footpath clearance.
9. `licence`: Licence Department — Trade licences, advertisement hoardings, sky signs, illegal banners.
10. `shops_establishments`: Shops & Establishments — Gumasta Act compliance, commercial operating hours.
11. `assessment_collection`: Assessment & Collection — Property tax assessment, billing, capital value revisions.
12. `estate`: Estate Department — Municipal land leases, municipal property recovery.
13. `colony_slum`: Colony & Slum Improvement — Slum sanitation, informal settlement walkways and community taps.
14. `education_schools`: Education & Municipal Schools — BMC primary/secondary school infrastructure.
15. `security`: Security Force — Internal municipal security (Headquarters, hospitals, reservoirs) *(Government audience)*.
16. `legal`: Legal Department — Civil, High Court, and Supreme Court municipal litigation *(Government audience)*.
17. `administration_establishment`: Administration & Establishment — Internal municipal HR, payroll, and postings *(Government audience)*.
18. `town_planning_development_plan`: Town Planning & Development Plan — Greater Mumbai Development Plan (DP 2034) zoning.

#### B. The 24 Canonical BMC Administrative Wards
Divided into 3 geographic zones:
- **Island City (9 Wards):** `A` (Colaba, Fort, Nariman Point), `B` (Sandhurst Road, Dongri), `C` (Marine Lines, Bhuleshwar), `D` (Grant Road, Malabar Hill), `E` (Byculla, Mumbai Central), `F/North` (Matunga, Sion), `F/South` (Parel, Sewri), `G/North` (Dharavi, Dadar West), `G/South` (Worli, Lower Parel).
- **Western Suburbs (9 Wards):** `H/East` (Bandra East, Santacruz East, BKC), `H/West` (Bandra West, Khar), `K/East` (Andheri East, Jogeshwari East), `K/West` (Andheri West, Lokhandwala, Juhu), `P/North` (Malad), `P/South` (Goregaon), `R/Central` (Borivali), `R/North` (Dahisar), `R/South` (Kandivali).
- **Eastern Suburbs (6 Wards):** `L` (Kurla, Sakinaka), `M/East` (Govandi, Mankhurd, Deonar), `M/West` (Chembur, Tilak Nagar), `N` (Ghatkopar, Vikhroli West), `S` (Bhandup, Powai), `T` (Mulund, Nahur).

#### C. The 6 Government Roles & The Dual-Role Invariant
1. `government_super_admin`: Municipal Commissioner / System Administrator with city-wide oversight.
2. `zonal_dmc`: Deputy Municipal Commissioner managing a multi-ward zone.
3. `central_department_hod`: Head of Department overseeing a municipal discipline across all 24 Wards.
4. `ward_officer`: Assistant Commissioner leading all administrative and civic operations in a Ward.
5. `ward_department_lead`: Executive Engineer overseeing a department in a Ward, conducting Quality Review and handling reworks.
6. `department_crew` (Dual Operational Roles):
   - **Junior Engineer (JE):** Technical owner in the Ward who reviews grievances and dispatches field squads (`assignedJuniorEngineerId`).
   - **Field Execution Officer:** On-site technician/squad performing physical repairs and uploading completion photos (`assignedFieldOfficerId`).
   - **Technical Invariant:** `assignedJuniorEngineerId != assignedFieldOfficerId` (The dispatcher cannot self-certify physical completion).

#### D. Complaint Lifecycle, Rework & SLA Invariants
- **Stage 1 (Reported):** Geotagged grievance logged, unique ticket ID generated (e.g. `CF-2026-000042`), **SLA clock starts immediately**.
- **Stage 2 (Under Verification):** 2-Stage verification (AI authenticity check, 50m spatial deduplication, department confirmation). If AI services are offline, grievances fall back gracefully to the manual review queue for the Ward Department Lead.
- **Stage 3 (Assigned):** Auto-routed to the least-loaded Ward JE, who assigns a dedicated Field Execution Officer.
- **Stage 4 (In Progress):** Field Officer arrives on site, taps "Start Work", and performs physical repairs. If blocked by weather, traffic, or access, ticket is marked "Blocked" with a logged reason.
- **Stage 5 (Resolved):** Field Officer uploads mandatory After-Work photo evidence and remarks.
- **Quality Review & Rework:** Ward Department Lead audits the repair. If defective, ticket is reopened for rework. **The SLA clock does NOT reset on rework or reassignment.**

---

### 5. Central Registry & Search Engine Implementation

`CivicAssistantKnowledge` provides high-performance retrieval and prompt grounding:

```dart
// 1. Fast ID Lookup (O(1))
final entry = CivicAssistantKnowledge.getById('dept_water_works');

// 2. Topic Filtering (O(N))
final depts = CivicAssistantKnowledge.getByTopic('departments');

// 3. Multi-field Search Ranking (Title, Tags, Content Token Scoring)
final searchResults = CivicAssistantKnowledge.search('pothole road repair');

// 4. Consolidated Prompt Generation for LLM Grounding
final systemGrounding = CivicAssistantKnowledge.consolidatedVerifiedText;

// 5. Strict Hallucination Boundary Enforcement
if (!isSupported) {
  return CivicAssistantKnowledge.strictHallucinationBoundaryMessage;
}
```

---

### 6. Automated Verification & Test Scorecard

Static analysis and comprehensive automated tests were executed across all assistant features:

| Test Suite File | Tests | Status | Scope Verified |
| :--- | :---: | :---: | :--- |
| [`civic_assistant_knowledge_test.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/test/core/assistant/civic_assistant_knowledge_test.dart) | 10 | **PASS (100%)** | 18 departments, 24 wards, 6 roles, JE!=Field Officer invariant, 5-stage lifecycle, SLA preservation, evidence rules, AI fallback, offline queue, search ranking, hallucination rejection. |
| [`civic_assistant_foundation_test.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/test/core/assistant/civic_assistant_foundation_test.dart) | 17 | **PASS (100%)** | 8 intent categories, keyword collision fixes, multi-turn session memory, Hindi/Marathi localization, prompt assembly. |
| [`assistant_screen_widget_test.dart`](file:///C:/Learning%20some%20new%20stuf/SPP/CivicFix/TeamCivicSense/civic_app/test/core/assistant/assistant_screen_widget_test.dart) | 3 | **PASS (100%)** | End-to-end Chat UI rendering, suggestion chip interaction, query dispatch, clear chat reset. |
| **Total Automated Tests** | **30** | **30 / 30 PASS (100%)** | **Full Suite Verified** |

#### Static Analysis Result
```
Analyzing civic_app...
No issues found! (ran in 8.7s)
```

---

### 7. Deliverables & Artifacts Summary

1. **Structured Knowledge Modules:** 19 dedicated Dart files in `TeamCivicSense/civic_app/lib/core/assistant/knowledge/`.
2. **Central Knowledge Engine:** `CivicAssistantKnowledge` with indexed caching, topic aggregation, search ranking, and prompt formatting.
3. **Integration Updates:** `CivicAssistantConversationEngine` and `CivicAssistantIntentRouter` updated to query canonical knowledge entries.
4. **Validation Test Suite:** 10 new comprehensive unit tests in `test/core/assistant/civic_assistant_knowledge_test.dart`.
5. **Project Brain Update:** `Brain.md` and `TeamCivicSense/Brain.md` updated with Section 11 (Phase 3 completion).
6. **Zero Git Modification:** No git commits or pushes were executed (strictly adhered to development rules).

---

### 8. Readiness for Phase 4

With the canonical knowledge base established and verified:
- **Phase 4 (RAG Retrieval Engine):** Can now index these structured `KnowledgeEntry` objects into vector embeddings or dynamic BM25/cosine retrieval pipelines without touching UI or routing logic.
- **Dynamic Grounding:** `CivicAssistantPromptBuilder` will ingest retrieved chunks directly into `AssistantRagContext`.
