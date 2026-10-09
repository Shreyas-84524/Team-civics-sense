import {
  getGoogleOAuthToken,
  getServiceAccountConfig,
} from "./firestore-client.ts";

type FirestoreValue = Record<string, unknown>;

function decode(value: FirestoreValue): unknown {
  if ("nullValue" in value) return null;
  if ("stringValue" in value) return value.stringValue;
  if ("booleanValue" in value) return value.booleanValue;
  if ("integerValue" in value) return Number(value.integerValue);
  if ("doubleValue" in value) return Number(value.doubleValue);
  if ("timestampValue" in value) return value.timestampValue;
  if ("arrayValue" in value) {
    const array = value.arrayValue as { values?: FirestoreValue[] };
    return (array.values ?? []).map(decode);
  }
  if ("mapValue" in value) {
    const map = value.mapValue as { fields?: Record<string, FirestoreValue> };
    return Object.fromEntries(
      Object.entries(map.fields ?? {}).map(([key, item]) => [key, decode(item)]),
    );
  }
  return null;
}

function encode(value: unknown): FirestoreValue {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === "string") return { stringValue: value };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "number") {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(encode) } };
  if (typeof value === "object") {
    return { mapValue: { fields: encodeFields(value as Record<string, unknown>) } };
  }
  throw new Error("Unsupported Firestore value");
}

function encodeFields(data: Record<string, unknown>): Record<string, FirestoreValue> {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, encode(value)]));
}

export interface FirestoreDocument {
  name: string;
  updateTime: string;
  data: Record<string, unknown>;
}

function parseDocument(raw: {
  name: string;
  updateTime: string;
  fields?: Record<string, FirestoreValue>;
}): FirestoreDocument {
  return {
    name: raw.name,
    updateTime: raw.updateTime,
    data: Object.fromEntries(
      Object.entries(raw.fields ?? {}).map(([key, value]) => [key, decode(value)]),
    ),
  };
}

export async function createComplaintFirestore() {
  const serviceAccount = getServiceAccountConfig();
  if (!serviceAccount || serviceAccount.project_id !== "civicfix-38d53") {
    throw new Error("Firebase service account is missing or targets the wrong project");
  }
  const token = await getGoogleOAuthToken(serviceAccount);
  const root = `https://firestore.googleapis.com/v1/projects/${serviceAccount.project_id}/databases/(default)/documents`;

  async function request(path: string, init: RequestInit = {}) {
    return fetch(`${root}/${path}`, {
      ...init,
      headers: {
        Authorization: `Bearer ${token}`,
        ...(init.body ? { "Content-Type": "application/json" } : {}),
      },
    });
  }

  return {
    async get(path: string): Promise<FirestoreDocument | null> {
      const response = await request(path);
      if (response.status === 404) return null;
      if (!response.ok) throw new Error(`Firestore get failed: ${response.status}`);
      return parseDocument(await response.json());
    },
    async patch(
      path: string,
      fields: Record<string, unknown>,
      updateTime?: string,
    ): Promise<FirestoreDocument> {
      const query = new URLSearchParams();
      for (const key of Object.keys(fields)) query.append("updateMask.fieldPaths", key);
      if (updateTime) query.set("currentDocument.updateTime", updateTime);
      const response = await request(`${path}?${query}`, {
        method: "PATCH",
        body: JSON.stringify({ fields: encodeFields(fields) }),
      });
      if (!response.ok) throw new Error(`Firestore patch failed: ${response.status}`);
      return parseDocument(await response.json());
    },
    async list(collection: string, maxDocuments = 5000): Promise<FirestoreDocument[]> {
      const documents: FirestoreDocument[] = [];
      let pageToken: string | undefined;
      do {
        const query = new URLSearchParams({ pageSize: "500" });
        if (pageToken) query.set("pageToken", pageToken);
        const response = await request(`${collection}?${query}`);
        if (!response.ok) throw new Error(`Firestore list failed: ${response.status}`);
        const page = await response.json();
        documents.push(...(page.documents ?? []).map(parseDocument));
        pageToken = page.nextPageToken;
        if (documents.length >= maxDocuments && pageToken) {
          throw new Error(`Firestore collection ${collection} exceeded safe scan limit`);
        }
      } while (pageToken);
      return documents;
    },
    async query(
      collection: string,
      field: string,
      value: string,
      allDescendants = false,
    ): Promise<FirestoreDocument[]> {
      const response = await fetch(`${root}:runQuery`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          structuredQuery: {
            from: [{ collectionId: collection, allDescendants }],
            where: {
              fieldFilter: {
                field: { fieldPath: field },
                op: "EQUAL",
                value: { stringValue: value },
              },
            },
          },
        }),
      });
      if (!response.ok) throw new Error(`Firestore query failed: ${response.status}`);
      return (await response.json())
        .filter((row: { document?: unknown }) => row.document)
        .map((row: { document: Parameters<typeof parseDocument>[0] }) =>
          parseDocument(row.document),
        );
    },
    async commitRewards(
      summaryPath: string,
      summary: Record<string, unknown>,
      previous: FirestoreDocument | null,
      events: { id: string; data: Record<string, unknown> }[],
      userPath: string,
      delta: number,
    ): Promise<boolean> {
      const prefix = root.split("/v1/")[1];
      const writes: Record<string, unknown>[] = [
        {
          update: {
            name: `${prefix}/${summaryPath}`,
            fields: encodeFields(summary),
          },
          currentDocument: previous
            ? { updateTime: previous.updateTime }
            : { exists: false },
        },
      ];
      for (const event of events) {
        writes.push({
          update: {
            name: `${prefix}/${summaryPath}/events/${event.id}`,
            fields: encodeFields(event.data),
          },
          currentDocument: { exists: false },
        });
      }
      if (delta) {
        writes.push({
          transform: {
            document: `${prefix}/${userPath}`,
            fieldTransforms: [
              {
                fieldPath: "civicPoints",
                increment: { integerValue: String(delta) },
              },
            ],
          },
          currentDocument: { exists: true },
        });
      }
      const response = await fetch(`${root}:commit`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ writes }),
      });
      if ([400, 409, 412].includes(response.status)) return false;
      if (!response.ok) throw new Error(`Reward commit failed: ${response.status}`);
      return true;
    },
  };
}
