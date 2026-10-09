import {
  generateDepartmentPromptList,
  getDepartmentById,
  isValidDepartmentId,
} from './departments';

export interface EvidenceVerificationResult {
  passed: boolean;
  confidence: number;
  reason: string;
  issueType?: string;
  detectedLabels?: string[];
  rawAnalysis?: Record<string, unknown>;
  isTransientFailure?: boolean;
  failureCode?: string;
  attempts?: number;
}

export interface DepartmentVerificationResult {
  passed: boolean;
  verifiedDepartmentId?: string;
  verifiedDepartmentName?: string;
  confidence: number;
  rationale: string;
  isDepartmentConfirmed: boolean;
  isTransientFailure?: boolean;
  failureCode?: string;
  attempts?: number;
}

const GEMINI_MODELS = [
  process.env.GEMINI_MODEL || 'gemini-3.5-flash',
  'gemini-3.8-flash',
  'gemini-3.5-flash-lite',
  'gemini-flash-latest',
];

/**
 * Classifies whether an API failure is transient (infrastructure error eligible for retry / human fallback)
 * vs permanent business/validation logic failure.
 */
export function isTransientAiFailure(status: number, errorMsg?: string): boolean {
  if ([408, 429, 500, 502, 503, 504].includes(status)) {
    return true;
  }
  if (!errorMsg) return false;
  const lower = errorMsg.toLowerCase();
  return (
    lower.includes('timeout') ||
    lower.includes('quota') ||
    lower.includes('rate limit') ||
    lower.includes('resource exhausted') ||
    lower.includes('overloaded') ||
    lower.includes('temporarily unavailable') ||
    lower.includes('service unavailable') ||
    lower.includes('econnreset') ||
    lower.includes('etimedout') ||
    lower.includes('fetch failed') ||
    lower.includes('network')
  );
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Robust helper to call Google Gemini API with model fallback, timeout, and auth checking.
 */
async function callGeminiApi(
  apiKey: string,
  prompt: string,
  timeoutMs = 10000
): Promise<{ ok: boolean; status: number; text?: string; json?: any; error?: string }> {
  for (const model of GEMINI_MODELS) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);

      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.1,
          },
        }),
        signal: controller.signal,
      });
      clearTimeout(timer);

      if (response.status === 401 || response.status === 403) {
        const errBody = await response.text();
        console.error(
          `[Gemini Auth Error] API key authentication/permission rejected (status ${response.status}): ${errBody}`
        );
        return { ok: false, status: response.status, error: errBody };
      }

      if (response.status === 404) {
        console.warn(`[Gemini Model] Model "${model}" not found or retired (404). Trying next fallback model...`);
        continue;
      }

      if (!response.ok) {
        const errBody = await response.text();
        console.warn(`[Gemini API Warning] Model "${model}" returned HTTP ${response.status}: ${errBody}`);
        return { ok: false, status: response.status, error: errBody };
      }

      const data = await response.json();
      return { ok: true, status: response.status, json: data };
    } catch (e: any) {
      if (e?.name === 'AbortError') {
        console.error(`[Gemini Timeout] Request to model "${model}" timed out after ${timeoutMs}ms.`);
        return { ok: false, status: 408, error: `Request timed out after ${timeoutMs}ms` };
      }
      console.warn(`[Gemini Network Error] Error contacting ${model}:`, e);
    }
  }
  return { ok: false, status: 503, error: 'All Gemini model candidates exhausted or unreachable' };
}

/**
 * Executes a Gemini API call with bounded exponential backoff retries for transient failures.
 */
export async function callGeminiWithRetry(
  apiKey: string,
  prompt: string,
  maxAttempts = 3,
  baseBackoffMs = 500,
  timeoutMs = 10000
): Promise<{ ok: boolean; status: number; text?: string; json?: any; error?: string; attempts: number; isTransient: boolean }> {
  let lastResult: { ok: boolean; status: number; text?: string; json?: any; error?: string } = {
    ok: false,
    status: 500,
    error: 'Uninitialized',
  };

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    lastResult = await callGeminiApi(apiKey, prompt, timeoutMs);
    if (lastResult.ok) {
      return { ...lastResult, attempts: attempt, isTransient: false };
    }

    const isTransient = isTransientAiFailure(lastResult.status, lastResult.error);
    if (!isTransient || attempt === maxAttempts) {
      return { ...lastResult, attempts: attempt, isTransient };
    }

    // Bounded exponential backoff: 500ms, 1500ms, 3000ms
    const backoffTime = baseBackoffMs * Math.pow(2, attempt - 1);
    console.warn(`[Gemini Retry] Attempt ${attempt} failed with status ${lastResult.status}. Retrying in ${backoffTime}ms...`);
    await sleep(backoffTime);
  }

  return {
    ...lastResult,
    attempts: maxAttempts,
    isTransient: isTransientAiFailure(lastResult.status, lastResult.error),
  };
}

/**
 * Step 1: Gemini Evidence & Authenticity Verification.
 *
 * Verifies whether the uploaded complaint evidence represents a legitimate, real-world civic grievance
 * (e.g., potholes, garbage heaps, broken pipes, open manholes) and is not synthetic, unrelated, or spam.
 */
export async function verifyComplaintEvidence(complaint: {
  title: string;
  description: string;
  category?: { id?: string; name?: string } | string;
  imageUrls?: string[];
}): Promise<EvidenceVerificationResult> {
  const apiKey =
    process.env.GEMINI_API_KEY ||
    process.env.GEMINI_DEPARTMENT_API_KEY;

  const title = complaint.title || '';
  const description = complaint.description || '';
  const categoryName =
    typeof complaint.category === 'object' && complaint.category !== null
      ? complaint.category.name || complaint.category.id || 'General'
      : (complaint.category as string) || 'General';
  const imageUrls = complaint.imageUrls || [];

  // If no API key configured (e.g. local offline test), provide deterministic heuristic check
  if (!apiKey) {
    const isObviousSpam =
      title.toLowerCase().includes('test-invalid-spam') ||
      description.toLowerCase().includes('fake complaint');
    if (isObviousSpam) {
      return {
        passed: false,
        confidence: 0.95,
        reason: 'Flagged as test or invalid civic grievance by automated rules.',
        isTransientFailure: false,
        attempts: 1,
      };
    }
    return {
      passed: true,
      confidence: 0.88,
      reason: 'Automated civic evidence verification passed (offline mode).',
      issueType: categoryName,
      detectedLabels: [categoryName, 'civic_issue'],
      isTransientFailure: false,
      attempts: 1,
    };
  }

  const prompt = `You are the BMC Municipal AI Grievance Evidence Verifier for CivicFix Mumbai.
Analyze the following citizen civic grievance submission:
Title: "${title}"
Description: "${description}"
User Category: "${categoryName}"
Evidence Images: ${JSON.stringify(imageUrls)}

Your task:
1. Determine if this describes and depicts a legitimate municipal civic issue in an urban environment.
2. Flag if the complaint appears to be spam, unrelated imagery, synthetic junk, or commercial advertisement.
3. Respond in JSON with this exact schema:
{
  "isLegitimateCivicIssue": boolean,
  "confidence": number (between 0.0 and 1.0),
  "primaryIssueType": string,
  "reason": string
}`;

  try {
    const apiRes = await callGeminiWithRetry(apiKey, prompt, 3, 500, 10000);

    if (!apiRes.ok || !apiRes.json) {
      console.warn(`[Gemini Step 1] API error after ${apiRes.attempts} attempts: status ${apiRes.status}, error: ${apiRes.error}`);
      return {
        passed: false,
        confidence: 0.0,
        reason: 'Automated evidence verification is temporarily unavailable. Queued for manual departmental review.',
        isTransientFailure: true,
        failureCode: `HTTP_${apiRes.status}`,
        attempts: apiRes.attempts,
      };
    }

    const candidateText = apiRes.json.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!candidateText) {
      return {
        passed: false,
        confidence: 0.0,
        reason: 'Automated evidence verification response was empty. Queued for manual departmental review.',
        isTransientFailure: true,
        failureCode: 'EMPTY_AI_RESPONSE',
        attempts: apiRes.attempts,
      };
    }

    const parsed = JSON.parse(candidateText);
    const isLegitimate = parsed.isLegitimateCivicIssue === true;
    const confidence = parsed.confidence ?? (isLegitimate ? 0.85 : 0.2);
    const passed = isLegitimate && confidence >= 0.5;

    return {
      passed,
      confidence,
      reason: parsed.reason || (passed ? 'Valid civic issue verified.' : 'Invalid or unverified civic issue evidence.'),
      issueType: parsed.primaryIssueType,
      isTransientFailure: false, // Class A: Explicit business decision returned by AI
      attempts: apiRes.attempts,
    };
  } catch (error) {
    console.error('[Gemini Step 1] Evidence verification exception:', error);
    return {
      passed: false,
      confidence: 0.0,
      reason: 'Automated evidence verification encountered an unexpected error. Queued for manual departmental review.',
      isTransientFailure: true,
      failureCode: 'EXCEPTION',
      attempts: 3,
    };
  }
}

/**
 * Step 2: Gemini Department Verification.
 *
 * Evaluates the complaint against the CLOSED CANONICAL 18 BMC DEPARTMENTS ALLOWLIST.
 * Performs strict server-side validation to reject any hallucinated department IDs.
 */
export async function verifyComplaintDepartment(
  complaint: {
    title: string;
    description: string;
    category?: { id?: string; name?: string } | string;
    imageUrls?: string[];
  },
  evidenceResult: EvidenceVerificationResult
): Promise<DepartmentVerificationResult> {
  // MUST use trusted backend secret GEMINI_DEPARTMENT_API_KEY
  const apiKey =
    process.env.GEMINI_DEPARTMENT_API_KEY ||
    process.env.GEMINI_API_KEY;

  const title = complaint.title || '';
  const description = complaint.description || '';
  const categoryId =
    typeof complaint.category === 'object' && complaint.category !== null
      ? complaint.category.id || 'solid_waste_management'
      : (complaint.category as string) || 'solid_waste_management';

  const deptPromptList = generateDepartmentPromptList();

  // If no API key configured (e.g. unit testing), use deterministic allowlist lookup
  if (!apiKey) {
    const matchedDept = getDepartmentById(categoryId) || getDepartmentById('solid_waste_management');
    return {
      passed: true,
      verifiedDepartmentId: matchedDept?.departmentId || 'solid_waste_management',
      verifiedDepartmentName: matchedDept?.displayName || 'Solid Waste Management',
      confidence: 0.9,
      rationale: 'Deterministic canonical department matching (offline mode).',
      isDepartmentConfirmed: true,
      isTransientFailure: false,
      attempts: 1,
    };
  }

  const prompt = `You are the BMC Municipal Department Routing Classifier for CivicFix Mumbai.
A complaint has passed initial evidence authenticity checks.

Citizen Grievance Details:
Title: "${title}"
Description: "${description}"
User-Selected Category: "${categoryId}"
Evidence Issue Type: "${evidenceResult.issueType || 'N/A'}"

CLOSED ALLOWLIST OF THE 18 AUTHORITATIVE BMC DEPARTMENTS:
${deptPromptList}

STRICT INSTRUCTIONS:
1. You MUST select EXACTLY ONE department from the 18 allowed department IDs above.
2. You MUST NEVER invent, hypothesize, or return any department ID not present in the list.
3. Validate if the user's selected category is correct, or reassign to the correct BMC department from the 18 allowed IDs.
4. Output JSON ONLY with this exact schema:
{
  "departmentId": string (must exactly match one of the 18 IDs above),
  "confidence": number (between 0.0 and 1.0),
  "rationale": string
}`;

  try {
    const apiRes = await callGeminiWithRetry(apiKey, prompt, 3, 500, 10000);

    if (!apiRes.ok || !apiRes.json) {
      console.warn(`[Gemini Step 2] API error after ${apiRes.attempts} attempts: status ${apiRes.status}, error: ${apiRes.error}`);
      return {
        passed: false,
        confidence: 0.0,
        rationale: 'Automated department classification is temporarily unavailable. Queued for manual departmental review.',
        isDepartmentConfirmed: false,
        isTransientFailure: true,
        failureCode: `HTTP_${apiRes.status}`,
        attempts: apiRes.attempts,
      };
    }

    const candidateText = apiRes.json.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!candidateText) {
      return {
        passed: false,
        confidence: 0.0,
        rationale: 'Automated department classification response was empty. Queued for manual departmental review.',
        isDepartmentConfirmed: false,
        isTransientFailure: true,
        failureCode: 'EMPTY_AI_RESPONSE',
        attempts: apiRes.attempts,
      };
    }

    const parsed = JSON.parse(candidateText);
    const returnedDeptId = (parsed.departmentId || '').trim().toLowerCase();

    // CRITICAL SERVER-SIDE GATING: Reject hallucinated or non-allowlisted department IDs
    if (!isValidDepartmentId(returnedDeptId)) {
      console.error(
        `[Gemini Step 2] Security / Validation Rejection: Model returned invalid departmentId "${returnedDeptId}" not in 18 canonical BMC allowlist.`
      );
      return {
        passed: false,
        confidence: 0.0,
        rationale: `AI returned unapproved department ID "${returnedDeptId}". Must be strictly within the 18 BMC departments. Queued for manual departmental review.`,
        isDepartmentConfirmed: false,
        isTransientFailure: true, // Send to human review rather than blocking complaint
        failureCode: 'INVALID_AI_DEPARTMENT_OUTPUT',
        attempts: apiRes.attempts,
      };
    }

    const canonicalDept = getDepartmentById(returnedDeptId)!;

    return {
      passed: true,
      verifiedDepartmentId: canonicalDept.departmentId,
      verifiedDepartmentName: canonicalDept.displayName,
      confidence: parsed.confidence ?? 0.9,
      rationale: parsed.rationale || `Verified for ${canonicalDept.displayName}.`,
      isDepartmentConfirmed: true,
      isTransientFailure: false,
      attempts: apiRes.attempts,
    };
  } catch (error) {
    console.error('[Gemini Step 2] Department verification error:', error);
    return {
      passed: false,
      confidence: 0.0,
      rationale: 'Department verification encountered an error. Queued for manual departmental review.',
      isDepartmentConfirmed: false,
      isTransientFailure: true,
      failureCode: 'EXCEPTION',
      attempts: 3,
    };
  }
}
