import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { normalizeIndianPhone } from "../_shared/otp-security.ts";
import { verifyFirebaseIdToken } from "../_shared/firebase-auth.ts";
import { claimPhoneAndVerifyCitizen } from "../_shared/firestore-client.ts";
import { maskPhoneNumber } from "../_shared/sms-transport.ts";
import { GlobalOtpClient } from "../_shared/global-otp-client.ts";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // 1. Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // 2. Enforce HTTP POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({
        success: false,
        error: "METHOD_NOT_ALLOWED",
        message: `HTTP ${req.method} is not supported. Use POST.`,
      }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  // 3. Authenticate Citizen Firebase ID Token
  const authHeader = req.headers.get("authorization") || req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "UNAUTHORIZED",
        message: "Missing or malformed Authorization header. Expected 'Bearer <token>'.",
      }),
      {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const rawToken = authHeader.substring(7).trim();
  const authResult = await verifyFirebaseIdToken(rawToken);
  if (!authResult.valid) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "UNAUTHORIZED",
        message: `Authentication failed: ${authResult.error}`,
      }),
      {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const callerUid = authResult.uid!;

  // 4. Parse & Validate Payload
  let body: { phone?: string; request_id?: string; otp?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({
        success: false,
        error: "BAD_REQUEST",
        message: "Invalid or malformed JSON payload.",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (!body.phone || typeof body.phone !== "string") {
    return new Response(
      JSON.stringify({
        success: false,
        error: "INVALID_PHONE_NUMBER",
        message: "The 'phone' parameter is required.",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (!body.request_id || typeof body.request_id !== "string") {
    return new Response(
      JSON.stringify({
        success: false,
        error: "INVALID_REQUEST_ID",
        message: "The 'request_id' parameter is required.",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (!body.otp || typeof body.otp !== "string" || body.otp.trim().length === 0) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "INVALID_OTP",
        message: "The 'otp' parameter is required.",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  let normalizedPhone: string;
  try {
    normalizedPhone = normalizeIndianPhone(body.phone);
  } catch (err: any) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "INVALID_PHONE_NUMBER",
        message: err.message || "Invalid Indian mobile phone number.",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  // 5. Initialize Global OTP Client
  let globalOtpClient: GlobalOtpClient;
  try {
    globalOtpClient = new GlobalOtpClient();
  } catch (configErr: any) {
    console.error("[verify-otp] Configuration error:", configErr.message);
    return new Response(
      JSON.stringify({
        success: false,
        error: "INTERNAL_ERROR",
        message: "Verification service is temporarily unconfigured.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  try {
    // 6. Verify Challenge with Global OTP Backend
    const cleanOtp = body.otp.trim();
    const cleanRequestId = body.request_id.trim();

    const verifyResult = await globalOtpClient.verifyOtp(
      normalizedPhone,
      cleanRequestId,
      cleanOtp
    );

    if (!verifyResult.success || !verifyResult.verified) {
      const statusCode = verifyResult.statusCode === 429 ? 429 : 400;
      return new Response(
        JSON.stringify({
          success: false,
          error: verifyResult.errorCode || "INVALID_OTP",
          message: verifyResult.error || "Incorrect verification code.",
          remaining_attempts: verifyResult.remainingAttempts,
        }),
        {
          status: statusCode,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 7. Authoritative Firestore Identity Sync (1 Phone = 1 Citizen Account)
    const claimResult = await claimPhoneAndVerifyCitizen(normalizedPhone, callerUid);
    if (!claimResult.success) {
      const statusCode = claimResult.statusCode || 500;
      return new Response(
        JSON.stringify({
          success: false,
          error: statusCode === 409 ? "PHONE_ALREADY_REGISTERED" : "IDENTITY_SYNC_FAILED",
          message: claimResult.error || "Failed to link verified phone to citizen profile.",
        }),
        {
          status: statusCode,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `[verify-otp] Successfully verified and linked ${maskPhoneNumber(normalizedPhone)} for UID ${callerUid}`
    );

    // 8. Clean Citizen Response
    return new Response(
      JSON.stringify({
        success: true,
        phone: normalizedPhone,
        phoneVerified: true,
        message: "Phone number verified successfully.",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: any) {
    console.error("[verify-otp] Unhandled processing error:", err);
    return new Response(
      JSON.stringify({
        success: false,
        error: "INTERNAL_ERROR",
        message: err.message || "Failed to process verification request.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
