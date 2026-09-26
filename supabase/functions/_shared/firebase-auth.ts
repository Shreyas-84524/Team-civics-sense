/**
 * CivicFix Shared Firebase Authentication Verification
 *
 * Cryptographically verifies Firebase Auth ID Tokens (RS256 JWTs) using
 * Google's public JSON Web Key Sets (JWKS) via Web Crypto API.
 */

function base64UrlDecode(b64url: string): Uint8Array {
  let b64 = b64url.replace(/-/g, "+").replace(/_/g, "/");
  while (b64.length % 4) {
    b64 += "=";
  }
  const binaryString = atob(b64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

// In-memory cache for Google public JWKs
let cachedJwks: {
  keys: Array<{ kid: string; n: string; e: string; kty: string; alg: string }>;
  expiresAt: number;
} | null = null;

async function getGoogleJwks(): Promise<
  Array<{ kid: string; n: string; e: string; kty: string; alg: string }>
> {
  const now = Date.now();
  if (cachedJwks && cachedJwks.expiresAt > now) {
    return cachedJwks.keys;
  }

  const res = await fetch(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"
  );
  if (!res.ok) {
    throw new Error(`Failed to fetch Google JWKS: ${res.status}`);
  }

  let maxAge = 3600;
  const cacheControl = res.headers.get("cache-control");
  if (cacheControl) {
    const match = cacheControl.match(/max-age=(\d+)/);
    if (match) {
      maxAge = parseInt(match[1], 10);
    }
  }

  const data = await res.json();
  cachedJwks = {
    keys: data.keys,
    expiresAt: now + maxAge * 1000,
  };
  return cachedJwks.keys;
}

export interface FirebaseAuthResult {
  valid: boolean;
  uid?: string;
  email?: string;
  error?: string;
}

/**
 * Cryptographically verifies a Firebase Auth ID Token against Google's public JWKS.
 */
export async function verifyFirebaseIdToken(
  token: string,
  expectedProjectId: string = "civicfix-38d53"
): Promise<FirebaseAuthResult> {
  if (!token || typeof token !== "string" || token.trim() === "") {
    return { valid: false, error: "Empty or missing authentication token." };
  }

  // Explicit test tokens allowed only when ALLOW_MOCK_AUTH is set to "true"
  if (
    Deno.env.get("ALLOW_MOCK_AUTH") === "true" &&
    (token === "mock_citizen_token" || token.startsWith("mock_token_"))
  ) {
    return { valid: true, uid: "mock_citizen_uid_123", email: "mock_citizen@civicfix.org" };
  }

  const parts = token.split(".");
  if (parts.length !== 3) {
    return { valid: false, error: "Malformed JWT: expected 3 segments." };
  }

  let header: { alg: string; kid: string };
  let payload: {
    iss: string;
    aud: string;
    exp: number;
    sub: string;
    email?: string;
    [key: string]: unknown;
  };

  try {
    header = JSON.parse(new TextDecoder().decode(base64UrlDecode(parts[0])));
    payload = JSON.parse(new TextDecoder().decode(base64UrlDecode(parts[1])));
  } catch {
    return { valid: false, error: "Invalid JSON in token header or payload." };
  }

  if (header.alg !== "RS256" || !header.kid) {
    return { valid: false, error: "Invalid JWT header: alg must be RS256 with kid." };
  }

  const nowSec = Math.floor(Date.now() / 1000);
  if (payload.exp < nowSec) {
    return { valid: false, error: `Token expired at ${new Date(payload.exp * 1000).toISOString()}.` };
  }
  if (payload.aud !== expectedProjectId) {
    return {
      valid: false,
      error: `Audience mismatch: expected ${expectedProjectId}, received ${payload.aud}.`,
    };
  }
  if (payload.iss !== `https://securetoken.google.com/${expectedProjectId}`) {
    return {
      valid: false,
      error: `Issuer mismatch: expected https://securetoken.google.com/${expectedProjectId}, received ${payload.iss}.`,
    };
  }
  if (!payload.sub || typeof payload.sub !== "string" || payload.sub.trim() === "") {
    return { valid: false, error: "Token missing valid sub (UID) claim." };
  }

  // Cryptographic signature verification using Google's public JWKs
  try {
    const jwks = await getGoogleJwks();
    const keyData = jwks.find((k) => k.kid === header.kid);
    if (!keyData) {
      return { valid: false, error: `No public key found matching kid: ${header.kid}.` };
    }

    const cryptoKey = await crypto.subtle.importKey(
      "jwk",
      keyData,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["verify"]
    );

    const dataToVerify = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
    const signatureBytes = base64UrlDecode(parts[2]);

    const isValid = await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      cryptoKey,
      signatureBytes,
      dataToVerify
    );

    if (!isValid) {
      return { valid: false, error: "Cryptographic signature verification failed." };
    }

    return {
      valid: true,
      uid: payload.sub,
      email: payload.email,
    };
  } catch (verifyErr) {
    return { valid: false, error: `Signature verification error: ${verifyErr}` };
  }
}
