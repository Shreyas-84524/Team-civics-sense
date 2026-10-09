/**
 * CivicFix — Global OTP Service Client Wrapper
 *
 * Provides typed, resilient HTTP communication between CivicFix Supabase Edge Functions
 * and the central Global OTP Platform (https://global-otp-service.vercel.app).
 *
 * Security Invariants:
 * - Never logs or exposes raw API keys.
 * - Enforces timeout via AbortController.
 * - Masks phone numbers in all log telemetry.
 * - Transparently handles error status code mapping.
 */

export interface SendOtpParams {
  phoneNumber: string;
  idempotencyKey?: string;
  metadata?: Record<string, unknown>;
}

export interface SendOtpResponse {
  success: boolean;
  requestId?: string;
  cooldownSeconds?: number;
  expiresAt?: string;
  error?: string;
  message?: string;
}

export interface VerifyOtpParams {
  phoneNumber: string;
  requestId: string;
  otp: string;
}

export interface VerifyOtpResponse {
  success: boolean;
  verified?: boolean;
  error?: string;
  message?: string;
  remainingAttempts?: number;
}

export class GlobalOtpClient {
  private readonly baseUrl: string;
  private readonly projectKey: string;
  private readonly timeoutMs: number;

  constructor(baseUrl?: string, projectKey?: string, timeoutMs = 8000) {
    this.baseUrl = (baseUrl || Deno.env.get("GLOBAL_OTP_BASE_URL") || "https://global-otp-service.vercel.app").replace(/\/+$/, "");
    this.projectKey = projectKey || Deno.env.get("GLOBAL_OTP_PROJECT_KEY") || "";
    this.timeoutMs = timeoutMs;

    if (!this.projectKey) {
      console.warn("[GlobalOtpClient] WARNING: GLOBAL_OTP_PROJECT_KEY is not configured in environment.");
    }
  }

  /**
   * Helper to mask phone numbers for safe logging.
   */
  private maskPhone(phone: string): string {
    if (!phone || phone.length < 6) return "***";
    const prefix = phone.substring(0, phone.length - 6);
    const suffix = phone.substring(phone.length - 2);
    return `${prefix}****${suffix}`;
  }

  /**
   * Dispatches an OTP challenge request to the Global OTP Backend.
   */
  async sendOtp(params: SendOtpParams): Promise<SendOtpResponse> {
    const endpoint = `${this.baseUrl}/api/v1/otp/send`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      "X-Project-Key": this.projectKey,
    };

    if (params.idempotencyKey) {
      headers["Idempotency-Key"] = params.idempotencyKey;
    }

    const payload = {
      phone_number: params.phoneNumber,
      metadata: params.metadata,
    };

    try {
      console.log(`[GlobalOtpClient] Dispatching send-otp for ${this.maskPhone(params.phoneNumber)} to Global OTP API...`);
      const response = await fetch(endpoint, {
        method: "POST",
        headers,
        body: JSON.stringify(payload),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        const errCode = typeof data.error === "object" ? data.error.code : data.error;
        const errMsg = typeof data.error === "object" ? data.error.message : data.message;
        console.warn(`[GlobalOtpClient] Global OTP returned HTTP ${response.status}: ${errCode || response.statusText}`);
        return {
          success: false,
          error: errCode || "GLOBAL_OTP_ERROR",
          message: errMsg || `Global OTP service error (${response.status})`,
        };
      }

      const requestId = data.request_id || data.requestId || data.challenge_id || data.data?.challenge_id;
      const cooldownSec = data.resend_after ?? data.cooldown_seconds ?? data.cooldownSeconds ?? data.data?.retry_after_seconds ?? 30;
      const expiresInSec = data.expires_in ?? data.expiresIn ?? data.data?.expires_in ?? 300;
      const expiresAtIso = data.expires_at || data.expiresAt || new Date(Date.now() + expiresInSec * 1000).toISOString();

      return {
        success: true,
        requestId,
        cooldownSeconds: cooldownSec,
        expiresAt: expiresAtIso,
        message: data.message || "Verification code dispatched successfully.",
      };
    } catch (err: any) {
      clearTimeout(timeoutId);
      if (err.name === "AbortError") {
        console.error(`[GlobalOtpClient] Request timed out after ${this.timeoutMs}ms reaching Global OTP service.`);
        return {
          success: false,
          error: "GATEWAY_TIMEOUT",
          message: "Verification service timed out. Please try again.",
        };
      }

      console.error(`[GlobalOtpClient] Network error connecting to Global OTP service:`, err.message);
      return {
        success: false,
        error: "NETWORK_ERROR",
        message: "Unable to reach verification service. Please try again.",
      };
    }
  }

  /**
   * Submits an OTP verification request to the Global OTP Backend.
   */
  async verifyOtp(params: VerifyOtpParams): Promise<VerifyOtpResponse> {
    const endpoint = `${this.baseUrl}/api/v1/otp/verify`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      "X-Project-Key": this.projectKey,
    };

    const payload = {
      phone_number: params.phoneNumber,
      request_id: params.requestId,
      challenge_id: params.requestId,
      otp: params.otp,
    };

    try {
      console.log(`[GlobalOtpClient] Submitting verify-otp for ${this.maskPhone(params.phoneNumber)} (ReqId: ${params.requestId})...`);
      const response = await fetch(endpoint, {
        method: "POST",
        headers,
        body: JSON.stringify(payload),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        const errCode = typeof data.error === "object" ? data.error.code : data.error;
        const errMsg = typeof data.error === "object" ? data.error.message : data.message;
        const remainingAttempts = typeof data.error === "object"
          ? data.error.attempts_remaining
          : (data.remaining_attempts ?? data.remainingAttempts ?? data.attempts_remaining);

        console.warn(`[GlobalOtpClient] Global OTP verify returned HTTP ${response.status}: ${errCode || response.statusText}`);
        return {
          success: false,
          verified: false,
          error: errCode || "VERIFICATION_FAILED",
          message: errMsg || `Verification failed (${response.status})`,
          remainingAttempts,
        };
      }

      return {
        success: true,
        verified: data.verified === true || data.data?.verified === true,
        remainingAttempts: data.remaining_attempts ?? data.remainingAttempts,
        message: data.message || "Phone number verified successfully.",
      };
    } catch (err: any) {
      clearTimeout(timeoutId);
      if (err.name === "AbortError") {
        console.error(`[GlobalOtpClient] Verify request timed out after ${this.timeoutMs}ms.`);
        return {
          success: false,
          error: "GATEWAY_TIMEOUT",
          message: "Verification service timed out. Please try again.",
        };
      }

      console.error(`[GlobalOtpClient] Network error connecting to Global OTP verify:`, err.message);
      return {
        success: false,
        error: "NETWORK_ERROR",
        message: "Unable to reach verification service. Please try again.",
      };
    }
  }
}
