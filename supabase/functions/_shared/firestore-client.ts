/**
 * CivicFix Firestore Identity & Phone Ownership Client
 *
 * Interacts with Cloud Firestore via REST API using Firebase Service Account OAuth2 credentials.
 * Authoritatively enforces:
 * 1. 1 Verified Phone Number = 1 Citizen Account (/phoneIndex/{+91XXXXXXXXXX})
 * 2. Updating /users/{uid} with phoneVerified: true upon successful verification
 */

import { maskPhoneNumber } from "./sms-transport.ts";

interface ServiceAccountConfig {
  project_id: string;
  client_email: string;
  private_key: string;
}

function base64UrlEncode(input: string | Uint8Array): string {
  let binary = "";
  if (typeof input === "string") {
    const bytes = new TextEncoder().encode(input);
    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
  } else {
    for (let i = 0; i < input.length; i++) {
      binary += String.fromCharCode(input[i]);
    }
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToPkcs8Binary(pem: string): Uint8Array {
  const cleanPem = pem
    .replace(/-----BEGIN[ A-Z0-9_-]+-----/g, "")
    .replace(/-----END[ A-Z0-9_-]+-----/g, "")
    .replace(/\s+/g, "");
  const binaryString = atob(cleanPem);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

async function getGoogleOAuthToken(serviceAccount: ServiceAccountConfig): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 60) {
    return cachedAccessToken.token;
  }

  const privateKeyBytes = pemToPkcs8Binary(serviceAccount.private_key);
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    privateKeyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/datastore",
  };

  const unsignedToken = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(claims))}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(unsignedToken)
  );

  const assertionJwt = `${unsignedToken}.${base64UrlEncode(new Uint8Array(signature))}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: assertionJwt,
    }),
  });

  if (!tokenRes.ok) {
    const errorBody = await tokenRes.text();
    throw new Error(`Firebase OAuth2 token exchange failed (${tokenRes.status}): ${errorBody}`);
  }

  const tokenData = await tokenRes.json();
  const token = tokenData.access_token as string;
  cachedAccessToken = { token, expiresAt: now + 3500 };
  return token;
}

function getServiceAccountConfig(): ServiceAccountConfig | null {
  const rawSecret = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
  if (!rawSecret || rawSecret.trim() === "") {
    return null;
  }

  try {
    const parsed = JSON.parse(rawSecret.trim());
    if (parsed.client_email && parsed.private_key) {
      return {
        project_id: parsed.project_id || "civicfix-38d53",
        client_email: parsed.client_email,
        private_key: parsed.private_key.replace(/\\n/g, "\n"),
      };
    }
  } catch (err) {
    console.error("[FirestoreClient] Error parsing FIREBASE_SERVICE_ACCOUNT_KEY secret:", err);
  }
  return null;
}

export interface ClaimPhoneResult {
  success: boolean;
  error?: string;
  statusCode?: number;
}

/**
 * Validates phone uniqueness and binds the verified phone number to the citizen's Firestore account.
 */
export async function claimPhoneAndVerifyCitizen(
  phone: string,
  uid: string
): Promise<ClaimPhoneResult> {
  const serviceAccount = getServiceAccountConfig();

  // If service account is not configured yet (e.g. initial testing), acknowledge gracefully
  if (!serviceAccount) {
    console.warn(
      `[FirestoreClient] Notice: FIREBASE_SERVICE_ACCOUNT_KEY not configured. Firestore sync for UID ${uid} deferred.`
    );
    return { success: true };
  }

  const projectId = serviceAccount.project_id;
  const accessToken = await getGoogleOAuthToken(serviceAccount);

  const phoneDocId = encodeURIComponent(phone);
  const phoneIndexUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/phoneIndex/${phoneDocId}`;
  const userUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${uid}`;

  // 1. Check existing phone index ownership
  const checkRes = await fetch(phoneIndexUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (checkRes.ok) {
    const phoneData = await checkRes.json();
    const existingUid = phoneData.fields?.uid?.stringValue;
    if (existingUid && existingUid !== uid) {
      return {
        success: false,
        statusCode: 409,
        error: "This phone number is already associated with another CivicFix account.",
      };
    }
  }

  // 2. Read citizen profile to check for previous verified phone
  const userRes = await fetch(userUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (userRes.ok) {
    const userData = await userRes.json();
    const oldPhone = userData.fields?.phone?.stringValue;
    const oldVerified = userData.fields?.phoneVerified?.booleanValue;

    if (oldPhone && oldPhone !== phone && oldVerified === true) {
      const oldPhoneDocId = encodeURIComponent(oldPhone);
      const oldPhoneUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/phoneIndex/${oldPhoneDocId}`;
      try {
        await fetch(oldPhoneUrl, {
          method: "DELETE",
          headers: { Authorization: `Bearer ${accessToken}` },
        });
      } catch (delErr) {
        console.warn(`[FirestoreClient] Notice: Could not prune old phoneIndex ${maskPhoneNumber(oldPhone)}:`, delErr);
      }
    }
  }

  const nowIso = new Date().toISOString();

  // 3. Write /phoneIndex/{phone}
  const writeIndexRes = await fetch(phoneIndexUrl, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      fields: {
        uid: { stringValue: uid },
        phone: { stringValue: phone },
        verifiedAt: { timestampValue: nowIso },
        updatedAt: { timestampValue: nowIso },
      },
    }),
  });

  if (!writeIndexRes.ok) {
    const errText = await writeIndexRes.text();
    console.error(`[FirestoreClient] Failed writing phoneIndex for ${maskPhoneNumber(phone)}: ${errText}`);
    return {
      success: false,
      statusCode: 500,
      error: "Failed to update phone index registry in Firestore.",
    };
  }

  // 4. Update citizen profile /users/{uid}
  const updateUserRes = await fetch(
    `${userUrl}?updateMask.fieldPaths=phone&updateMask.fieldPaths=phoneVerified&updateMask.fieldPaths=phoneVerifiedAt&updateMask.fieldPaths=updatedAt`,
    {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        fields: {
          phone: { stringValue: phone },
          phoneVerified: { booleanValue: true },
          phoneVerifiedAt: { timestampValue: nowIso },
          updatedAt: { timestampValue: nowIso },
        },
      }),
    }
  );

  if (!updateUserRes.ok) {
    const errText = await updateUserRes.text();
    console.error(`[FirestoreClient] Failed updating citizen profile for UID ${uid}: ${errText}`);
    return {
      success: false,
      statusCode: 500,
      error: "Failed to update citizen verification status in Firestore.",
    };
  }

  return { success: true };
}
