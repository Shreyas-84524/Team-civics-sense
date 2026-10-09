// Synchronize bundled/offline rosters only after the live replacement verifies.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const dir = path.join(root, '.temp/government-account-replacement');
const result = JSON.parse(fs.readFileSync(path.join(dir, 'result.json'), 'utf8'));
assert.equal(result.passwordUpdatesConfirmed, 2642);
assert.equal(result.legacyAuthAccountsRemaining, 0);
const records = JSON.parse(fs.readFileSync(path.join(dir, 'input.json'), 'utf8'));
const emails = new Set(records.filter(r => r.source === 'Active Canonical Matrix').map(r => r.email));
for (const relative of ['civic_app/assets/govt_data/government_users.json', 'resources/Govt Data/government_users.json', 'civic_app/resources/Govt Data/government_users.json']) {
  const file = path.join(root, relative);
  const original = fs.readFileSync(file, 'utf8');
  const data = JSON.parse(original);
  data.governmentUsers = data.governmentUsers.filter(u => emails.has(u.email.toLowerCase()));
  assert.equal(data.governmentUsers.length, 2642);
  data.totalUsers = 2642;
  data.updatedAt = result.completedAt;
  const backup = path.join(dir, relative.replaceAll('/', '_') + '.backup.json');
  if (!fs.existsSync(backup)) fs.writeFileSync(backup, original);
  fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n');
}
console.log('All three bundled/source government rosters now contain 2,642 canonical accounts.');
