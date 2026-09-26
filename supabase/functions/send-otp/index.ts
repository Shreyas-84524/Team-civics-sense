import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  normalizeIndianPhone,
  generateSecureOtp,
  generateSecureSalt,
  hashOtp,
  OTP_LIFETIME_SECONDS,
  RESEND_COOLDOWN_SECONDS,
  HOURLY_RATE_LIMIT,
} from "../_shared/otp-security.ts";
import { verifyFirebaseIdToken } from "../_shared/firebase-auth.ts";
import { getSmsTransport, maskPhoneNumber } from "../_shared/sms-transport.ts";

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

  // 3. Authenticate Firebase ID Token
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

  // 5. Initialize Supabase Database Client (service_role)
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    console.error("[send-otp] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.");
    return new Response(
      JSON.stringify({
        success: false,
        error: "INTERNAL_ERROR",
        message: "Server database configuration is incomplete.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const now = Date.now();

  try {
    // 6. Server-Authoritative Rate Limiting
    // A. 30-Second Cooldown Check
    const { data: latestRecord, error: latestErr } = await supabase
      .from("phone_verification_otps")
      .select("created_at")
      .eq("phone", normalizedPhone)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (latestErr) {
      console.error("[send-otp] Database error reading rate limit:", latestErr);
      throw new Error("Failed to check rate limit cooldown.");
    }

    if (latestRecord && latestRecord.created_at) {
      const elapsedMs = now - new Date(latestRecord.created_at).getTime();
      const cooldownMs = RESEND_COOLDOWN_SECONDS * 1000;
      if (elapsedMs < cooldownMs) {
        const remainingSeconds = Math.ceil((cooldownMs - elapsedMs) / 1000);
        return new Response(
          JSON.stringify({
            success: false,
            error: "RATE_LIMITED",
            message: `Please wait ${remainingSeconds} seconds before requesting another verification code.`,
            resend_after: remainingSeconds,
          }),
          {
            status: 429,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

    // B. Hourly Dispatch Cap (Max 5 sends per hour per phone)
    const oneHourAgo = new Date(now - 3600_000).toISOString();
    const { count: hourlyCount, error: countErr } = await supabase
      .from("phone_verification_otps")
      .select("*", { count: "exact", head: true })
      .eq("phone", normalizedPhone)
      .gte("created_at", oneHourAgo);

    if (countErr) {
      console.error("[send-otp] Database error counting hourly requests:", countErr);
      throw new Error("Failed to check hourly rate limit.");
    }

    if ((hourlyCount ?? 0) >= HOURLY_RATE_LIMIT) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "HOURLY_LIMIT_EXCEEDED",
          message: "Too many verification requests for this phone number. Please try again in an hour.",
        }),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 7. Cryptographically Secure OTP Generation & Hashing
    const otp = generateSecureOtp();
    const salt = generateSecureSalt();
    const otpHash = await hashOtp(otp, salt, normalizedPhone);
    const requestId = crypto.randomUUID();
    const expiresAt = new Date(now + OTP_LIFETIME_SECONDS * 1000).toISOString();

    // 8. Store Challenge in Database
    const { error: insertErr } = await supabase.from("phone_verification_otps").insert({
      phone: normalizedPhone,
      otp_hash: otpHash,
      salt: salt,
      request_id: requestId,
      attempts: 0,
      max_attempts: 3,
      expires_at: expiresAt,
      consumed: false,
    });

    if (insertErr) {
      console.error("[send-otp] Failed to persist OTP challenge:", insertErr);
      throw new Error("Failed to record verification challenge.");
    }

    // 9. Dispatch via SMS Transport Boundary
    let smsTransport;
    try {
      smsTransport = getSmsTransport();
    } catch (configErr: any) {
      console.error("[send-otp] Transport configuration error:", configErr.message);
      await supabase.from("phone_verification_otps").delete().eq("request_id", requestId);
      return new Response(
        JSON.stringify({
          success: false,
          error: "SMS_GATEWAY_CONFIG_ERROR",
          message: "SMS service configuration error.",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const smsMessage = `Your CivicFix verification code is ${otp}. It expires in 5 minutes.`;
    const transportResult = await smsTransport.sendSms(normalizedPhone, smsMessage, requestId);

    if (!transportResult.success) {
      console.error(
        `[send-otp] SMS dispatch failed for ${maskPhoneNumber(normalizedPhone)} [ReqId: ${requestId}]: ${transportResult.errorCode || "DISPATCH_FAILED"}`
      );

      // Invalidate/prune the challenge so the citizen is not left with an undelivered active OTP or locked out by cooldown
      await supabase.from("phone_verification_otps").delete().eq("request_id", requestId);

      return new Response(
        JSON.stringify({
          success: false,
          error: transportResult.errorCode || "SMS_GATEWAY_UNAVAILABLE",
          message: transportResult.error || "SMS delivery service is currently unavailable. Please try again shortly.",
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `[send-otp] OTP challenge created and dispatched for UID ${callerUid} (${maskPhoneNumber(normalizedPhone)}) [ReqId: ${requestId}]`
    );

    // 10. Clean Production Response (OTP is NEVER returned in response)
    return new Response(
      JSON.stringify({
        success: true,
        request_id: requestId,
        expires_in: OTP_LIFETIME_SECONDS,
        resend_after: RESEND_COOLDOWN_SECONDS,
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
