// Bounded retries keep both verification stages within the Edge Function lifetime.
export async function requestGeminiJson(
  key: string,
  models: string[],
  parts: Record<string, unknown>[],
  dependencies = { fetch: globalThis.fetch, sleep: (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms)) },
): Promise<Record<string, unknown>> {
  let lastError = "No configured Gemini model is available";
  const unavailable = new Set<string>();
  for (let attempt = 0; attempt < 4; attempt++) {
    const available = models.filter((model) => !unavailable.has(model));
    if (!available.length) break;
    const model = available[attempt % available.length];
    if (attempt > 0) await dependencies.sleep(500 * 2 ** (attempt - 1));
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 10000);
    try {
      const response = await dependencies.fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json", "x-goog-api-key": key },
          body: JSON.stringify({ contents: [{ parts }], generationConfig: { responseMimeType: "application/json", temperature: 0.1 } }),
          signal: controller.signal,
        },
      );
      if (!response.ok) {
        // Record model and status, never credentials or citizen evidence.
        lastError = `Gemini ${model} returned HTTP ${response.status}`;
        await response.body?.cancel();
        if (response.status === 404) unavailable.add(model);
        else if (![408, 429, 500, 502, 503, 504].includes(response.status)) throw new Error(lastError);
        console.warn(lastError, `attempt ${attempt + 1}/4`);
        continue;
      }
      const result = await response.json();
      const text = result.candidates?.[0]?.content?.parts?.filter(
        (part: { text?: string; thought?: boolean }) => typeof part.text === "string" && !part.thought,
      ).map((part: { text: string }) => part.text).join("");
      if (!text) throw new Error(`Gemini ${model} returned no text`);
      const parsed = JSON.parse(text);
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("Gemini returned invalid JSON object");
      return parsed;
    } catch (error) {
      if (error instanceof Error && (error.name === "AbortError" || error instanceof TypeError || error instanceof SyntaxError)) {
        lastError = `Gemini ${model} ${error.name === "AbortError" ? "request timed out" : "request or response failed"}`;
        console.warn(lastError, `attempt ${attempt + 1}/4`);
        continue;
      }
      throw error;
    } finally {
      clearTimeout(timer);
    }
  }
  throw new Error(`${lastError}; automatic retries exhausted`);
}
