import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  normalizeIndianPhone,
  hashOtp,
  constantTimeCompare,
} from "../_shared/otp-security.ts";
import { verifyFirebaseIdToken } from "../_shared/firebase-auth.ts";
import { claimPhoneAndVerifyCitizen } from "../_shared/firestore-client.ts";
import { maskPhoneNumber } from "../_shared/sms-transport.ts";

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

  // 5. Initialize Supabase Database Client (service_role)
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    console.error("[verify-otp] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.");
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
    // 6. Fetch Challenge Record by request_id
    const { data: record, error: fetchErr } = await supabase
      .from("phone_verification_otps")
      .select("*")
      .eq("request_id", body.request_id.trim())
      .maybeSingle();

    if (fetchErr) {
      console.error("[verify-otp] Database error reading challenge:", fetchErr);
      throw new Error("Failed to query verification challenge.");
    }

    if (!record) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "CHALLENGE_NOT_FOUND",
          message: "No verification challenge found for the provided request ID.",
        }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 7. Validate Phone Number Match
    if (record.phone !== normalizedPhone) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "CHALLENGE_MISMATCH",
          message: "The provided phone number does not match this verification request.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 8. Validate Challenge State: Already Consumed
    if (record.consumed) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "OTP_ALREADY_USED",
          message: "This verification code has already been used. Please request a new one.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 9. Validate Challenge State: Expired
    const expiresAtMs = new Date(record.expires_at).getTime();
    if (expiresAtMs <= now) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "OTP_EXPIRED",
          message: "This verification code has expired. Please request a new one.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 10. Validate Challenge State: Max Attempts Reached
    if (record.attempts >= record.max_attempts) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "MAX_ATTEMPTS_EXCEEDED",
          message: "Maximum verification attempts exceeded. Please request a new code.",
          remaining_attempts: 0,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 11. Cryptographic Hash Comparison
    const candidateHash = await hashOtp(body.otp, record.salt, normalizedPhone);
    const isMatch = constantTimeCompare(candidateHash, record.otp_hash);

    if (!isMatch) {
      const newAttempts = record.attempts + 1;
      const remaining = Math.max(0, record.max_attempts - newAttempts);

      const { error: updateAttemptsErr } = await supabase
        .from("phone_verification_otps")
        .update({ attempts: newAttempts })
        .eq("id", record.id);

      if (updateAttemptsErr) {
        console.error("[verify-otp] Failed to increment attempts:", updateAttemptsErr);
      }

      if (newAttempts >= record.max_attempts) {
        return new Response(
          JSON.stringify({
            success: false,
            error: "MAX_ATTEMPTS_EXCEEDED",
            message: "Incorrect verification code. Maximum attempts reached. Please request a new code.",
            remaining_attempts: 0,
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({
          success: false,
          error: "INVALID_OTP",
          message: "Incorrect verification code.",
          remaining_attempts: remaining,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 12. Correct OTP: Mark Challenge as Consumed
    const consumedAt = new Date().toISOString();
    const { error: consumeErr } = await supabase
      .from("phone_verification_otps")
      .update({
        consumed: true,
        consumed_at: consumedAt,
      })
      .eq("id", record.id);

    if (consumeErr) {
      console.error("[verify-otp] Failed to mark challenge as consumed:", consumeErr);
      throw new Error("Failed to finalize OTP challenge state.");
    }

    // 13. Authoritative Firestore Identity Sync (1 Phone = 1 Citizen Account)
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

    // 14. Clean Production Response
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
