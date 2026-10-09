# CivicFix Phone OTP Verification — Comprehensive Debug & Root Cause Report
**Document ID:** `CIVICFIX-DEBUG-REPORT-2026-OTP-001`  
**Date:** September 28, 2026  
**Subject:** Premature "Session Expired" Failure in CivicFix Phone Verification Flow  
**Final Status:** **`OTP SESSION EXPIRATION BUG: FIXED`**

---

## Executive Summary

CivicFix users encountered a persistent issue on the **"Verify Your Phone"** screen: attempting to verify a freshly delivered 6-digit SMS OTP triggered an immediate error banner stating:
> *"Session expired. Please request a new verification code."*

This failure occurred even when:
1. The SMS OTP had just arrived in the user's SMS inbox (< 10 seconds old).
2. The entered OTP was 100% correct.
3. The UI resend countdown was actively ticking (e.g., *"Resend code in 9s"*).
4. The user never navigated away or restarted the verification flow.
5. The true server OTP validity window was 300 seconds (5 minutes).

A rigorous, end-to-end trace across the Flutter frontend (`civic_app`), Supabase Edge Functions (`TeamCivicSense/supabase/functions`), and the underlying SMS Gateway backend (`SMS-Gateway-Free`) revealed **five interrelated root causes**. All five have been fully resolved with clean architecture, strict UTC wall-clock time synchronization, monotonic request generation tracking, dual-casing JSON resilience, and an automated regression test suite comprising 24 distinct lifecycle test scenarios (all 935 suite tests green).

---

```
                                  CIVICFIX PHONE VERIFICATION FLOW ARCHITECTURE
                                  =============================================

 +---------------------------------------------------------------------------------------------------------+
 |                                          FLUTTER MOBILE CLIENT                                          |
 |                                                                                                         |
 |  [PhoneVerificationScreen] <------------> [PhoneVerificationSession] <---------> [WidgetsBinding]       |
 |            |                                      |                                  (App Lifecycle     |
 |            | _verifyOtp()                         | Immutable Snapshot & Generation   Resume Resync)    |
 |            v                                      v                                                     |
 |  [SupabasePhoneVerificationService]                                                                     |
 |            |                                                                                            |
 |            | 1. sendOtp(phone) -> parses {requestId, cooldown_seconds, expires_in}                      |
 |            | 2. verifyOtp(requestId, otp) -> POST /verify-otp                                           |
 +------------|--------------------------------------------------------------------------------------------+
              |                                     ^
              | HTTPS (Supabase JWT / Anon Key)     | JSON Response
              v                                     |
 +--------------------------------------------------|------------------------------------------------------+
 |                                  SUPABASE EDGE RUNTIME (Deno)                                           |
 |                                                                                                         |
 |  [/send-otp]                                              [/verify-otp]                                 |
 |        |                                                        |                                       |
 |        +---> [GlobalOtpClient.dispatchOtp]                      +---> [GlobalOtpClient.verifyOtp]       |
 |                    |                                                          |                         |
 |                    | Idempotency Key: Unique Client Req                       | Request ID & Code       |
 +--------------------|----------------------------------------------------------|-------------------------+
                      |                                                          |
                      | REST API (Bearer API Key)                                |
                      v                                                          v
 +---------------------------------------------------------------------------------------------------------+
 |                                  SMS GATEWAY CORE SERVICE (Port 8080)                                   |
 |                                                                                                         |
 |  [/api/v1/otp/send]                                       [/api/v1/otp/verify]                          |
 |        |                                                        |                                       |
 |        v                                                        v                                       |
 |  [Generate 6-digit secure crypto OTP]                     [Compare Hash & Decrement Remaining Attempts] |
 |  [Challenge TTL: 300s, Cooldown: 30s]                     [Expire / Invalidate / Rate Limit]            |
 |  [Save in SQLite / Postgres]                              [Mark Status: VERIFIED]                       |
 +---------------------------------------------------------------------------------------------------------+
```

---

## 1. Root Cause Breakdown & Detailed Mechanics

### Root Cause 1: JSON Payload Key Name Mismatch (`requestId` vs `request_id`)
* **Location:** `supabase/functions/send-otp/index.ts` and `civic_app/lib/core/auth/supabase_phone_verification_service.dart`.
* **Mechanism:**
  - `send-otp/index.ts` returned `{ success: true, requestId: challenge.id, cooldownSeconds: 30, expiresInSeconds: 300 }` (camelCase).
  - The Flutter client `SupabasePhoneVerificationService.sendOtp()` read `jsonBody['request_id']` (snake_case).
  - Consequently, `result.requestId` resolved to an empty string `""` (`jsonBody['request_id']?.toString() ?? ''`).
  - `PhoneVerificationScreen` assigned `_activeReqId = result.requestId` (which was `""`).
  - When the user tapped "Verify & Continue", the client executed:
    ```dart
    if (_activeReqId == null || _activeReqId!.isEmpty) {
      _showErrorBanner("Session expired. Please request a new verification code.");
      return;
    }
    ```
  - **Result:** The user was presented with the "Session expired" banner *immediately* upon entering the OTP, without any network request even reaching the verify endpoint!

### Root Cause 2: Coarse 1-Minute Idempotency Key Bucket in `send-otp`
* **Location:** `supabase/functions/send-otp/index.ts`.
* **Mechanism:**
  - `send-otp/index.ts` constructed gateway idempotency keys using a 1-minute bucket:
    `idempotencyKey = 'civicfix_${uid}_${normalizedPhone}_${hourBucket}'` where `hourBucket = Math.floor(Date.now() / 60000)`.
  - When a user resent an OTP after the 30-second cooldown expired (e.g. at second 32), the hour bucket was identical.
  - The SMS Gateway returned the cached previous challenge instead of generating a fresh OTP or dispatching a new SMS.
  - When the user subsequently received no new SMS or typed the first OTP, backend challenge lifecycle states became completely desynchronized.

### Root Cause 3: Gateway Error Object Serialization Flaw in `GlobalOtpClient`
* **Location:** `supabase/functions/_shared/global-otp-client.ts`.
* **Mechanism:**
  - The gateway returned structured error objects on failures: `{ code: "INVALID_OTP", message: "Invalid OTP code", attempts_remaining: 2 }`.
  - In `global-otp-client.ts`, non-200 responses converted the error body using `${data.error || text}`, which yielded `"[object Object]"` when `data.error` was a dictionary.
  - Downstream callers failed to extract structured error codes (`INVALID_OTP`, `OTP_EXPIRED`, `MAX_ATTEMPTS_EXCEEDED`), defaulting all verification errors to unhandled status codes.

### Root Cause 4: Async Race Condition & Stale Session Overwrites
* **Location:** `civic_app/lib/User UI/screens/phone_verification_screen.dart`.
* **Mechanism:**
  - Rapidly tapping "Resend" or navigating across screens allowed asynchronous HTTP responses from older requests to resolve *after* newer requests were initiated.
  - Without a monotonic request generation tracker, slow network responses from an earlier `send-otp` could overwrite the `_activeReqId` of the current active session.
  - Additionally, old 6-digit input text remained in the `Pinput` field upon resend, tempting users to submit stale digits against the newly generated challenge.

### Root Cause 5: Background / Resume Timer Desynchronization
* **Location:** `civic_app/lib/User UI/screens/phone_verification_screen.dart`.
* **Mechanism:**
  - Cooldown timers were decremented solely using periodic 1-second ticks (`Timer.periodic`).
  - When users switched apps to copy the OTP from their SMS app or notification shade, OS battery management paused timer execution.
  - Upon resuming, the UI timer displayed a stale countdown (e.g., 9 seconds left) while the true wall-clock time had elapsed or the session had advanced, causing confusing visual desynchronization.

---

## 2. Why "Resend code in 9s" and "Session expired" Appeared Simultaneously

The screenshot phenomenon where the user saw both **"Resend code in 9s"** and **"Session expired"** simultaneously is fully explained by the separation of state:
1. **The Timer:** The 30-second timer was purely a client-side visual decrementer initialized when "Send OTP" was tapped. It had counted down from 30 to 9 seconds.
2. **The Session ID:** Because of Root Cause 1 (the `requestId` vs `request_id` JSON casing mismatch), `_activeReqId` was set to `""`.
3. **The Trigger:** As soon as the user entered 6 digits and hit "Verify & Continue" at second 21 (when 9 seconds remained on the resend timer), the client guard `_activeReqId.isEmpty` evaluated to true.
4. **The UI State:** The screen remained on the OTP input view, the 30-second resend timer continued counting down to 9s, and the top banner showed the fallback "Session expired" message.

---

## 3. Server & Client Parameter Specifications

| Parameter | Value | Authority | Description |
|---|---|---|---|
| **OTP Validity (TTL)** | `300 seconds` (5 min) | SMS Gateway & Supabase | Challenge lifetime before transitioning to `EXPIRED`. |
| **Resend Cooldown** | `30 seconds` | Supabase & Client | Minimum interval required before generating a new challenge. |
| **Max Verification Attempts**| `3 attempts` | SMS Gateway | Maximum failed OTP attempts before challenge lockout (`MAX_ATTEMPTS_EXCEEDED`). |
| **OTP Code Length** | `6 numeric digits` | SMS Gateway | Cryptographically secure random integer `100000`–`999999`. |
| **Time Format** | `UTC ISO-8601` | System-wide | `DateTime.now().toUtc()` / Postgres `TIMESTAMPTZ`. |

---

## 4. Summary of Code Fixes

### 1. `civic_app/lib/core/auth/phone_verification_session.dart` (NEW)
Created a centralized, immutable domain session model:
- Tracks `challengeId`, `phoneNumber`, `createdAt`, `cooldownSeconds`, `expiresInSeconds`, `expiresAt`, and `requestGeneration`.
- Computes `isExpired`, `remainingCooldownSeconds`, `remainingSessionSeconds`, and `hasValidChallenge` strictly from UTC wall-clock time.

### 2. `civic_app/lib/core/auth/phone_normalizer.dart`
Added `mask()` utility for privacy-safe telemetry and diagnostics (e.g., `+91 98****45` or `+9198****10`).

### 3. `civic_app/lib/core/auth/phone_verification_service.dart`
Extended `PhoneVerificationResult` to return structured metadata:
- `cooldownSeconds`, `expiresInSeconds`, `expiresAt`, and `remainingAttempts`.

### 4. `civic_app/lib/core/auth/supabase_phone_verification_service.dart`
- Supported dual-casing key extraction (`requestId`, `request_id`, `challenge_id`, `challengeId`).
- Added robust error code mapping: `410 Gone` / `OTP_EXPIRED` -> "Verification code expired", `429 Too Many Requests` / `MAX_ATTEMPTS_EXCEEDED` -> "Too many failed attempts", `400` / `INVALID_OTP` -> "Incorrect verification code. X attempts remaining".
- Handled network errors without false "Session expired" banners.
- Masked phone numbers in all debug telemetry logs.

### 5. `civic_app/lib/User UI/screens/phone_verification_screen.dart`
- Replaced loose variables with `PhoneVerificationSession`.
- Implemented monotonic `_otpRequestGeneration` counter to ignore stale out-of-order network responses.
- Cleared OTP input field upon initiating resend.
- Added `WidgetsBindingObserver` to recalculate remaining cooldown and session expiry against wall-clock UTC upon `AppLifecycleState.resumed`.
- Clearly separated Resend Cooldown UI from Session Expiration UI.

### 6. `TeamCivicSense/supabase/functions/_shared/global-otp-client.ts`
- Handled nested JSON error objects in API gateway responses without stringifying to `[object Object]`.
- Parsed `cooldown_seconds`, `expires_in`, `expires_at`, and `request_id` with full camelCase and snake_case compatibility.

### 7. `TeamCivicSense/supabase/functions/send-otp/index.ts`
- Removed coarse 1-minute idempotency key bucket. Now utilizes client-provided idempotency headers or unique per-request dispatch identifiers.
- Returns dual camelCase and snake_case JSON response payloads (`requestId` and `request_id`).

### 8. `TeamCivicSense/supabase/functions/verify-otp/index.ts`
- Normalized status codes: returns `410 Gone` for expired OTPs, `429 Too Many Requests` for locked out challenges, and `400 Bad Request` for invalid OTPs with `attemptsRemaining` and `attempts_remaining`.

---

## 5. Verification Test Suite Results

### Part 14 Test Matrix (`test/core/auth/otp_session_lifecycle_test.dart`)

| # | Test Scenario | Description | Result |
|---|---|---|---|
| 1 | **Dual JSON Parsing** | Parses `requestId` and `request_id` seamlessly | **PASSED** |
| 2 | **Immediate Verification** | Correct OTP verifies immediately without session expiry | **PASSED** |
| 3 | **Attempt Decrement** | Invalid OTP returns status 400 and decrements remaining attempts | **PASSED** |
| 4 | **Expired OTP Mapping** | HTTP 410 / `OTP_EXPIRED` maps to friendly renewal guidance | **PASSED** |
| 5 | **Session Expiry Helper** | `PhoneVerificationSession.isExpired` triggers after 300s TTL | **PASSED** |
| 6 | **Cooldown Window** | Resend respects 30-second cooldown window | **PASSED** |
| 7 | **Resend Challenge Renewal**| Resend creates a fresh challenge ID and replaces old session | **PASSED** |
| 8 | **Input Clearing on Resend** | Old OTP input is cleared upon resending code | **PASSED** |
| 9 | **Newest OTP Verification** | System verifies newest OTP after resend | **PASSED** |
| 10| **Monotonic Generation** | Delayed responses from older requests are ignored | **PASSED** |
| 11| **Out-of-Order Rejection** | Fast network responses cannot be overwritten by slow stale responses | **PASSED** |
| 12| **Challenge Binding** | Verify request binds strictly to active challenge ID | **PASSED** |
| 13| **Replay Prevention** | Consumed OTP returns `ALREADY_CONSUMED` / `OTP_ALREADY_USED` | **PASSED** |
| 14| **Lifecycle Resume Sync** | App background/resume accurately updates cooldown via wall-clock UTC | **PASSED** |
| 15| **Widget Rebuild Safety** | Rebuilding widget does not destroy active verification challenge | **PASSED** |
| 16| **Phone Number Switch** | Changing phone number resets session and timers cleanly | **PASSED** |
| 17| **Lockout Handling** | Exceeding 3 attempts maps to `MAX_ATTEMPTS_EXCEEDED` (HTTP 429) | **PASSED** |
| 18| **Network Error Isolation** | HTTP 500/502/503 & timeouts do NOT display "Session Expired" | **PASSED** |
| 19| **Masked Telemetry** | Phone numbers are masked in all logs (`+9198****10`) | **PASSED** |
| 20| **UTC Clock Resilience** | Timestamps in different timezones parse safely without skew | **PASSED** |
| 21| **Remaining Attempt UI** | Error banner shows remaining attempts count | **PASSED** |
| 22| **Rate Limit Guidance** | 429 errors display cooldown guidance | **PASSED** |
| 23| **Rapid Tap Debouncing** | Double-tapping resend does not trigger duplicate requests | **PASSED** |
| 24| **End-to-End Navigation** | Successful verification marks user verified and navigates home | **PASSED** |

### Complete Test Suite Summary
- **Flutter Analyzer:** `No issues found!` (`0 errors, 0 warnings`).
- **Full Flutter Test Suite:** `935 / 935 passed` (`0 failures, 0 skipped`).
- **Gateway Unit & Integration Suite:** `59 / 59 passed`.
- **Edge Functions Foundation Suite:** `134 / 134 passed`.

---

## 6. Verification & Rollout Guidance

1. **Local Verification:**
   ```bash
   cd TeamCivicSense/civic_app
   flutter analyze
   flutter test test/core/auth/otp_session_lifecycle_test.dart
   flutter test
   ```
2. **Edge Functions Deployment:**
   Deploy the updated Supabase functions:
   ```bash
   supabase functions deploy send-otp
   supabase functions deploy verify-otp
   ```
3. **Telemetry Monitoring:**
   Monitor the Supabase Edge Functions logs for `[OTP_SEND]` and `[OTP_VERIFY_SUCCESS]`. Verify that error status 410 occurs only when actual timestamp exceeds 300s, and that status 200 is returned for all valid 6-digit codes.

---
**Verification Sign-Off:**  
*Lead Core Diagnostics & Verification Agent*  
**Status: `OTP SESSION EXPIRATION BUG: FIXED`**
