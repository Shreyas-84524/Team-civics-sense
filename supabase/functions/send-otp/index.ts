import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { normalizeIndianPhone } from "../_shared/otp-security.ts";
import { verifyFirebaseIdToken } from "../_shared/firebase-auth.ts";
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
  let body: { phone?: string };
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
    console.error("[send-otp] Configuration error:", configErr.message);
    return new Response(
      JSON.stringify({
        success: false,
        error: "INTERNAL_ERROR",
        message: "SMS verification service is temporarily unconfigured.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  try {
    // 6. Generate request idempotency key and dispatch to Global OTP backend
    const idempotencyKey = crypto.randomUUID();
    const result = await globalOtpClient.sendOtp(
      normalizedPhone,
      idempotencyKey,
      {
        citizen_uid: callerUid,
        app: "CivicFix",
      }
    );

    if (!result.success) {
      const statusCode = result.statusCode || 500;
      return new Response(
        JSON.stringify({
          success: false,
          error: result.errorCode || "GATEWAY_DELIVERY_FAILED",
          message: result.error || "Unable to send verification code at this time.",
          resend_after: result.retryAfterSeconds,
          retry_after: result.retryAfterSeconds,
        }),
        {
          status: statusCode,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `[send-otp] OTP challenge created via Global OTP for UID ${callerUid} (${maskPhoneNumber(normalizedPhone)}) [ReqId: ${result.requestId}]`
    );

    // 7. Clean Citizen Response (OTP plaintext is NEVER returned)
    return new Response(
      JSON.stringify({
        success: true,
        request_id: result.requestId,
        expires_in: result.expiresIn || 300,
        resend_after: result.resendAfter || 30,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: any) {
    console.error("[send-otp] Unhandled processing error:", err);
    return new Response(
      JSON.stringify({
        success: false,
        error: "INTERNAL_ERROR",
        message: err.message || "Failed to process phone verification request.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
