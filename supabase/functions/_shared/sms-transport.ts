/**
 * CivicFix SMS Transport Boundary
 *
 * Defines the clean abstraction separating OTP business logic from physical SMS delivery.
 * - SMS_TRANSPORT=mock (default): MockSmsTransport simulates SMS dispatch without hitting external cell networks.
 * - SMS_TRANSPORT=gateway: GatewaySmsTransport communicates with the SMS-Gateway-Free Android phone via HTTPS ingress.
 */

export interface SmsTransportResult {
  success: boolean;
  gatewayMessageId?: string;
  gatewayStatus?: string; // e.g. "PENDING"
  durationMs?: number;
  error?: string;
  errorCode?: string; // e.g. "SMS_GATEWAY_UNAVAILABLE", "SMS_GATEWAY_TIMEOUT", "SMS_GATEWAY_AUTH_ERROR"
}

export interface SmsTransport {
  sendSms(phoneNumber: string, message: string, requestId: string): Promise<SmsTransportResult>;
}

export const DEFAULT_GATEWAY_TIMEOUT_MS = 7000; // 7 seconds timeout (strict 5-8s boundary)

/**
 * Sanitizes and masks an E.164 phone number for secure logging.
 * Example: +919876543210 -> +9198****10
 */
export function maskPhoneNumber(phoneNumber: string): string {
  if (!phoneNumber || typeof phoneNumber !== "string") {
    return "[invalid_phone]";
  }
  const clean = phoneNumber.trim();
  if (clean.length <= 6) {
    return clean.slice(0, 2) + "****";
  }
  if (clean.startsWith("+91") && clean.length === 13) {
    return `+91${clean.slice(3, 5)}****${clean.slice(-2)}`;
  }
  if (clean.length === 10) {
    return `${clean.slice(0, 4)}****${clean.slice(-2)}`;
  }
  return `${clean.slice(0, 2)}****${clean.slice(-2)}`;
}

/**
 * Phase 3 & Test Transport: Simulates SMS dispatch without hitting external cell networks.
 * Strictly avoids logging plaintext OTP codes.
 */
export class MockSmsTransport implements SmsTransport {
  private _lastDispatched: {
    phone: string;
    requestId: string;
    timestamp: number;
    maskedPhone: string;
  } | null = null;

  async sendSms(phoneNumber: string, message: string, requestId: string): Promise<SmsTransportResult> {
    const start = Date.now();
    const masked = maskPhoneNumber(phoneNumber);

    this._lastDispatched = {
      phone: phoneNumber,
      requestId,
      timestamp: start,
      maskedPhone: masked,
    };

    console.log(
      `[MockSmsTransport] SMS dispatch simulated for recipient: ${masked} (RequestId: ${requestId})`
    );

    return {
      success: true,
      gatewayMessageId: `mock_gw_${requestId.replace(/-/g, "").slice(0, 12)}`,
      gatewayStatus: "PENDING",
      durationMs: Date.now() - start,
    };
  }

  get lastDispatched() {
    return this._lastDispatched;
  }
}

/**
 * Phase 4 Transport: Communicates with the SMS-Gateway-Free Android Phone via HTTPS ingress.
 *
 * Requirements:
 * - Environment variables: SMS_GATEWAY_URL, SMS_GATEWAY_API_KEY
 * - Target: POST {SMS_GATEWAY_URL}/api/send
 * - Strict 5-8s timeout via AbortController
 * - Validates PENDING queue acceptance
 * - Never leaks API key, gateway URL, or raw network errors
 */
export class GatewaySmsTransport implements SmsTransport {
  private readonly gatewayUrl: string;
  private readonly apiKey: string;
  private readonly timeoutMs: number;

  constructor(gatewayUrl: string, apiKey: string, timeoutMs: number = DEFAULT_GATEWAY_TIMEOUT_MS) {
    this.gatewayUrl = gatewayUrl.replace(/\/+$/, "");
    this.apiKey = apiKey;
    this.timeoutMs = timeoutMs;
  }

  async sendSms(phoneNumber: string, message: string, requestId: string): Promise<SmsTransportResult> {
    if (!this.gatewayUrl || !this.apiKey) {
      return {
        success: false,
        error: "SMS Gateway is not configured. Missing SMS_GATEWAY_URL or SMS_GATEWAY_API_KEY.",
        errorCode: "SMS_GATEWAY_CONFIG_ERROR",
      };
    }

    const maskedPhone = maskPhoneNumber(phoneNumber);
    const endpoint = `${this.gatewayUrl}/api/send`;
    const startTime = Date.now();

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-API-Key": this.apiKey,
        },
        body: JSON.stringify({
          phone_number: phoneNumber,
          message: message,
          request_id: requestId,
        }),
        signal: controller.signal,
      });

      clearTimeout(timer);
      const durationMs = Date.now() - startTime;

      if (!response.ok) {
        let errorCode = "SMS_GATEWAY_UNAVAILABLE";
        if (response.status === 401 || response.status === 403) {
          errorCode = "SMS_GATEWAY_AUTH_ERROR";
        } else if (response.status === 429) {
          errorCode = "SMS_GATEWAY_RATE_LIMITED";
        } else if (response.status >= 500) {
          errorCode = "SMS_GATEWAY_SERVER_ERROR";
        }

        console.error(
          `[GatewaySmsTransport] Gateway returned HTTP ${response.status} in ${durationMs}ms for ${maskedPhone} [ReqId: ${requestId}]`
        );

        return {
          success: false,
          error: "SMS delivery service is currently unavailable. Please try again shortly.",
          errorCode,
          durationMs,
        };
      }

      let data: any;
      try {
        data = await response.json();
      } catch {
        console.error(
          `[GatewaySmsTransport] Failed to parse JSON response from gateway in ${durationMs}ms for ${maskedPhone} [ReqId: ${requestId}]`
        );
        return {
          success: false,
          error: "Invalid response from SMS gateway.",
          errorCode: "SMS_GATEWAY_INVALID_RESPONSE",
          durationMs,
        };
      }

      if (data && data.success === true) {
        // SMS-Gateway-Free returns sms_id and status "PENDING"
        // IMPORTANT: HTTP 200 / PENDING indicates queue acceptance on Android device, not carrier delivery.
        const smsId = data.sms_id !== undefined ? String(data.sms_id) : (data.request_id || requestId);
        const gatewayStatus = data.status || "PENDING";

        console.log(
          `[GatewaySmsTransport] SMS accepted by gateway (Status: ${gatewayStatus}, SmsId: ${smsId}) in ${durationMs}ms for ${maskedPhone} [ReqId: ${requestId}]`
        );

        return {
          success: true,
          gatewayMessageId: smsId,
          gatewayStatus: gatewayStatus,
          durationMs,
        };
      } else {
        const remoteError = data?.error || data?.message || "Gateway rejected dispatch request.";
        console.warn(
          `[GatewaySmsTransport] Gateway reported dispatch failure in ${durationMs}ms for ${maskedPhone}: ${remoteError} [ReqId: ${requestId}]`
        );
        return {
          success: false,
          error: "SMS dispatch could not be queued by gateway.",
          errorCode: "SMS_GATEWAY_DISPATCH_FAILED",
          durationMs,
        };
      }
    } catch (err: any) {
      clearTimeout(timer);
      const durationMs = Date.now() - startTime;

      if (err.name === "AbortError" || controller.signal.aborted) {
        console.error(
          `[GatewaySmsTransport] Timeout after ${durationMs}ms reaching SMS gateway for ${maskedPhone} [ReqId: ${requestId}]`
        );
        return {
          success: false,
          error: "SMS gateway request timed out. Please try again.",
          errorCode: "SMS_GATEWAY_TIMEOUT",
          durationMs,
        };
      }

      console.error(
        `[GatewaySmsTransport] Network connection error to SMS gateway in ${durationMs}ms for ${maskedPhone} [ReqId: ${requestId}]: ${err.name}`
      );
      return {
        success: false,
        error: "Unable to connect to SMS gateway.",
        errorCode: "SMS_GATEWAY_UNAVAILABLE",
        durationMs,
      };
    }
  }
}

/**
 * Factory resolving the active SMS Transport based on environment configuration.
 *
 * Rules:
 * - SMS_TRANSPORT="gateway": Uses GatewaySmsTransport.
 *   - Requires SMS_GATEWAY_URL and SMS_GATEWAY_API_KEY.
 *   - If either is missing or empty, throws an Error (fails explicitly, NEVER silently falls back to mock).
 * - SMS_TRANSPORT="mock", empty, or unset: Uses MockSmsTransport (default safe behavior).
 * - Any unrecognized value: Throws an Error.
 */
export function getSmsTransport(): SmsTransport {
  const rawMode = Deno.env.get("SMS_TRANSPORT");
  const transportMode = rawMode && rawMode.trim() !== "" ? rawMode.trim().toLowerCase() : "mock";

  if (transportMode === "gateway") {
    const gatewayUrl = Deno.env.get("SMS_GATEWAY_URL");
    const apiKey = Deno.env.get("SMS_GATEWAY_API_KEY");

    if (!gatewayUrl || !apiKey || gatewayUrl.trim() === "" || apiKey.trim() === "") {
      throw new Error(
        "SMS_GATEWAY_CONFIG_ERROR: SMS_TRANSPORT is configured as 'gateway' but SMS_GATEWAY_URL or SMS_GATEWAY_API_KEY is missing or empty."
      );
    }

    return new GatewaySmsTransport(gatewayUrl.trim(), apiKey.trim());
  }

  if (transportMode === "mock") {
    return new MockSmsTransport();
  }

  throw new Error(
    `SMS_TRANSPORT_INVALID: Unrecognized SMS_TRANSPORT '${transportMode}'. Expected 'mock' or 'gateway'.`
  );
}
