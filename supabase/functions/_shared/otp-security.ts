/**
 * CivicFix Phone Verification Security Utilities
 *
 * Implements:
 * - Cryptographically secure 6-digit OTP generation (rejection sampled)
 * - Salt generation & SHA-256 OTP hashing (bound to salt + phone)
 * - Constant-time equality comparison
 * - Indian mobile phone normalization (E.164 +91 format)
 * - Rate limiting and lifetime constants
 */

export const OTP_LIFETIME_SECONDS = 300; // 5 minutes
export const MAX_VERIFICATION_ATTEMPTS = 3;
export const RESEND_COOLDOWN_SECONDS = 30; // 30 seconds
export const HOURLY_RATE_LIMIT = 5; // Max 5 challenges per phone per hour

const CLEAN_PHONE_REGEX = /[\s\-\(\)\+]/g;
const DIGIT_ONLY_REGEX = /^[0-9]+$/;
const INDIAN_VALID_START_REGEX = /^[6-9]/;

/**
 * Normalizes an Indian mobile phone number into canonical E.164 format (+91XXXXXXXXXX).
 * Throws an Error if the phone number is invalid.
 */
export function normalizeIndianPhone(input: string): string {
  if (!input || typeof input !== "string") {
    throw new Error("Phone number must be a non-empty string.");
  }

  const cleaned = input.replace(CLEAN_PHONE_REGEX, "").trim();
  if (!DIGIT_ONLY_REGEX.test(cleaned)) {
    throw new Error("Phone number must contain digits only.");
  }

  let tenDigit: string | null = null;

  if (cleaned.length === 10) {
    if (INDIAN_VALID_START_REGEX.test(cleaned)) {
      tenDigit = cleaned;
    }
  } else if (cleaned.length === 11 && cleaned.startsWith("0")) {
    const sub = cleaned.substring(1);
    if (INDIAN_VALID_START_REGEX.test(sub)) {
      tenDigit = sub;
    }
  } else if (cleaned.length === 12 && cleaned.startsWith("91")) {
    const sub = cleaned.substring(2);
    if (INDIAN_VALID_START_REGEX.test(sub)) {
      tenDigit = sub;
    }
  }

  if (!tenDigit) {
    throw new Error(
      "Invalid Indian mobile number. Must be a 10-digit number starting with 6, 7, 8, or 9."
    );
  }

  return `+91${tenDigit}`;
}

/**
 * Returns true if the input is a valid Indian mobile number format.
 */
export function isValidIndianPhone(input: string): boolean {
  try {
    normalizeIndianPhone(input);
    return true;
  } catch {
    return false;
  }
}

/**
 * Generates a cryptographically secure 6-digit numeric OTP string (100000 - 999999).
 * Uses rejection sampling over a 32-bit random integer to eliminate modulo bias.
 */
export function generateSecureOtp(): string {
  const buffer = new Uint32Array(1);
  const range = 900000;
  const maxUint32 = 4294967295;
  const limit = maxUint32 - (maxUint32 % range);

  let randomVal: number;
  do {
    crypto.getRandomValues(buffer);
    randomVal = buffer[0];
  } while (randomVal >= limit);

  const otpCode = 100000 + (randomVal % range);
  return otpCode.toString();
}

/**
 * Generates a cryptographically secure random 16-byte salt as a 32-character hex string.
 */
export function generateSecureSalt(): string {
  const saltBytes = new Uint8Array(16);
  crypto.getRandomValues(saltBytes);
  return Array.from(saltBytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Computes a SHA-256 hash of the OTP cryptographically bound to its unique salt and recipient phone.
 * Binding the phone number prevents cross-account or cross-session OTP replay.
 */
export async function hashOtp(otp: string, salt: string, phone: string): Promise<string> {
  const payload = `${salt}:${otp.trim()}:${phone.trim()}`;
  const data = new TextEncoder().encode(payload);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * Timing-safe string equality comparison to protect against timing attacks.
 */
export function constantTimeCompare(a: string, b: string): boolean {
  if (typeof a !== "string" || typeof b !== "string") {
    return false;
  }
  if (a.length !== b.length) {
    return false;
  }

  let mismatch = 0;
  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }

  return mismatch === 0;
}
