import { requestGeminiJson } from "./gemini-request.ts";

function assert(value: unknown, message: string) { if (!value) throw new Error(message); }
const success = () => new Response(JSON.stringify({ candidates: [{ content: { parts: [{ text: '{"ok":true}' }] } }] }));

Deno.test("503 switches model and preserves image evidence", async () => {
  const calls: { url: string; body: string }[] = [];
  const parts = [{ inlineData: { mimeType: "image/png", data: "fixture" } }];
  const result = await requestGeminiJson("test", ["primary", "fallback"], parts, {
    fetch: async (url, init) => {
      calls.push({ url: String(url), body: String(init?.body) });
      return calls.length === 1 ? new Response("busy", { status: 503 }) : success();
    }, sleep: async () => {},
  });
  assert(result.ok && calls.length === 2 && calls[1].url.includes("fallback"), "fallback must recover 503");
  assert(calls.every(call => JSON.parse(call.body).contents[0].parts[0].inlineData.data === "fixture"), "must preserve image");
});

Deno.test("outage retries stop after four requests", async () => {
  let count = 0;
  try {
    await requestGeminiJson("test", ["primary", "fallback"], [], { fetch: async () => { count++; return new Response("busy", { status: 503 }); }, sleep: async () => {} });
    throw new Error("unexpected success");
  } catch (error) { assert((error as Error).message.includes("retries exhausted") && count === 4, "bounded failure required"); }
});

Deno.test("invalid credentials fail immediately", async () => {
  let count = 0;
  try {
    await requestGeminiJson("test", ["primary", "fallback"], [], { fetch: async () => { count++; return new Response("denied", { status: 403 }); }, sleep: async () => {} });
    throw new Error("unexpected success");
  } catch (error) { assert((error as Error).message.includes("HTTP 403") && count === 1, "must not retry auth errors"); }
});

Deno.test("404 removes retired model from retries", async () => {
  const calls: string[] = [];
  const result = await requestGeminiJson("test", ["retired", "fallback"], [], {
    fetch: async (url) => { calls.push(String(url)); return calls.length === 1 ? new Response("missing", { status: 404 }) : success(); }, sleep: async () => {},
  });
  assert(result.ok && calls[1].includes("fallback"), "must skip unavailable model");
});

Deno.test("network failure retries successfully", async () => {
  let count = 0;
  const result = await requestGeminiJson("test", ["primary", "fallback"], [], {
    fetch: async () => { if (++count === 1) throw new TypeError("network"); return success(); }, sleep: async () => {},
  });
  assert(result.ok && count === 2, "must recover network errors");
});
