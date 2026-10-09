import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { verifyFirebaseIdToken } from "../_shared/firebase-auth.ts";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const BUCKET_NAME = "complaint-evidence";
const DEFAULT_EXPIRY_SECONDS = 3600; // 1 hour (30-60 min recommended)
const MIN_EXPIRY_SECONDS = 60;
const MAX_EXPIRY_SECONDS = 86400; // 24 hours

Deno.serve(async (req: Request) => {
  // 1. CORS Preflight
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
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
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
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const rawToken = authHeader.substring(7).trim();
  const authResult = await verifyFirebaseIdToken(rawToken);
  if (!authResult.valid) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "UNAUTHORIZED",
        message: authResult.error || "Invalid or expired Firebase ID token.",
      }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const _authenticatedUid = authResult.uid!;

  // 4. Parse Request Body
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({
        success: false,
        error: "BAD_REQUEST",
        message: "Malformed JSON request body.",
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const rawStoragePath = (body.storagePath || body.storage_path || body.path) as string;
  const rawExpiresIn = body.expiresIn ?? body.expires_in ?? DEFAULT_EXPIRY_SECONDS;
  const expiresIn = Math.max(
    MIN_EXPIRY_SECONDS,
    Math.min(MAX_EXPIRY_SECONDS, typeof rawExpiresIn === "number" ? rawExpiresIn : parseInt(String(rawExpiresIn), 10) || DEFAULT_EXPIRY_SECONDS)
  );

  if (!rawStoragePath || typeof rawStoragePath !== "string") {
    return new Response(
      JSON.stringify({
        success: false,
        error: "MISSING_STORAGE_PATH",
        message: "storagePath is required.",
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Clean path & prevent directory traversal
  let cleanPath = rawStoragePath.trim();
  if (cleanPath.startsWith("complaint-evidence/")) {
    cleanPath = cleanPath.substring("complaint-evidence/".length);
  }
  cleanPath = cleanPath.replace(/^\/+/, "");

  if (cleanPath.includes("..") || cleanPath.includes("//") || cleanPath.includes("\\")) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "INVALID_PATH",
        message: "Path contains illegal characters or directory traversal attempts.",
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 5. Init Supabase Service Role Client & Generate Signed URL
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  const { data: signedData, error: signError } = await supabase.storage
    .from(BUCKET_NAME)
    .createSignedUrl(cleanPath, expiresIn);

  if (signError || !signedData?.signedUrl) {
    console.error(`[GetEvidenceUrl] Failed to sign URL for ${cleanPath}:`, signError);
    return new Response(
      JSON.stringify({
        success: false,
        error: "SIGNED_URL_ERROR",
        message: signError?.message ?? "Could not generate signed URL for evidence object.",
      }),
      { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const expiresAt = new Date(Date.now() + expiresIn * 1000).toISOString();

  return new Response(
    JSON.stringify({
      success: true,
      bucket: BUCKET_NAME,
      storagePath: cleanPath,
      signedUrl: signedData.signedUrl,
      expiresIn,
      expiresAt,
    }),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
});
