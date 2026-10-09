// Read verification diagnostics using the existing Firebase CLI login.
// No tokens are printed or saved. This script never changes complaints.
const fs = require('node:fs');
const path = require('node:path');

async function main() {
  const [authModule, complaintId] = process.argv.slice(2);
  if (!authModule || !complaintId) throw new Error('Usage: node retry-complaint-verification.cjs <firebase-tools/lib/auth.js> <complaintId>');
  const auth = require(path.resolve(authModule));
  const config = JSON.parse(fs.readFileSync(path.join(process.env.USERPROFILE, '.config/configstore/firebase-tools.json'), 'utf8'));
  const access = await auth.getAccessToken(config.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const headers = { Authorization: `Bearer ${access.access_token}`, 'Content-Type': 'application/json' };
  const url = `https://firestore.googleapis.com/v1/projects/civicfix-38d53/databases/(default)/documents/complaints/${encodeURIComponent(complaintId)}`;
  const response = await fetch(url, { headers });
  if (!response.ok) throw new Error(`Firestore read HTTP ${response.status}`);
  const doc = await response.json();
  const fields = doc.fields;
  const selected = ['ticketNumber', 'status', 'aiAnalysisStatus', 'verificationStage', 'verificationFailureReason', 'evidenceVerificationStatus', 'departmentVerificationStatus', 'departmentName', 'citizenSafeVerificationMessage'];
  console.log(JSON.stringify(Object.fromEntries(selected.map(k => [k, fields[k]?.stringValue ?? null])), null, 2));
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
