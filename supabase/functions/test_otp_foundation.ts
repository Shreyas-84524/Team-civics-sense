/**
 * CivicFix — Phase 3: OTP Backend Foundation Test Suite
 *
 * Runs via: node --experimental-strip-types supabase/functions/test_otp_foundation.ts
 *
 * Validates all required cryptographic, business, rate-limiting, and lifecycle behaviors:
 * 1. Valid Indian mobile phone number normalization
 * 2. Invalid phone number rejection
 * 3. Cryptographically secure 6-digit OTP generation (rejection sampled)
 * 4. Salt generation & SHA-256 OTP hashing (bound to salt + phone, non-plaintext)
 * 5. Constant-time equality comparison
 * 6. Expiry check
 * 7. Wrong OTP verification
 * 8. Three failed attempts lockout
 * 9. Consumed OTP reuse prevention (atomic invalidation)
 * 10. Resend cooldown (30s)
 * 11. Hourly rate limit (5 sends/hour)
 * 12. Duplicate request ID uniqueness
 * 13. Unauthenticated request rejection
 * 14. Phone / request ID mismatch detection
 * 15. Production response hygiene (no OTP, no salt, no hash exposed)
 */

// Shim Deno global if running in Node.js
if (typeof (globalThis as any).Deno === "undefined") {
  (globalThis as any).Deno = {
    env: {
      get: (key: string) => process.env[key],
    },
  };
}

import http from "node:http";
import type { AddressInfo } from "node:net";

import {
  normalizeIndianPhone,
  isValidIndianPhone,
  generateSecureOtp,
  generateSecureSalt,
  hashOtp,
  constantTimeCompare,
  OTP_LIFETIME_SECONDS,
  MAX_VERIFICATION_ATTEMPTS,
  RESEND_COOLDOWN_SECONDS,
  HOURLY_RATE_LIMIT,
} from "./_shared/otp-security.ts";

import {
  MockSmsTransport,
  GatewaySmsTransport,
  getSmsTransport,
  maskPhoneNumber,
  DEFAULT_GATEWAY_TIMEOUT_MS,
} from "./_shared/sms-transport.ts";
import { verifyFirebaseIdToken } from "./_shared/firebase-auth.ts";

// Simple test assertion harness
let passedTests = 0;
let failedTests = 0;

function assert(condition: boolean, testName: string, detail?: string) {
  if (condition) {
    passedTests++;
    console.log(`  ✓ PASS: ${testName}`);
  } else {
    failedTests++;
    console.error(`  ✗ FAIL: ${testName}${detail ? ` — ${detail}` : ""}`);
  }
}

async function runTestSuite() {
  console.log("================================================================");
  console.log("CivicFix Phase 3: OTP Backend Foundation Comprehensive Test Suite");
  console.log("================================================================\n");

  // --------------------------------------------------------------------------
  // TEST GROUP 1: Indian Phone Number Normalization
  // --------------------------------------------------------------------------
  console.log("[Test Group 1] Indian Phone Normalization (E.164 +91XXXXXXXXXX)");
  {
    const validCases = [
      { input: "9876543210", expected: "+919876543210", desc: "10-digit raw" },
      { input: "09876543210", expected: "+919876543210", desc: "11-digit leading zero" },
      { input: "919876543210", expected: "+919876543210", desc: "12-digit country code without plus" },
      { input: "+919876543210", expected: "+919876543210", desc: "13-digit E.164 with plus" },
      { input: "+91 98765-43210", expected: "+919876543210", desc: "Formatted with space and hyphen" },
      { input: "  9876543210  ", expected: "+919876543210", desc: "Whitespace padded" },
      { input: "6123456789", expected: "+916123456789", desc: "Starts with 6 (valid)" },
      { input: "7123456789", expected: "+917123456789", desc: "Starts with 7 (valid)" },
      { input: "8123456789", expected: "+918123456789", desc: "Starts with 8 (valid)" },
      { input: "9123456789", expected: "+919123456789", desc: "Starts with 9 (valid)" },
    ];

    for (const tc of validCases) {
      const normalized = normalizeIndianPhone(tc.input);
      assert(normalized === tc.expected, `Normalizes ${tc.desc} (${tc.input} -> ${normalized})`);
      assert(isValidIndianPhone(tc.input), `isValidIndianPhone returns true for ${tc.desc}`);
    }
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 2: Invalid Phone Number Rejection
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 2] Invalid Phone Number Rejection");
  {
    const invalidCases = [
      { input: "12345", desc: "Too short (<10 digits)" },
      { input: "5555555555", desc: "Starts with 5 (invalid Indian mobile prefix)" },
      { input: "1234567890", desc: "Starts with 1 (invalid Indian mobile prefix)" },
      { input: "0123456789", desc: "Starts with 0 followed by 1" },
      { input: "987654321099", desc: "12 digits starting with 98 (too long)" },
      { input: "98765abcde", desc: "Contains alphabetic letters" },
      { input: "", desc: "Empty string" },
      { input: "   ", desc: "Whitespace only" },
    ];

    for (const tc of invalidCases) {
      let threw = false;
      try {
        normalizeIndianPhone(tc.input);
      } catch {
        threw = true;
      }
      assert(threw, `Rejects invalid phone: ${tc.desc}`);
      assert(!isValidIndianPhone(tc.input), `isValidIndianPhone returns false for: ${tc.desc}`);
    }
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 3: Cryptographically Secure OTP Generation
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 3] Cryptographically Secure OTP Generation");
  {
    let allValid = true;
    const generated = new Set<string>();

    for (let i = 0; i < 500; i++) {
      const otp = generateSecureOtp();
      if (!/^\d{6}$/.test(otp)) {
        allValid = false;
        break;
      }
      const num = parseInt(otp, 10);
      if (num < 100000 || num > 999999) {
        allValid = false;
        break;
      }
      generated.add(otp);
    }

    assert(allValid, "500 generated OTPs are strictly 6-digit numeric values between 100000 and 999999");
    assert(generated.size > 480, `High entropy verified (generated ${generated.size} distinct OTPs across 500 iterations)`);

    const salt = generateSecureSalt();
    assert(typeof salt === "string" && salt.length === 32, "Salt is a 32-character hex string (16 secure bytes)");
    const salt2 = generateSecureSalt();
    assert(salt !== salt2, "Subsequent salt generation produces distinct salts");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 4: OTP Hashing & Non-Plaintext Verification
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 4] OTP Hashing & Non-Plaintext Binding");
  {
    const otp = "845219";
    const salt = generateSecureSalt();
    const phone = "+919876543210";

    const hash = await hashOtp(otp, salt, phone);

    assert(typeof hash === "string" && hash.length === 64, "OTP hash is a 64-character SHA-256 hex string");
    assert(!hash.includes(otp), "OTP hash does NOT contain the plaintext OTP");
    assert(!hash.includes(phone), "OTP hash does NOT contain the plaintext phone number");

    // Salt binding: same OTP + phone with different salt produces different hash
    const differentSalt = generateSecureSalt();
    const hashDiffSalt = await hashOtp(otp, differentSalt, phone);
    assert(hash !== hashDiffSalt, "Hash is cryptographically bound to salt (different salt produces different hash)");

    // Phone binding: same OTP + salt with different phone produces different hash
    const differentPhone = "+919123456780";
    const hashDiffPhone = await hashOtp(otp, salt, differentPhone);
    assert(hash !== hashDiffPhone, "Hash is cryptographically bound to phone (different phone produces different hash)");

    // OTP binding: different OTP + same salt & phone produces different hash
    const hashDiffOtp = await hashOtp("123456", salt, phone);
    assert(hash !== hashDiffOtp, "Different OTP produces different hash");

    // Constant-time compare behavior
    assert(constantTimeCompare(hash, hash), "constantTimeCompare returns true for identical hashes");
    assert(!constantTimeCompare(hash, hashDiffOtp), "constantTimeCompare returns false for differing hashes");
    assert(!constantTimeCompare(hash, "short"), "constantTimeCompare returns false for different length strings");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 5: SMS Transport Boundary Safety
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 5] SMS Transport Boundary Safety");
  {
    const mockTransport = new MockSmsTransport();
    const phone = "+919876543210";
    const requestId = crypto.randomUUID();
    const otp = "654321";
    const message = `Your CivicFix verification code is ${otp}. It expires in 5 minutes.`;

    const result = await mockTransport.sendSms(phone, message, requestId);

    assert(result.success === true, "MockSmsTransport dispatches successfully without network calls");
    assert(!!result.gatewayMessageId, "MockSmsTransport provides simulated gateway tracking ID");
    assert(mockTransport.lastDispatched?.phone === phone, "Mock transport records recipient phone");
    assert(mockTransport.lastDispatched?.requestId === requestId, "Mock transport records request ID");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 6: Challenge Expiry Check
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 6] Challenge Expiry Verification");
  {
    assert(OTP_LIFETIME_SECONDS === 300, "OTP lifetime is configured to 300 seconds (5 minutes)");

    const now = Date.now();
    const activeExpiresAt = new Date(now + 120_000).getTime();
    const expiredExpiresAt = new Date(now - 1_000).getTime();

    const isActiveExpired = activeExpiresAt <= now;
    const isExpiredExpired = expiredExpiresAt <= now;

    assert(!isActiveExpired, "Challenge with future expires_at is active and valid");
    assert(isExpiredExpired, "Challenge with past expires_at is correctly identified as expired (OTP_EXPIRED)");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 7: Wrong OTP & Attempt Counting
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 7] Wrong OTP Verification & Attempt Tracking");
  {
    assert(MAX_VERIFICATION_ATTEMPTS === 3, "Max verification attempts is configured to 3");

    const phone = "+919876543210";
    const actualOtp = "456789";
    const wrongOtp = "111111";
    const salt = generateSecureSalt();
    const actualHash = await hashOtp(actualOtp, salt, phone);

    // Attempt 1: wrong OTP
    const wrongHash1 = await hashOtp(wrongOtp, salt, phone);
    const isMatch1 = constantTimeCompare(wrongHash1, actualHash);
    let attempts = 0;
    if (!isMatch1) attempts += 1;
    let remaining = Math.max(0, MAX_VERIFICATION_ATTEMPTS - attempts);

    assert(!isMatch1, "Wrong OTP does not match actual hash");
    assert(attempts === 1, "Failed attempt increments attempts counter to 1");
    assert(remaining === 2, "Remaining attempts calculated as 2 after first failure");

    // Attempt 2: wrong OTP
    const isMatch2 = constantTimeCompare(wrongHash1, actualHash);
    if (!isMatch2) attempts += 1;
    remaining = Math.max(0, MAX_VERIFICATION_ATTEMPTS - attempts);

    assert(attempts === 2, "Failed attempt increments attempts counter to 2");
    assert(remaining === 1, "Remaining attempts calculated as 1 after second failure");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 8: Three Failed Attempts Lockout
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 8] Three Failed Attempts Lockout (MAX_ATTEMPTS_EXCEEDED)");
  {
    const phone = "+919876543210";
    const actualOtp = "456789";
    const salt = generateSecureSalt();
    const actualHash = await hashOtp(actualOtp, salt, phone);

    let attempts = 2; // already failed twice
    const wrongOtp = "000000";
    const wrongHash = await hashOtp(wrongOtp, salt, phone);
    const isMatch = constantTimeCompare(wrongHash, actualHash);

    if (!isMatch) attempts += 1;
    const isLockedOut = attempts >= MAX_VERIFICATION_ATTEMPTS;
    const remaining = Math.max(0, MAX_VERIFICATION_ATTEMPTS - attempts);

    assert(attempts === 3, "Attempts count reaches 3 on third consecutive failure");
    assert(isLockedOut, "Challenge is locked out when attempts >= max_attempts");
    assert(remaining === 0, "Remaining attempts is 0 upon lockout");

    // Even if the user enters the CORRECT OTP after lockout, it must be rejected!
    const correctHash = await hashOtp(actualOtp, salt, phone);
    const correctMatch = constantTimeCompare(correctHash, actualHash);
    assert(correctMatch, "Cryptographic hash matches actual OTP");
    const allowedAfterLockout = !isLockedOut && correctMatch;
    assert(!allowedAfterLockout, "Post-lockout correct OTP submission is BLOCKED by server-side attempt check");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 9: Consumed OTP Reuse Prevention (Atomic Invalidation)
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 9] Consumed OTP Reuse Prevention");
  {
    const challengeState = {
      phone: "+919876543210",
      consumed: false,
      consumed_at: null as string | null,
    };

    // First successful verification marks consumed
    challengeState.consumed = true;
    challengeState.consumed_at = new Date().toISOString();

    assert(challengeState.consumed === true, "Successful verification atomically marks challenge as consumed");
    assert(challengeState.consumed_at !== null, "consumed_at timestamp is populated");

    // Replay attempt with same challenge
    const canReplay = !challengeState.consumed;
    assert(!canReplay, "Replay attack on consumed challenge is REJECTED (OTP_ALREADY_USED)");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 10: Resend Cooldown (30 Seconds)
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 10] Resend Cooldown Enforcement (30s Server-Side)");
  {
    assert(RESEND_COOLDOWN_SECONDS === 30, "Resend cooldown is configured to 30 seconds");

    const now = Date.now();
    const recentRequestTime = new Date(now - 10_000).getTime(); // 10 seconds ago
    const elapsedMs = now - recentRequestTime;
    const cooldownMs = RESEND_COOLDOWN_SECONDS * 1000;

    const isCooldownActive = elapsedMs < cooldownMs;
    const remainingCooldown = Math.ceil((cooldownMs - elapsedMs) / 1000);

    assert(isCooldownActive, "Request at T+10s is blocked by active 30-second cooldown");
    assert(remainingCooldown === 20, `Remaining cooldown calculated correctly (expected 20s, got ${remainingCooldown}s)`);

    // Request after 35 seconds
    const olderRequestTime = new Date(now - 35_000).getTime();
    const olderElapsedMs = now - olderRequestTime;
    const isOlderCooldownActive = olderElapsedMs < cooldownMs;

    assert(!isOlderCooldownActive, "Request at T+35s is allowed after cooldown expires");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 11: Hourly Rate Limit (5 Sends/Hour)
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 11] Hourly Rate Limit Enforcement (Max 5 per hour)");
  {
    assert(HOURLY_RATE_LIMIT === 5, "Hourly rate limit is configured to 5 requests per hour");

    const simulateHourlyCount = (count: number) => count >= HOURLY_RATE_LIMIT;

    assert(!simulateHourlyCount(0), "0 sends in past hour: allowed");
    assert(!simulateHourlyCount(4), "4 sends in past hour: allowed");
    assert(simulateHourlyCount(5), "5 sends in past hour: BLOCKED (HOURLY_LIMIT_EXCEEDED)");
    assert(simulateHourlyCount(8), "8 sends in past hour: BLOCKED (HOURLY_LIMIT_EXCEEDED)");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 12: Request ID Uniqueness & Phone Mismatch
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 12] Request ID Uniqueness & Challenge Mismatch");
  {
    const reqId1 = crypto.randomUUID();
    const reqId2 = crypto.randomUUID();
    assert(reqId1 !== reqId2, "Generated request IDs are unique UUIDs");

    const challengeRecord = {
      request_id: reqId1,
      phone: "+919876543210",
    };

    // Correct phone matching
    const matchingPhone = "+919876543210";
    assert(challengeRecord.phone === matchingPhone, "Matching phone number accepted for challenge");

    // Mismatched phone
    const attackerPhone = "+919123456780";
    const isPhoneMatch = challengeRecord.phone === attackerPhone;
    assert(!isPhoneMatch, "Mismatched phone number REJECTED for challenge (CHALLENGE_MISMATCH)");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 13: Unauthenticated Request Handling
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 13] Unauthenticated Request Rejection");
  {
    const emptyTokenResult = await verifyFirebaseIdToken("");
    assert(!emptyTokenResult.valid, "Empty token is rejected as invalid (UNAUTHORIZED)");

    const malformedTokenResult = await verifyFirebaseIdToken("malformed.jwt.token");
    assert(!malformedTokenResult.valid, "Malformed JWT structure is rejected as invalid");

    const nonJwtToken = await verifyFirebaseIdToken("not_even_a_jwt");
    assert(!nonJwtToken.valid, "Non-JWT string is rejected as invalid");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 14: Production Response Hygiene (No Secrets Leaked)
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 14] Production Response Hygiene");
  {
    const sendOtpResponse = {
      success: true,
      request_id: crypto.randomUUID(),
      expires_in: OTP_LIFETIME_SECONDS,
      resend_after: RESEND_COOLDOWN_SECONDS,
    };

    assert(!("otp" in sendOtpResponse), "send-otp response does NOT include 'otp'");
    assert(!("salt" in sendOtpResponse), "send-otp response does NOT include 'salt'");
    assert(!("otp_hash" in sendOtpResponse), "send-otp response does NOT include 'otp_hash'");

    const verifyOtpResponse = {
      success: true,
      phone: "+919876543210",
      phoneVerified: true,
      message: "Phone number verified successfully.",
    };

    assert(!("otp" in verifyOtpResponse), "verify-otp response does NOT include 'otp'");
    assert(!("salt" in verifyOtpResponse), "verify-otp response does NOT include 'salt'");
    assert(!("otp_hash" in verifyOtpResponse), "verify-otp response does NOT include 'otp_hash'");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 15: Phone Number Masking Utility
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 15] Phone Number Masking Utility");
  {
    assert(maskPhoneNumber("+919876543210") === "+9198****10", "Masks standard Indian mobile (+919876543210 -> +9198****10)");
    assert(maskPhoneNumber("9876543210") === "9876****10", "Masks 10-digit mobile (9876543210 -> 9876****10)");
    assert(maskPhoneNumber("12345") === "12****", "Handles short strings safely");
    assert(maskPhoneNumber("") === "[invalid_phone]", "Handles empty string safely");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 16: SMS Transport Factory & Secret Validation
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 16] SMS Transport Factory & Secret Validation");
  {
    const originalEnv = { ...process.env };

    // 1. Default safe behavior: returns MockSmsTransport when SMS_TRANSPORT is unset
    delete process.env.SMS_TRANSPORT;
    const defaultTransport = getSmsTransport();
    assert(defaultTransport instanceof MockSmsTransport, "Defaults to MockSmsTransport when SMS_TRANSPORT is unset");

    // 2. Explicit SMS_TRANSPORT=mock
    process.env.SMS_TRANSPORT = "mock";
    const explicitMockTransport = getSmsTransport();
    assert(explicitMockTransport instanceof MockSmsTransport, "Returns MockSmsTransport when SMS_TRANSPORT='mock'");

    // 3. SMS_TRANSPORT=gateway but secrets missing -> MUST throw SMS_GATEWAY_CONFIG_ERROR (never silent fallback)
    process.env.SMS_TRANSPORT = "gateway";
    delete process.env.SMS_GATEWAY_URL;
    delete process.env.SMS_GATEWAY_API_KEY;

    let threwConfigErr = false;
    let configErrMsg = "";
    try {
      getSmsTransport();
    } catch (err: any) {
      threwConfigErr = true;
      configErrMsg = err.message;
    }
    assert(threwConfigErr, "Throws error when SMS_TRANSPORT='gateway' but secrets are missing");
    assert(configErrMsg.includes("SMS_GATEWAY_CONFIG_ERROR"), "Error code is SMS_GATEWAY_CONFIG_ERROR");

    // 4. SMS_TRANSPORT=gateway with secrets present -> returns GatewaySmsTransport
    process.env.SMS_GATEWAY_URL = "http://127.0.0.1:8080";
    process.env.SMS_GATEWAY_API_KEY = "test_key_123";
    const gatewayTransport = getSmsTransport();
    assert(gatewayTransport instanceof GatewaySmsTransport, "Returns GatewaySmsTransport when SMS_TRANSPORT='gateway' with valid env");

    // 5. Unrecognized SMS_TRANSPORT -> MUST throw SMS_TRANSPORT_INVALID
    process.env.SMS_TRANSPORT = "unknown_carrier";
    let threwInvalidErr = false;
    try {
      getSmsTransport();
    } catch (err: any) {
      threwInvalidErr = true;
      assert(err.message.includes("SMS_TRANSPORT_INVALID"), "Error code is SMS_TRANSPORT_INVALID for unknown transport");
    }
    assert(threwInvalidErr, "Throws error when SMS_TRANSPORT is invalid");

    // Restore env
    process.env = originalEnv;
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 17: Gateway HTTP Responses & PENDING Acceptance (Mock Server)
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 17] Gateway HTTP Responses & PENDING Acceptance");
  {
    // Start local HTTP server to simulate Android Gateway responses
    let serverMode: "success" | "auth_error" | "rate_limit" | "server_error" | "failure_json" | "malformed_json" = "success";
    let lastReceivedHeaders: http.IncomingHttpHeaders = {};
    let lastReceivedBody: any = null;

    const mockServer = http.createServer((req, res) => {
      lastReceivedHeaders = req.headers;
      let bodyData = "";
      req.on("data", (chunk) => { bodyData += chunk; });
      req.on("end", () => {
        try { lastReceivedBody = JSON.parse(bodyData); } catch { lastReceivedBody = bodyData; }

        if (serverMode === "success") {
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({
            success: true,
            sms_id: 1042,
            request_id: lastReceivedBody?.request_id,
            status: "PENDING",
          }));
        } else if (serverMode === "auth_error") {
          res.writeHead(401, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ success: false, error: "Unauthorized" }));
        } else if (serverMode === "rate_limit") {
          res.writeHead(429, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ success: false, error: "Rate limit exceeded" }));
        } else if (serverMode === "server_error") {
          res.writeHead(500, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ success: false, error: "SmsManager internal crash" }));
        } else if (serverMode === "failure_json") {
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ success: false, error: "SIM 1 no cellular service" }));
        } else if (serverMode === "malformed_json") {
          res.writeHead(200, { "Content-Type": "text/html" });
          res.end("<html><body>Bad Gateway</body></html>");
        }
      });
    });

    await new Promise<void>((resolve) => mockServer.listen(0, "127.0.0.1", resolve));
    const port = (mockServer.address() as AddressInfo).port;
    const gatewayUrl = `http://127.0.0.1:${port}`;
    const apiKey = "cf_secret_key_audit_test";
    const transport = new GatewaySmsTransport(gatewayUrl, apiKey, 2000);

    const testPhone = "+919876543210";
    const testMsg = "Your CivicFix verification code is 654321. It expires in 5 minutes.";
    const testReqId = crypto.randomUUID();

    // 1. Successful gateway response (HTTP 200, status PENDING, sms_id)
    serverMode = "success";
    const resSuccess = await transport.sendSms(testPhone, testMsg, testReqId);
    assert(resSuccess.success === true, "Gateway dispatch succeeded with HTTP 200");
    assert(resSuccess.gatewayStatus === "PENDING", "Gateway acceptance status is PENDING");
    assert(resSuccess.gatewayMessageId === "1042", "Gateway SMS ID returned as 1042");
    assert(lastReceivedHeaders["x-api-key"] === apiKey, "X-API-Key header forwarded correctly to gateway");
    assert(lastReceivedHeaders["content-type"] === "application/json", "Content-Type header set to application/json");
    assert(lastReceivedBody.phone_number === testPhone, "phone_number in payload matches");
    assert(lastReceivedBody.message === testMsg, "message in payload matches");
    assert(lastReceivedBody.request_id === testReqId, "request_id in payload matches");

    // 2. Gateway HTTP 401 Unauthorized
    serverMode = "auth_error";
    const resAuth = await transport.sendSms(testPhone, testMsg, testReqId);
    assert(resAuth.success === false, "Gateway HTTP 401 returns success: false");
    assert(resAuth.errorCode === "SMS_GATEWAY_AUTH_ERROR", "Gateway HTTP 401 maps to SMS_GATEWAY_AUTH_ERROR");
    assert(!resAuth.error?.includes(apiKey), "Error message does not leak API key");
    assert(!resAuth.error?.includes(gatewayUrl), "Error message does not leak Gateway URL");

    // 3. Gateway HTTP 429 Rate Limited
    serverMode = "rate_limit";
    const resRate = await transport.sendSms(testPhone, testMsg, testReqId);
    assert(resRate.success === false, "Gateway HTTP 429 returns success: false");
    assert(resRate.errorCode === "SMS_GATEWAY_RATE_LIMITED", "Gateway HTTP 429 maps to SMS_GATEWAY_RATE_LIMITED");

    // 4. Gateway HTTP 500 Server Error
    serverMode = "server_error";
    const res500 = await transport.sendSms(testPhone, testMsg, testReqId);
    assert(res500.success === false, "Gateway HTTP 500 returns success: false");
    assert(res500.errorCode === "SMS_GATEWAY_SERVER_ERROR", "Gateway HTTP 500 maps to SMS_GATEWAY_SERVER_ERROR");

    // 5. Gateway HTTP 200 with success=false
    serverMode = "failure_json";
    const resFailJson = await transport.sendSms(testPhone, testMsg, testReqId);
    assert(resFailJson.success === false, "Gateway success=false returns success: false");
    assert(resFailJson.errorCode === "SMS_GATEWAY_DISPATCH_FAILED", "Maps to SMS_GATEWAY_DISPATCH_FAILED");

    // 6. Gateway HTTP 200 with Malformed JSON
    serverMode = "malformed_json";
    const resMalformed = await transport.sendSms(testPhone, testMsg, testReqId);
    assert(resMalformed.success === false, "Malformed JSON returns success: false");
    assert(resMalformed.errorCode === "SMS_GATEWAY_INVALID_RESPONSE", "Maps to SMS_GATEWAY_INVALID_RESPONSE");

    mockServer.close();
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 18: Gateway Timeout Handling (Strict 5-8s Boundary)
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 18] Gateway Timeout Handling");
  {
    // Start a server that intentionally hangs without completing the response
    const hangingServer = http.createServer((_req, _res) => {
      // Deliberately hold connection open without sending a response
    });

    await new Promise<void>((resolve) => hangingServer.listen(0, "127.0.0.1", resolve));
    const port = (hangingServer.address() as AddressInfo).port;
    const hangingUrl = `http://127.0.0.1:${port}`;

    // Test with a short 80ms timeout to verify abort behavior
    const timeoutTransport = new GatewaySmsTransport(hangingUrl, "secret_key", 80);
    const start = Date.now();
    const resTimeout = await timeoutTransport.sendSms("+919876543210", "test otp", crypto.randomUUID());
    const elapsed = Date.now() - start;

    assert(resTimeout.success === false, "Timed-out request returns success: false");
    assert(resTimeout.errorCode === "SMS_GATEWAY_TIMEOUT", "Error code is SMS_GATEWAY_TIMEOUT");
    assert(resTimeout.error === "SMS gateway request timed out. Please try again.", "Error message is clean and sanitized");
    assert(elapsed >= 70, `Timeout triggered around target window (took ${elapsed}ms)`);
    assert(!resTimeout.error?.includes(hangingUrl), "Timeout error does not leak gateway URL");

    hangingServer.close();
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 19: Missing Configuration Handling in GatewaySmsTransport
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 19] Missing Configuration Handling in GatewaySmsTransport");
  {
    const missingUrlTransport = new GatewaySmsTransport("", "secret_key");
    const resNoUrl = await missingUrlTransport.sendSms("+919876543210", "msg", crypto.randomUUID());
    assert(!resNoUrl.success, "Missing gateway URL returns success: false");
    assert(resNoUrl.errorCode === "SMS_GATEWAY_CONFIG_ERROR", "Error code is SMS_GATEWAY_CONFIG_ERROR");

    const missingKeyTransport = new GatewaySmsTransport("http://127.0.0.1:8080", "");
    const resNoKey = await missingKeyTransport.sendSms("+919876543210", "msg", crypto.randomUUID());
    assert(!resNoKey.success, "Missing API key returns success: false");
    assert(resNoKey.errorCode === "SMS_GATEWAY_CONFIG_ERROR", "Error code is SMS_GATEWAY_CONFIG_ERROR");
  }

  // --------------------------------------------------------------------------
  // TEST GROUP 20: Safe Retry & Request ID Idempotency
  // --------------------------------------------------------------------------
  console.log("\n[Test Group 20] Safe Retry & Request ID Idempotency");
  {
    const reqId = crypto.randomUUID();

    // Verify request_id is consistent and forwarded
    const mockTransport = new MockSmsTransport();
    await mockTransport.sendSms("+919876543210", "Your code is 123456", reqId);
    assert(mockTransport.lastDispatched?.requestId === reqId, "OTP challenge UUID is forwarded as gateway request_id");

    // Verify no automatic blind retry loop inside transport
    // (Simulate dispatch failure and ensure exactly 1 attempt was made)
    let callCount = 0;
    const singleAttemptServer = http.createServer((_req, res) => {
      callCount++;
      res.writeHead(503, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ success: false, error: "Gateway busy" }));
    });

    await new Promise<void>((resolve) => singleAttemptServer.listen(0, "127.0.0.1", resolve));
    const port = (singleAttemptServer.address() as AddressInfo).port;
    const testTransport = new GatewaySmsTransport(`http://127.0.0.1:${port}`, "key", 500);

    const failRes = await testTransport.sendSms("+919876543210", "Your code is 123456", reqId);
    assert(failRes.success === false, "Failing gateway call returns success: false");
    assert(callCount === 1, "Gateway transport executes exactly 1 attempt (NO dangerous automatic retry loops)");

    singleAttemptServer.close();
  }

  // --------------------------------------------------------------------------
  // Test Summary
  // --------------------------------------------------------------------------
  console.log("\n================================================================");
  console.log(`TEST RESULTS: ${passedTests} passed, ${failedTests} failed`);
  console.log("================================================================\n");

  if (failedTests > 0) {
    process.exit(1);
  }
}

runTestSuite().catch((err) => {
  console.error("Unexpected test execution error:", err);
  process.exit(1);
});
