// Government credential replacement. Secrets remain in ignored .temp files.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const dir = path.join(root, '.temp/government-account-replacement');
const project = 'civicfix-38d53';
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
async function main() {
  const [authModule, mode = 'plan', selection = 'all'] = process.argv.slice(2);
  if (!authModule || !['plan'].includes(mode)) throw new Error('Only read-only planning is currently supported');
  const records = JSON.parse(fs.readFileSync(path.join(dir, 'input.json'), 'utf8'));
  const auth = require(path.resolve(authModule));
  const cfg = JSON.parse(fs.readFileSync(path.join(process.env.USERPROFILE, '.config/configstore/firebase-tools.json'), 'utf8'));
  const token = await auth.getAccessToken(cfg.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const headers = { Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json' };
  async function api(url, body) {
    const response = await fetch(url, { method: body ? 'POST' : 'GET', headers, ...(body ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(30000) });
    const data = await response.json();
    if (!response.ok) throw new Error(`API HTTP ${response.status}: ${data.error?.status || 'request failed'}`);
    return data;
  }
  const docs = [];
  let pageToken = '';
  do {
    const page = await api(`${base}/government_users?pageSize=1000${pageToken ? '&pageToken=' + encodeURIComponent(pageToken) : ''}`);
    docs.push(...page.documents || []);
    pageToken = page.nextPageToken;
  } while (pageToken);
  const userRows = await api(`${base}:runQuery`, { structuredQuery: {
    from: [{ collectionId: 'users' }],
    where: { fieldFilter: { field: { fieldPath: 'role' }, op: 'IN', value: { arrayValue: { values: ['government', 'government_super_admin', 'zonal_dmc', 'central_department_hod', 'ward_officer', 'ward_department_lead', 'department_crew'].map(stringValue => ({ stringValue })) } } } },
  } });
  const userDocs = userRows.filter(r => r.document).map(r => r.document);
  const accounts = [];
  for (let i = 0; i < records.length; i += 100) {
    const found = await api(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:lookup`, { email: records.slice(i, i + 100).map(r => r.email) });
    accounts.push(...(found.users || []).map(u => ({ localId: u.localId, email: u.email, disabled: !!u.disabled, customAttributes: u.customAttributes })));
  }
  const wanted = records.filter(r => selection === 'all' || r.source === 'Active Canonical Matrix');
  const wantedEmails = new Set(wanted.map(r => r.email));
  const matched = new Map(accounts.map(u => [u.email.toLowerCase(), u]));
  const extras = docs.filter(d => !wantedEmails.has(d.fields.email?.stringValue?.toLowerCase()));
  const summary = { project, selection, workbookAccounts: records.length, selectedAccounts: wanted.length, liveGovernmentProfiles: docs.length, matchingAuthAccounts: wanted.filter(r => matched.has(r.email)).length, missingAuthAccounts: wanted.filter(r => !matched.has(r.email)).length, uidMismatches: wanted.filter(r => matched.has(r.email) && matched.get(r.email).localId !== r.profile.id).length, governmentProfilesOutsideSelection: extras.length, disabledSelectedAccounts: wanted.filter(r => matched.get(r.email)?.disabled).length };
  summary.liveGovernmentUserProfiles = userDocs.length;
  summary.governmentUserProfilesOutsideRoster = userDocs.filter(d => !records.some(r => r.profile.id === d.name.split('/').pop())).length;
  fs.writeFileSync(path.join(dir, 'live-government-user-profiles.json'), JSON.stringify(userDocs));
  fs.writeFileSync(path.join(dir, 'live-government-profiles.json'), JSON.stringify(docs));
  fs.writeFileSync(path.join(dir, 'auth-inventory.json'), JSON.stringify(accounts));
  fs.writeFileSync(path.join(dir, 'plan.json'), JSON.stringify(summary, null, 2));
  console.log(JSON.stringify(summary, null, 2));
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
