# CivicFix — Multilingual Architecture Specification (Phases 1–8 Production Ready)

## Executive Summary
This document establishes the official and complete production multilingual architecture for the CivicFix municipal platform (supporting **English (`en`)**, **Hindi (`hi`)**, and **Marathi (`mr`)**).

The architecture spans static UI localization, canonical backend value mappers, server-side dynamic machine translation with Google Gemini, two-level persistent caching, source-hash invalidation, request coalescing, a locale-aware municipal AI chatbot, localized notifications, TTS voice readiness, and zero-mutation historical data compatibility.

---

## 1. The Three Architectural Pillars of Localization

CivicFix strictly separates localization concerns into three decoupled paths that never blend or mutate underlying database schemas:

```text
                    CIVICFIX LOCALE
                         │
              ┌──────────┼──────────┐
              │          │          │
             en         hi         mr
              │          │          │
              └──────────┼──────────┘
                         ↓
                 Flutter gen_l10n
                         │
          ┌──────────────┼──────────────┐
          ↓              ↓              ↓
      Static UI      Canonical IDs   User Text
          │              │              │
         ARB           Mapper            ↓
                                  TranslationRepository
                                           │
                           ┌───────────────┼───────────────┐
                           ↓               ↓               ↓
                        L1 Cache        L2 Cache       Cloud Function
                                                           ↓
                                                        Gemini
                                                           ↓
                                                  Derived Translation
                                                           │
                                                           ↓
                                              CivicFixTranslatedText
                                                           │
                                         ┌─────────────────┴──────────────┐
                                         ↓                                ↓
                                    Translation                     View Original
```

1. **Static UI Layer**:
   * Pre-compiled type-safe string resources in `lib/l10n/app_en.arb`, `app_hi.arb`, and `app_mr.arb`.
   * Covers all citizen and government screens, dialogs, form validation errors, navigation, and badges.

2. **Canonical Backend Values / Enums / Roles / Statuses**:
   * Stored in Firestore as immutable ASCII tokens (`inProgress`, `department_crew`, `roads`, `underVerification`).
   * Rendered on screen through centralized, pure in-memory display mappers (`lib/core/localization/mappers/canonical_display_mappers.dart`).
   * Zero localized strings are ever persisted to canonical Firestore document fields.

3. **User-Generated & Dynamic Content Layer**:
   * Authoritative original user/officer text (`title`, `description`, `citizenRemarks`, `officerNotes`, `resolutionRemarks`, `reworkReason`) remains 100% immutable in Firestore.
   * Translations exist exclusively as derived, ephemeral presentation data in `TranslatableContent` and `TwoLevelTranslationCache`.
   * Reusable component `CivicFixTranslatedText` provides the bidirectional *"Translated from [Language] | View original"* and *"Original — [Language] | View translation"* experience.

---

## 2. Production Translation Infrastructure & Security

### Backend Cloud Function (`translateUserContent`)
* **Endpoint**: Firebase Cloud Functions (`functions/src/translation.ts`, `functions/src/index.ts`).
* **Zero Client Secret Exposure**: Flutter client code contains zero Gemini API keys, Service Account credentials, or AI tokens.
* **Strict Allowlist**: Server-side validation restricts translation strictly to `{'en', 'hi', 'mr'}`.
* **Municipal Glossary**: Canonical BMC glossary (`CIVIC_GLOSSARY`) is injected into system prompts to ensure faithful municipal translation across English, Hindi, and Marathi.
* **Pluggable Provider Architecture**: Communicates via `RemoteTranslationService` with standard callable contracts, enabling seamless future migration to IndicTrans2 or private Indic models.

---

## 3. Two-Level Persistent Caching & Invalidation

* **L1 Cache** (`MemoryTranslationCache`): Fast in-memory session cache with LRU eviction (default capacity: 500 entries).
* **L2 Cache** (`PersistentTranslationCache`): Durable, multi-session persistent store with SHA-256 source hashing and version isolation.
* **Two-Level Lifecycle** (`TwoLevelTranslationCache`):
  1. Check L1. On hit $\rightarrow$ return immediately.
  2. On L1 miss $\rightarrow$ check L2.
  3. On L2 hit $\rightarrow$ backfill L1 and return.
  4. On L2 miss $\rightarrow$ invoke remote Cloud Function $\rightarrow$ populate both L1 and L2 simultaneously.
* **Source-Hash Invalidation**:
  $$\text{sourceHash} = \text{SHA-256}(\text{trim}(text))$$
  If source text is edited by an author, the hash changes, automatically invalidating stale translations.
* **Privacy-Conscious Cache Keys**:
  $$\text{cacheKey} = \text{SHA-256}(\text{contentType} : \text{sourceHash} : \text{sourceLanguage} : \text{targetLanguage} : \text{v}N)$$
* **Request Deduplication**: `DefaultTranslationRepository` coalesces concurrent identical translation requests into a single in-flight `Future`.

---

## 4. Historical Data Compatibility & Migration Policy

1. **Zero Destructive Migration**:
   * Never overwrites or rewrites legacy complaint records.
   * Historical complaints lacking language metadata are evaluated on-demand when viewed in an alternate locale.
2. **Historical Source-Language Resolution Priority**:
   1. Explicit trusted source-language metadata $\rightarrow$ use it.
   2. Cached detection result (for identical `sourceHash`) $\rightarrow$ reuse it.
   3. `LanguageDetector.detect(text)` $\rightarrow$ evaluate Latin/Devanagari scripts and municipal keyword dictionaries.
   4. Confident `en` / `hi` / `mr` $\rightarrow$ use detected language code.
   5. Uncertain / ambiguous / alphanumeric codes $\rightarrow$ preserve original, fallback safely to avoid forced/hallucinated translation.
3. **Migration Utility** (`HistoricalMigrationUtility`):
   * Dry-run capability (`runAuditDryRun`) scans legacy complaints, classifies into Categories A through E, and guarantees `recordsModified == 0`.
   * Optional controlled warm-up (`warmUpActiveComplaints`) pre-caches active/high-priority complaints without broad sweeps.

---

## 5. Locale-Aware AI Assistant & Chatbot

* **Service**: `CivicAssistantService` dynamically generates strict municipal system prompts (`generateLanguageSystemPrompt`) mandating responses in the active UI locale (`en`, `hi`, `mr`).
* **Cross-Language Resolution**: If a citizen queries in English while Marathi UI is active, the assistant responds in Marathi using approved civic terminology.
* **Chat History Immutability**: Historical user queries and past replies maintain their verbatim text and are never mutated retroactively upon language switching.

---

## 6. Notification & TTS Architecture

* **Notifications** (`NotificationLanguageTemplates`): Localizes 9 canonical notification event types (`complaintRegistered`, `complaintVerified`, `officerAssigned`, `workInProgress`, `complaintResolved`, `reworkRequested`, `slaBreached`, `pointsAwarded`, `emergencyAlert`) across `en`, `hi`, and `mr` with recipient locale fallback.
* **TTS Speech Synthesis** (`TtsLanguageConfig`):
  * Maps language codes to BCP-47 voice tags (`en` $\rightarrow$ `en-IN`, `hi` $\rightarrow$ `hi-IN`, `mr` $\rightarrow$ `mr-IN`).
  * Enforces the visible text reading rule: Reads translated text when translated view is active; reads verbatim original text when "View Original" is toggled.

---

## 7. Feature Flags & Rollback Strategy

* **Kill-Switch**: `TranslationConstants.dynamicTranslationEnabled` (default: `true`).
  * If disabled during provider outages or cost spikes, static UI remains 100% localized, while user-generated free text safely displays its authoritative original content.
* **Translation Versioning**: `TranslationConstants.currentTranslationVersion` (centralized integer, default: `1`).
  * Incrementing version isolates cache namespaces cleanly without requiring manual cache wipes.
* **Outage Resilience**: Bounded timeouts (default: 10s), HTTP/503 exception fallbacks, and storage failure handlers ensure that complaints and government workflows are never blocked.

---

## 8. Final Verification & Quality Assurance Baseline

* `flutter analyze`: **0 issues** across all Flutter packages and tests.
* `npm test` (Functions): **20 tests passed (100%)** across 9 test suites.
* `flutter test test/core/localization/`: **203 tests passed (100%)**.
* `flutter build web --no-tree-shake-icons`: **Exit code 0 (Production build ready)**.
