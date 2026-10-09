# CivicFix Chatbot Rollout — Phase 5: Live App Context, Complaint-Aware Responses & Safe Personalization

**Date:** October 8, 2026  
**Status:** Completed & Fully Verified  
**Static Analysis:** 0 issues found (`flutter analyze`)  
**Test Suite:** 73/73 tests passing (`flutter test test/core/assistant/`)  

---

## 1. Executive Summary

Phase 5 successfully upgrades the CivicFix citizen assistant with **safe, real-time application context** and **complaint-aware intelligence**. The assistant can now seamlessly understand what screen the user is viewing, what complaint is currently active, what stage of the 5-stage lifecycle it is in, whether technical staff have been assigned, whether field repairs are blocked or undergoing rework, and whether a grievance is waiting in the local offline queue.

All context integration adheres to strict **zero-PII privacy boundaries**, **read-only safety invariants**, **hybrid RAG grounding**, and **zero regression** on general CivicFix questions and casual conversation.

```
+---------------------------------------------------------------------------------------------------+
|                                  CIVICFIX ASSISTANT PIPELINE                                     |
+---------------------------------------------------------------------------------------------------+
|  [Citizen UI / Screen Context]  ──>  [ComplaintToAssistantContextMapper]                         |
|                                                  │                                                |
|                                                  ▼                                                |
|                                       [AssistantAppContext]                                       |
|                                       (Sanitized, Zero-PII)                                       |
|                                                  │                                                |
|  [User Query] ───────────────┬───────────────────┴───────────────────┬─────────────────────────── |
|                              │                                       │                            |
|                              ▼                                       ▼                            |
|                  [Semantic Intent Router]               [Hybrid RAG Retriever]                    |
|                              │                                       │                            |
|                              ▼                                       ▼                            |
|               [CivicAssistantConversationEngine] <────── [Relevant Knowledge Chunks]              |
|                              │                                                                    |
|                              ▼                                                                    |
|               [Safe, Grounded, Contextual Response]                                               |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Safe App Context Architecture & Data Schema

The `AssistantAppContext` model (`lib/core/assistant/models/assistant_app_context.dart`) defines a strictly controlled, typed context container.

### A. Context Field Schema

| Field Name | Type | Purpose | Privacy Classification |
|---|---|---|---|
| `userRole` | `String?` | Role identifier (e.g. `'citizen'`, `'ward_department_lead'`) | Public Role Token |
| `currentScreen` | `String?` | Active screen ID (`'complaintDetails'`, `'reportIssue'`, `'map'`) | Transient UI State |
| `reportStep` | `int?` | Active step in Report Issue flow (1 to 4) | Transient UI State |
| `selectedMapFeatureType` | `String?` | Map filter layer (`'potholes'`, `'garbage'`, `'water'`) | Transient UI State |
| `selectedComplaintId` | `String?` | Firestore Document ID | Internal Reference |
| `selectedTicketNumber` | `String?` | Canonical Citizen Ticket ID (`'MCGM-2026-0891'`) | Safe Reference |
| `complaintStatus` | `String?` | Canonical Lifecycle Status (`'underVerification'`, `'assigned'`, `'inProgress'`, `'resolved'`, `'closed'`) | Municipal Workflow State |
| `complaintCategory` | `String?` | Grievance Category (`'Pothole'`, `'Garbage Dump'`, `'Water Leakage'`) | Grievance Classification |
| `wardId` | `String?` | Canonical BMC Ward (`'K/West'`, `'G/North'`, `'A'`) | Geographic Jurisdiction |
| `departmentId` | `String?` | Canonical BMC Department (`'maintenance_roads'`, `'water_works'`) | Responsible Department |
| `verificationStage` | `int?` | Automated Verification Progress Stage (1 or 2) | Quality Pipeline State |
| `hasJuniorEngineerAssigned` | `bool` | Boolean flag for Junior Engineer technical ownership | Operational Flag |
| `assignedJuniorEngineerName` | `String?` | Public name snapshot from complaint model | Public Government Name |
| `hasFieldOfficerAssigned` | `bool` | Boolean flag for on-ground Field Officer allocation | Operational Flag |
| `assignedFieldOfficerName` | `String?` | Public name snapshot from complaint model | Public Government Name |
| `isBlocked` | `bool` | On-ground obstacle flag | Operational Flag |
| `blockedReason` | `String?` | Obstacle reason description (`'Heavy waterlogging'`) | Operational Metadata |
| `reopenCount` | `int` | Number of times complaint was sent for rework | Supervisory Audit Count |
| `reopenReason` | `String?` | Supervisory audit rework remarks | Quality Audit Remarks |
| `syncState` | `String?` | Offline synchronization state (`'synced'`, `'pending'`, `'failed'`) | Device Offline State |

---

## 3. Strict Zero-PII & Privacy Protection Invariants

The assistant context architecture enforces strict data isolation:

```
[STRICT ZERO-PII ISOLATION MATRIX]
+------------------------------------+------------------------------------+
|        PROHIBITED DATA (BLOCKED)   |        SAFE CONTEXT (ALLOWED)      |
+------------------------------------+------------------------------------+
| Citizen Phone Numbers              | Canonical Ticket Number            |
| Citizen Email Addresses            | Grievance Category & Ward ID       |
| Firebase User UIDs                 | Responsible Municipal Department   |
| Citizen Home / Physical Addresses  | Normalized Status Code             |
| Civil Servant Phone / Credentials  | Public Officer Display Names       |
| Authentication Tokens & OTPs       | Obstacle Reason (Ground Context)   |
| Private Evidence Storage URLs      | Supervisory Rework Remarks         |
| Direct Firestore Write Methods     | Offline Sync Pending State         |
+------------------------------------+------------------------------------+
```

### Safety Rules Enforced:
1. **Read-Only Invariant:** The assistant is strictly conversational and informational. It cannot trigger status transitions, assign personnel, approve evidence, or delete records.
2. **Zero In-Chat PII Echoing:** The model never asks for or repeats phone numbers, OTPs, or private contact info.
3. **Safe Fallback on Missing Context:** If the citizen opens the chat outside a complaint context, the assistant automatically falls back to canonical domain knowledge without failing.

---

## 4. In-Memory State Mapping (`ComplaintToAssistantContextMapper`)

To ensure optimal performance and eliminate redundant Firestore read costs, `ComplaintToAssistantContextMapper` (`lib/core/assistant/adapters/complaint_context_mapper.dart`) maps existing in-memory `ComplaintModel` instances:

- **Ward Sanitization:** Strips prefixes to yield canonical ward names (`'Ward K/West'` -> `'K/West'`).
- **Category Normalization:** Translates internal IDs to human-readable strings (`'potholes'` -> `'Pothole'`).
- **Department Normalization:** Maps category codes to official BMC department names (`'maintenance_roads'` -> `'Maintenance & Roads'`).
- **Government Snapshots:** Extracts display names from immutable complaint snapshots (`assignedJuniorEngineerNameSnapshot`, `assignedFieldOfficerNameSnapshot`).
- **Zero Firestore Read Latency:** Pure functional in-memory transformation (0ms network overhead).

---

## 5. RAG Hybrid Retriever Context Expansion

The Phase 4 `CivicAssistantHybridRetriever` was upgraded to accept `AssistantAppContext`:

- **Context-Aware Query Expansion:** Extracts active status, ward, department, category, and obstacle tokens from `AssistantAppContext`.
- **Scoring Boosts:** Injects a **+30.0 relevance boost** for knowledge entries matching the active complaint state (e.g. boosting `status_under_verification` when the active complaint is in Stage 2).
- **Casual Bypass Preservation:** Unaffected by context; greetings and small talk continue to bypass RAG with 0ms overhead.

---

## 6. Conversational Handling & Lifecycle State Matrix

The `CivicAssistantConversationEngine` resolves context-aware queries accurately across the entire complaint lifecycle:

| Complaint State | Citizen Query | Assistant Response Strategy | Verified Output Highlight |
|---|---|---|---|
| **Under Verification** (Stage 2) | *"What is happening with my complaint?"* | Explains Stage 2 automated photo authenticity and department verification. | Identifies ticket ID & Stage 2 verification pipeline. |
| **Under Verification** (Stage 2) | *"What happens next?"* | Explains that after verification, it will route to the Junior Engineer for the specific Ward & Dept. | Explains transition from Stage 2 to Stage 3. |
| **Assigned** (Stage 3) | *"Has work started on my complaint?"* | Clarifies that Junior Engineer is assigned as Technical Owner, but field work starts in Stage 4. | Distinguishes technical assignment from physical work start. |
| **In Progress** (Stage 4) | *"Has work started?"* | Confirms field squad is actively on site executing repairs. | Confirms Stage 4 active repair. |
| **Blocked Obstacle** | *"Why is work blocked?"* | Explains the specific obstacle reason logged by the field crew and confirms SLA is preserved. | Mentions logged obstacle reason & SLA preservation. |
| **Resolved** (Stage 5) | *"Is my complaint finished?"* | Clarifies status is Resolved with photo proof, awaiting Ward Lead supervisory review before Closed. | Distinguishes Resolved (Stage 5) from Closed. |
| **Reopened Rework** | *"Why was my complaint reopened?"* | Explains supervisory quality audit by Ward Lead, cites rework reason, and confirms SLA is preserved. | Mentions quality audit & continuous SLA. |
| **Offline Pending** | *"Why can't I track my complaint yet?"* | Explains local offline storage queue and automatic sync upon internet reconnect. | Clarifies offline queue & sync restoration. |
| **Report Screen** | *"What do I do here?"* | Breaks down the 4-step reporting flow (Info -> Evidence -> Location -> Submit). | 4-step guided walkthrough. |
| **State Contradiction** | *"Why is my ticket closed?"* (when active) | Corrects misconception; states the complaint is actively being processed in its real stage. | Contradiction guard protects citizen peace of mind. |

---

## 7. Evaluation Dataset & Benchmark Results

The Phase 5 test suite (`test/core/assistant/civic_assistant_app_context_test.dart`) thoroughly verifies all requirements across **8 distinct test sections** and **21 test scenarios**:

```
00:00 +0: Group: CivicFix Chatbot Phase 5 — Live App Context & Complaint Awareness
00:00 +1: Section 1: Context Mapping & PII Scrubbing - Maps ComplaintModel to AssistantAppContext with strict zero-PII
00:00 +2: Section 1: Context Mapping & PII Scrubbing - Formats prompt context string cleanly with read-only instructions
00:00 +3: Section 2: Under Verification Context - "What is happening with my complaint?" explains Under Verification stage
00:00 +4: Section 2: Under Verification Context - "What happens next?" explains routing to Junior Engineer for specific Ward/Dept
00:00 +5: Section 2: Under Verification Context - "Has work started?" clarifies work has not started yet during verification
00:00 +6: Section 3: Assigned & In Progress Context - "Has work started?" distinguishes Assigned from In Progress
00:00 +7: Section 3: Assigned & In Progress Context - "Who is assigned?" identifies both Junior Engineer and Field Officer
00:00 +8: Section 3: Assigned & In Progress Context - "What is happening?" describes active field repair during In Progress
00:00 +9: Section 4: Blocked, Resolved, Rework & Offline Context - "Why is work blocked?" explains obstacle reason and SLA preservation
00:00 +10: Section 4: Blocked, Resolved, Rework & Offline Context - "Is my complaint finished?" explains Resolved vs Closed distinction
00:00 +11: Section 4: Blocked, Resolved, Rework & Offline Context - "Why was my complaint reopened?" explains supervisory audit and SLA
00:00 +12: Section 4: Blocked, Resolved, Rework & Offline Context - "Why can't I track my complaint yet?" explains offline pending sync
00:00 +13: Section 5: Screen Context & Contradiction Protection - "What do I do here?" on reportIssue screen provides 4-step guidance
00:00 +14: Section 5: Screen Context & Contradiction Protection - "How does this screen work?" on map screen explains hazard map
00:00 +15: Section 5: Screen Context & Contradiction Protection - State contradiction guard clarifies complaint is NOT closed
00:00 +16: Section 6: Casual Conversation & General Knowledge Bypass - Casual greeting "Hello" remains natural and does NOT leak complaint context
00:00 +17: Section 6: Casual Conversation & General Knowledge Bypass - Out-of-scope "Tell me a joke" works naturally without context pollution
00:00 +18: Section 6: Casual Conversation & General Knowledge Bypass - General query "What is a Junior Engineer?" retrieves general role knowledge
00:00 +19: Section 7: RAG Hybrid Retriever Context Hints - App context tokens boost relevant knowledge retrieval
00:00 +20: Section 8: Controller Freshness & Context Mutation - Controller receives, updates, and clears complaint context cleanly
00:00 +21: Section 8: Controller Freshness & Context Mutation - Provider responds with live context when controller receives query
```

### Complete Test Suite Summary

| Test Suite File | Tests | Pass Rate | Execution Time |
|---|---|---|---|
| `civic_assistant_app_context_test.dart` | 21 | 100% | 0.4s |
| `civic_assistant_rag_retriever_test.dart` | 22 | 100% | 0.5s |
| `civic_assistant_foundation_test.dart` | 15 | 100% | 0.3s |
| `civic_assistant_knowledge_test.dart` | 12 | 100% | 0.2s |
| `assistant_screen_widget_test.dart` | 3 | 100% | 0.3s |
| **Total Full Suite** | **73** | **100% (73/73 Passed)** | **1.7s** |

---

## 8. Final Verdict & Deliverables Checklist

- [x] **Safe App Context Model:** Strongly typed `AssistantAppContext` implemented with complete field coverage.
- [x] **Strict Privacy / Zero-PII:** Verified zero phone numbers, emails, passwords, UIDs, or private URLs in context.
- [x] **Read-Only Invariant:** Chatbot has zero ability to execute mutations or state changes in Firestore.
- [x] **In-Memory Mapping:** `ComplaintToAssistantContextMapper` converts active complaints with 0ms network latency.
- [x] **Context-Aware Lifecycle Routing:** Accurate responses for Under Verification, Assigned, In Progress, Blocked, Resolved, Rework, and Offline states.
- [x] **State Contradiction Guard:** Active complaints safely refute citizen misconceptions regarding closed tickets.
- [x] **Casual Bypass Integrity:** Zero regressions on greetings, small talk, and general knowledge.
- [x] **Documentation Updated:** `Brain.md` and `TeamCivicSense/Brain.md` updated with Section 13.
- [x] **Static Analysis:** `flutter analyze` verified with **0 issues found**.
- [x] **Non-Commit / Non-Push Compliance:** All changes maintained locally without committing or pushing.
