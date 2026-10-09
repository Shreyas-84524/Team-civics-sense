import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { verifyFirebaseIdToken } from "../_shared/firebase-auth.ts";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const BUCKET_NAME = "complaint-evidence";
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB
const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];

function base64ToBytes(b64: string): Uint8Array {
  // Strip optional data URI prefix (e.g. data:image/jpeg;base64,...)
  const cleanB64 = b64.replace(/^data:image\/[a-z]+;base64,/, "");
  const binaryString = atob(cleanB64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

function getExtensionFromMime(mime: string): string {
  switch (mime.toLowerCase()) {
    case "image/jpeg":
    case "image/jpg":
      return ".jpg";
    case "image/png":
      return ".png";
    case "image/webp":
      return ".webp";
    default:
      return ".jpg";
  }
}

function validateMagicBytes(bytes: Uint8Array, mime: string): boolean {
  if (bytes.length < 4) return false;
  if (mime === "image/jpeg" || mime === "image/jpg") {
    return bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  }
  if (mime === "image/png") {
    return bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47;
  }
  if (mime === "image/webp") {
    if (bytes.length < 12) return false;
    return (
      bytes[0] === 0x52 &&
      bytes[1] === 0x49 &&
      bytes[2] === 0x46 &&
      bytes[3] === 0x46 &&
      bytes[8] === 0x57 &&
      bytes[9] === 0x45 &&
      bytes[10] === 0x42 &&
      bytes[11] === 0x50
    );
  }
  return true;
}

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

  const authenticatedUid = authResult.uid!;

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

  // 5. Handle Action: Delete or Upload
  const action = (body.action as string) || "upload";

  // Init Supabase Service Role Client
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  if (action === "delete") {
    const storagePath = body.storagePath as string;
    if (!storagePath || typeof storagePath !== "string" || storagePath.includes("..")) {
      return new Response(
        JSON.stringify({ success: false, error: "INVALID_PATH", message: "Invalid storage path." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    const cleanPath = storagePath.replace(/^complaint-evidence\//, "").replace(/^\/+/, "");
    const { error: delError } = await supabase.storage.from(BUCKET_NAME).remove([cleanPath]);
    if (delError) {
      return new Response(
        JSON.stringify({ success: false, error: "STORAGE_ERROR", message: delError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    return new Response(
      JSON.stringify({ success: true, message: `Deleted ${cleanPath}` }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Handle Upload
  const ticketNumber = (body.ticketNumber || body.ticket_number || body.complaintId) as string;
  const rawIndex = body.evidenceIndex ?? body.evidence_index ?? 1;
  const evidenceIndex = typeof rawIndex === "number" ? rawIndex : parseInt(String(rawIndex), 10) || 1;
  const rawMime = (body.mimeType || body.mime_type || "image/jpeg") as string;
  const mimeType = rawMime.toLowerCase().trim();
  const originalFileName = (body.originalFileName || body.fileName || `evidence_${evidenceIndex}.jpg`) as string;
  const fileBytesBase64 = (body.fileBytes || body.fileBytesBase64 || body.file_data) as string;

  // Validate Ticket Format: prevent path traversal or arbitrary paths
  if (!ticketNumber || typeof ticketNumber !== "string" || !/^[A-Za-z0-9_-]{3,64}$/.test(ticketNumber)) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "INVALID_TICKET",
        message: "Invalid ticket format. Expected alphanumeric ticket reference (e.g. CF-2026-000026).",
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Validate MIME
  if (!ALLOWED_MIME_TYPES.includes(mimeType)) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "UNSUPPORTED_MEDIA_TYPE",
        message: `MIME type '${mimeType}' is not supported. Allowed: ${ALLOWED_MIME_TYPES.join(", ")}.`,
      }),
      { status: 415, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Validate File Bytes
  if (!fileBytesBase64 || typeof fileBytesBase64 !== "string") {
    return new Response(
      JSON.stringify({
        success: false,
        error: "EMPTY_FILE",
        message: "Missing image file data (base64 string required).",
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  let fileBytes: Uint8Array;
  try {
    fileBytes = base64ToBytes(fileBytesBase64);
  } catch (decodeErr) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "INVALID_BASE64",
        message: `Failed to decode base64 file data: ${decodeErr}`,
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Validate Size
  if (fileBytes.length === 0) {
    return new Response(
      JSON.stringify({ success: false, error: "EMPTY_FILE", message: "File is empty (0 bytes)." }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  if (fileBytes.length > MAX_FILE_SIZE) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "FILE_TOO_LARGE",
        message: `File size (${(fileBytes.length / (1024 * 1024)).toFixed(2)} MB) exceeds maximum limit of 10 MB.`,
      }),
      { status: 413, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Validate Magic Header Bytes
  if (!validateMagicBytes(fileBytes, mimeType)) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "INVALID_FILE_SIGNATURE",
        message: `File header bytes do not match declared MIME type '${mimeType}'.`,
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 6. Generate Deterministic Object Storage Path
  // Format: {ticketNumber}/{ticketNumber}_evidence_{paddedIndex}{ext}
  const paddedIndex = String(evidenceIndex).padStart(2, "0");
  const ext = getExtensionFromMime(mimeType);
  const cleanOriginalName = originalFileName.replace(/[^a-zA-Z0-9._-]/g, "_");
  const storagePath = `${ticketNumber}/${ticketNumber}_evidence_${paddedIndex}${ext}`;

  // 7. Upload to Supabase Storage via Service Role (upsert: true for idempotency)
  const { error: uploadError } = await supabase.storage.from(BUCKET_NAME).upload(storagePath, fileBytes, {
    contentType: mimeType,
    upsert: true,
    metadata: {
      uploaderId: authenticatedUid,
      ticketNumber,
      evidenceIndex: String(evidenceIndex),
      originalFileName: cleanOriginalName,
      uploadedAt: new Date().toISOString(),
    },
  });

  if (uploadError) {
    console.error(`[UploadEvidence] Storage error for ${storagePath}:`, uploadError);
    return new Response(
      JSON.stringify({
        success: false,
        error: "STORAGE_UPLOAD_ERROR",
        message: `Failed to upload evidence to Supabase Storage: ${uploadError.message}`,
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 8. Generate short-lived signed URL for immediate client feedback (TTL: 3600 seconds)
  const { data: signedData, error: signError } = await supabase.storage
    .from(BUCKET_NAME)
    .createSignedUrl(storagePath, 3600);

  if (signError) {
    console.warn(`[UploadEvidence] Warning: Signed URL creation notice for ${storagePath}:`, signError);
  }

  // 9. Return Structured Result
  return new Response(
    JSON.stringify({
      success: true,
      bucket: BUCKET_NAME,
      storagePath,
      originalFileName: cleanOriginalName,
      mimeType,
      evidenceIndex,
      sizeInBytes: fileBytes.length,
      signedUrl: signedData?.signedUrl ?? null,
      uploadedAt: new Date().toISOString(),
    }),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
});
