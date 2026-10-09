/**
 * CivicFix Certificate Verification Serverless Function (Vercel Ready)
 * 
 * Validates cryptographic verification slugs against authoritative Firestore records
 * and returns ONLY privacy-safe public certificate data.
 */

const https = require('https');

// Privacy-safe allowlist mapper
function mapToPublicCertificate(data) {
  const isLevel = (data.certificateType || '') === 'civic_level_tier';
  const defaultImportance = isLevel
    ? 'Official recognition awarded by Municipal Civic Governance for sustained citizen engagement, active civic problem reporting, and verifiable community impact.'
    : 'Special civic milestone recognition awarded for exemplary verified contributions to community infrastructure, ground reporting, or collective civic problem solving.';

  return {
    certificateId: data.certificateId || '',
    recipientDisplayName: data.recipientDisplayName || 'Citizen',
    certificateType: data.certificateType || 'civic_level_tier',
    certificateTitle: data.certificateTitle || 'Civic Certificate of Recognition',
    civicLevel: data.civicLevel || 'Civic Contributor',
    pointsAtIssue: Number(data.pointsAtIssue) || 0,
    verifiedComplaintsAtIssue: Number(data.verifiedComplaintsAtIssue) || 0,
    resolvedComplaintsAtIssue: Number(data.resolvedComplaintsAtIssue) || 0,
    achievementReason: data.achievementReason || '',
    awardImportance: data.awardImportance || defaultImportance,
    issuedAt: data.issuedAt || new Date().toISOString(),
    status: (data.status || 'valid').toUpperCase(),
    verificationSlug: data.verificationSlug || '',
    certificateVersion: Number(data.certificateVersion) || 1,
    revocationReason: data.revocationReason || null,
    revokedAt: data.revokedAt || null,
  };
}

// Helper to query Firestore via REST API
async function fetchCertificateFromFirestore(projectId, apiKey, slug) {
  if (!projectId) return null;

  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:runQuery${apiKey ? `?key=${apiKey}` : ''}`;

  const queryBody = JSON.stringify({
    structuredQuery: {
      from: [{ collectionId: 'certificates' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'verificationSlug' },
          op: 'EQUAL',
          value: { stringValue: slug }
        }
      },
      limit: 1
    }
  });

  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(queryBody)
      }
    }, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (Array.isArray(parsed) && parsed.length > 0 && parsed[0].document) {
            const doc = parsed[0].document;
            const fields = doc.fields || {};
            const result = {};
            for (const [key, val] of Object.entries(fields)) {
              if (val.stringValue !== undefined) result[key] = val.stringValue;
              else if (val.integerValue !== undefined) result[key] = parseInt(val.integerValue, 10);
              else if (val.timestampValue !== undefined) result[key] = val.timestampValue;
              else if (val.booleanValue !== undefined) result[key] = val.booleanValue;
            }
            resolve(result);
          } else {
            resolve(null);
          }
        } catch (e) {
          resolve(null);
        }
      });
    });

    req.on('error', (err) => resolve(null));
    req.write(queryBody);
    req.end();
  });
}

module.exports = async function handler(req, res) {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json; charset=utf-8');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const slug = (req.query.slug || req.url.split('?')[0].split('/').pop() || '').trim();

  // 1. Slug Validation Guard
  if (!slug || !/^[a-zA-Z0-9_-]{4,64}$/.test(slug)) {
    return res.status(200).json({
      state: 'invalid',
      certificate: null,
      message: 'No valid CivicFix certificate was found for this verification reference.',
      verifiedAt: new Date().toISOString()
    });
  }

  const projectId = process.env.FIREBASE_PROJECT_ID || process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID;
  const apiKey = process.env.FIREBASE_API_KEY || process.env.NEXT_PUBLIC_FIREBASE_API_KEY;

  let rawCert = null;

  if (projectId) {
    try {
      rawCert = await fetchCertificateFromFirestore(projectId, apiKey, slug);
    } catch (err) {
      console.error('Firestore lookup error:', err);
    }
  }

  // If certificate not found
  if (!rawCert) {
    return res.status(200).json({
      state: 'invalid',
      certificate: null,
      message: 'No valid CivicFix certificate was found for this verification reference.',
      verifiedAt: new Date().toISOString()
    });
  }

  const publicCert = mapToPublicCertificate(rawCert);

  // Check Revocation Status
  if (publicCert.status === 'REVOKED') {
    return res.status(200).json({
      state: 'revoked',
      certificate: publicCert,
      message: 'This certificate is no longer considered valid by CivicFix.',
      verifiedAt: new Date().toISOString()
    });
  }

  // Valid Active Certificate
  return res.status(200).json({
    state: 'valid',
    certificate: publicCert,
    message: 'Certificate Verified — Authentic CivicFix Achievement',
    verifiedAt: new Date().toISOString()
  });
};
