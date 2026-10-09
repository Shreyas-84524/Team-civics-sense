import * as crypto from 'crypto';
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

export const SUPPORTED_LANGUAGES = ['en', 'hi', 'mr'] as const;
export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];

export const CURRENT_TRANSLATION_VERSION = 1;
export const MAX_TRANSLATABLE_LENGTH = 5000;

export interface TranslationInput {
  text: string;
  sourceLanguage?: string;
  targetLanguage: string;
  contentType?: string;
  contentId?: string;
  fieldName?: string;
  translationVersion?: number;
}

export interface TranslationOutput {
  originalText: string;
  translatedText: string;
  sourceLanguage: string;
  targetLanguage: string;
  provider: string;
  translatedAt: string;
  isCached: boolean;
  confidence?: number;
  sourceHash?: string;
}

/**
 * Validates whether a language code is within the strict CivicFix allowlist (en, hi, mr).
 */
export function isSupportedLanguage(lang?: string | null): lang is SupportedLanguage {
  if (!lang) return false;
  return (SUPPORTED_LANGUAGES as readonly string[]).includes(lang.trim().toLowerCase());
}

/**
 * Computes deterministic SHA-256 hash for a given text string.
 */
export function computeSourceHash(text: string): string {
  return crypto.createHash('sha256').update(text.trim()).digest('hex');
}

/**
 * Computes deterministic, privacy-conscious Firestore document ID for persistent translation cache.
 */
export function computeCacheDocId(params: {
  contentType: string;
  sourceHash: string;
  sourceLanguage: string;
  targetLanguage: string;
  version: number;
}): string {
  const seed = `${params.contentType}:${params.sourceHash}:${params.sourceLanguage}:${params.targetLanguage}:v${params.version}`;
  return crypto.createHash('sha256').update(seed).digest('hex');
}

/**
 * Approved compact civic terminology glossary for Mumbai municipal grievances.
 */
export const CIVIC_GLOSSARY: Record<string, { hi: string; mr: string; en: string }> = {
  complaint: { en: 'Complaint / Grievance', hi: 'शिकायत', mr: 'तक्रार' },
  ward: { en: 'Ward', hi: 'वार्ड', mr: 'प्रभाग' },
  department: { en: 'Department', hi: 'विभाग', mr: 'विभाग' },
  evidence: { en: 'Evidence / Proof', hi: 'सबूत', mr: 'पुरावा' },
  resolution: { en: 'Resolution', hi: 'समाधान', mr: 'निवारण' },
  rework: { en: 'Rework / Reopened', hi: 'पुनः कार्य', mr: 'पुनर्कार्य' },
  verification: { en: 'Verification', hi: 'सत्यापन', mr: 'पडताळणी' },
  pothole: { en: 'Pothole', hi: 'गड्ढा', mr: 'खड्डा' },
  waterLeakage: { en: 'Water Leakage', hi: 'पानी का रिसाव', mr: 'पाण्याची गळती' },
  garbageOverflow: { en: 'Garbage Overflow', hi: 'कचरा ओवरफ्लो', mr: 'कचऱ्याचा ढीग' },
  sewageOverflow: { en: 'Sewage Overflow', hi: 'सीवेज ओवरफ्लो', mr: 'सांडपाणी निचरा' },
  streetlight: { en: 'Streetlight', hi: 'स्ट्रीट लाइट', mr: 'पथदिवा' },
  pipeline: { en: 'Pipeline', hi: 'पाइपलाइन', mr: 'जलवाहिनी' },
};

/**
 * Generates a compact glossary prompt string for the requested target language.
 */
export function generateGlossaryPrompt(targetLang: SupportedLanguage): string {
  const lines: string[] = [];
  for (const [key, terms] of Object.entries(CIVIC_GLOSSARY)) {
    lines.push(`- ${key}: use "${terms[targetLang]}"`);
  }
  return lines.join('\n');
}

const GEMINI_MODELS = [
  process.env.GEMINI_TRANSLATION_MODEL || 'gemini-3.5-flash',
  'gemini-3.8-flash',
  'gemini-3.5-flash-lite',
  'gemini-flash-latest',
];

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Calls the Gemini generative AI model with bounded timeout and model fallback.
 */
async function callGeminiTranslationApi(
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
        console.error(`[Translation Auth Error] API key authentication failed (${response.status}): ${errBody}`);
        return { ok: false, status: response.status, error: errBody };
      }

      if (response.status === 404) {
        console.warn(`[Translation Model] Model "${model}" not found (404). Trying next fallback candidate...`);
        continue;
      }

      if (!response.ok) {
        const errBody = await response.text();
        console.warn(`[Translation API Warning] Model "${model}" HTTP ${response.status}: ${errBody}`);
        return { ok: false, status: response.status, error: errBody };
      }

      const data = await response.json();
      return { ok: true, status: response.status, json: data };
    } catch (e: any) {
      if (e?.name === 'AbortError') {
        console.error(`[Translation Timeout] Model "${model}" timed out after ${timeoutMs}ms.`);
        return { ok: false, status: 408, error: `Translation request timed out after ${timeoutMs}ms` };
      }
      console.warn(`[Translation Network Error] Error contacting model ${model}:`, e);
    }
  }
  return { ok: false, status: 503, error: 'All Gemini translation models unreachable' };
}

/**
 * Executes a Gemini translation call with exponential backoff retry for transient network issues.
 */
async function callGeminiTranslationWithRetry(
  apiKey: string,
  prompt: string,
  maxAttempts = 3,
  baseBackoffMs = 400,
  timeoutMs = 10000
): Promise<{ ok: boolean; status: number; text?: string; json?: any; error?: string; attempts: number }> {
  let lastResult: { ok: boolean; status: number; text?: string; json?: any; error?: string } = {
    ok: false,
    status: 500,
    error: 'Uninitialized',
  };

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const res = await callGeminiTranslationApi(apiKey, prompt, timeoutMs);
    if (res.ok) {
      return { ...res, attempts: attempt };
    }

    lastResult = res;
    if (res.status === 401 || res.status === 403 || res.status === 400) {
      // Non-transient client/auth error: do not retry
      return { ...res, attempts: attempt };
    }

    if (attempt < maxAttempts) {
      const backoff = baseBackoffMs * Math.pow(2, attempt - 1);
      await sleep(backoff);
    }
  }

  return { ...lastResult, attempts: maxAttempts };
}

/**
 * Deterministic offline translation simulator for unit tests and local development.
 */
export function simulateOfflineTranslation(
  text: string,
  sourceLang: SupportedLanguage,
  targetLang: SupportedLanguage
): string {
  if (sourceLang === targetLang) return text;

  // Sample phrases
  if (text.includes('water leakage near the school') || text.includes('water leakage')) {
    if (targetLang === 'mr') return 'शाळेजवळ पाण्याची गळती आहे.';
    if (targetLang === 'hi') return 'स्कूल के पास पानी का रिसाव है।';
    if (targetLang === 'en') return 'There is water leakage near the school.';
  }

  if (text.includes('पाण्याची गळती') || text.includes('शाळेजवळ')) {
    if (targetLang === 'en') return 'There is water leakage near the school.';
    if (targetLang === 'hi') return 'स्कूल के पास पानी का रिसाव है।';
    if (targetLang === 'mr') return text;
  }

  if (text.includes('पानी का रिसाव') || text.includes('स्कूल के पास')) {
    if (targetLang === 'en') return 'There is water leakage near the school.';
    if (targetLang === 'mr') return 'शाळेजवळ पाण्याची गळती आहे.';
    if (targetLang === 'hi') return text;
  }

  if (text.includes('Pothole on Main Road') || text.includes('pothole')) {
    if (targetLang === 'mr') return 'मुख्य रस्त्यावर खड्डा आहे.';
    if (targetLang === 'hi') return 'मुख्य सड़क पर गड्ढा है।';
    if (targetLang === 'en') return 'Pothole on Main Road.';
  }

  // Generic prefixed simulation
  if (targetLang === 'mr') return `[मराठी भाषांतर] ${text}`;
  if (targetLang === 'hi') return `[हिंदी अनुवाद] ${text}`;
  return `[English Translation] ${text}`;
}

/**
 * Core translation executor that checks persistent cache, calls Gemini API with prompt hardening,
 * validates output, and persists translation records.
 */
export async function executeUserContentTranslation(
  db: FirebaseFirestore.Firestore,
  input: TranslationInput
): Promise<TranslationOutput> {
  const rawText = (input.text || '').trim();
  if (rawText.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Text to translate cannot be empty.');
  }

  if (rawText.length > MAX_TRANSLATABLE_LENGTH) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Text exceeds maximum allowable length of ${MAX_TRANSLATABLE_LENGTH} characters.`
    );
  }

  const targetLang = (input.targetLanguage || '').trim().toLowerCase();
  if (!isSupportedLanguage(targetLang)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Target language "${targetLang}" is not supported. Supported languages: ${SUPPORTED_LANGUAGES.join(', ')}.`
    );
  }

  const sourceLang = (input.sourceLanguage || 'en').trim().toLowerCase();
  if (!isSupportedLanguage(sourceLang)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Source language "${sourceLang}" is not supported. Supported languages: ${SUPPORTED_LANGUAGES.join(', ')}.`
    );
  }

  // 1. Same-language bypass (Zero AI cost, zero DB write)
  if (sourceLang === targetLang) {
    return {
      originalText: rawText,
      translatedText: rawText,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
      provider: 'identity',
      translatedAt: new Date().toISOString(),
      isCached: false,
      confidence: 1.0,
      sourceHash: computeSourceHash(rawText),
    };
  }

  const sourceHash = computeSourceHash(rawText);
  const contentType = (input.contentType || 'generic').trim().toLowerCase();
  const version = input.translationVersion || CURRENT_TRANSLATION_VERSION;

  const cacheDocId = computeCacheDocId({
    contentType,
    sourceHash,
    sourceLanguage: sourceLang,
    targetLanguage: targetLang,
    version,
  });

  const cacheRef = db.collection('translation_cache').doc(cacheDocId);

  // 2. Persistent Cache Check (L2 Cache Hit)
  try {
    const cachedSnap = await cacheRef.get();
    if (cachedSnap.exists) {
      const cachedData = cachedSnap.data();
      if (
        cachedData &&
        cachedData.sourceHash === sourceHash &&
        cachedData.targetLanguage === targetLang &&
        cachedData.translatedText &&
        typeof cachedData.translatedText === 'string'
      ) {
        return {
          originalText: rawText,
          translatedText: cachedData.translatedText,
          sourceLanguage: cachedData.sourceLanguage || sourceLang,
          targetLanguage: targetLang,
          provider: cachedData.provider || 'gemini',
          translatedAt: cachedData.createdAt?.toDate ? cachedData.createdAt.toDate().toISOString() : new Date().toISOString(),
          isCached: true,
          confidence: cachedData.confidence || 0.95,
          sourceHash,
        };
      }
    }
  } catch (err) {
    console.warn(`[TranslationCache] Error reading persistent cache:`, err);
  }

  // 3. Gemini Translation Engine Execution
  const apiKey =
    process.env.GEMINI_TRANSLATION_API_KEY ||
    process.env.GEMINI_API_KEY;

  let translatedText = '';
  let providerUsed = 'gemini';
  let confidenceScore = 0.95;

  if (!apiKey) {
    // Offline simulated translation
    translatedText = simulateOfflineTranslation(rawText, sourceLang, targetLang);
    providerUsed = 'simulated_offline';
  } else {
    const glossaryPrompt = generateGlossaryPrompt(targetLang);
    const langNames: Record<SupportedLanguage, string> = {
      en: 'English',
      hi: 'Hindi (हिन्दी)',
      mr: 'Marathi (मराठी)',
    };

    const prompt = `You are the authoritative CivicFix Municipal Translation Engine for Mumbai, India.
Translate the following human-authored civic grievance text faithfully from ${langNames[sourceLang]} into ${langNames[targetLang]}.

ORIGINAL TEXT:
"""
${rawText}
"""

APPROVED CIVIC GLOSSARY:
${glossaryPrompt}

STRICT TRANSLATION RULES:
1. Translate faithfully and naturally into ${langNames[targetLang]}.
2. Do NOT summarize, abbreviate, embellish, explain, or add commentary.
3. Preserve all ticket IDs (e.g. "CF-2026-000123"), ward designations (e.g. "Ward K/East", "Ward F/North"), personal names, landmarks, addresses, and phone numbers verbatim.
4. Preserve all numbers, timestamps, dates, bullet points, and paragraph breaks.
5. Return JSON ONLY with this exact structure:
{
  "translatedText": string,
  "confidence": number (between 0.0 and 1.0)
}`;

    const apiRes = await callGeminiTranslationWithRetry(apiKey, prompt, 3, 400, 10000);

    if (!apiRes.ok || !apiRes.json) {
      console.error(`[Translation Engine Error] Gemini returned error (status ${apiRes.status}): ${apiRes.error}`);
      throw new functions.https.HttpsError(
        'unavailable',
        `Translation provider is temporarily unavailable (status ${apiRes.status}).`
      );
    }

    const candidateText = apiRes.json.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!candidateText) {
      throw new functions.https.HttpsError('internal', 'Translation provider returned an empty response.');
    }

    try {
      const parsed = JSON.parse(candidateText);
      if (parsed.translatedText && typeof parsed.translatedText === 'string') {
        translatedText = parsed.translatedText.trim();
        confidenceScore = typeof parsed.confidence === 'number' ? parsed.confidence : 0.95;
      } else {
        translatedText = candidateText.trim();
      }
    } catch {
      translatedText = candidateText.trim();
    }
  }

  // Validate output
  if (!translatedText || translatedText.length === 0) {
    throw new functions.https.HttpsError('internal', 'Generated translation was empty or invalid.');
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const resultPayload: TranslationOutput = {
    originalText: rawText,
    translatedText,
    sourceLanguage: sourceLang,
    targetLanguage: targetLang,
    provider: providerUsed,
    translatedAt: new Date().toISOString(),
    isCached: false,
    confidence: confidenceScore,
    sourceHash,
  };

  // 4. Write to Persistent Translation Cache (L2 Cache Write)
  try {
    await cacheRef.set({
      cacheId: cacheDocId,
      contentId: input.contentId || null,
      fieldName: input.fieldName || null,
      contentType,
      sourceHash,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
      translatedText,
      provider: providerUsed,
      confidence: confidenceScore,
      schemaVersion: 1,
      translationVersion: version,
      createdAt: now,
      updatedAt: now,
    });
  } catch (err) {
    console.warn(`[TranslationCache] Error writing to persistent cache:`, err);
  }

  return resultPayload;
}
