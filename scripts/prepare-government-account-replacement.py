"""Validate the supplied workbook without printing passwords."""
import collections
import json
import pathlib
import sys
import openpyxl

root = pathlib.Path(__file__).resolve().parents[1]
workbook = openpyxl.load_workbook(sys.argv[1], read_only=True, data_only=True)
rows = list(workbook['All Government Accounts'].values)
profiles = json.loads((root / 'civic_app/assets/govt_data/government_users.json').read_text(encoding='utf-8'))['governmentUsers']
by_email = {p['email'].strip().lower(): p for p in profiles}
records, seen = [], set()
for number, values in enumerate(rows[1:], 2):
    if not any(v is not None for v in values):
        continue
    row = dict(zip(rows[0], values))
    email = str(row['Email'] or '').strip().lower()
    password = row['Password']
    if isinstance(password, (int, float)) and not isinstance(password, bool):
        assert float(password).is_integer() and 0 <= password < 10**15, f'Ambiguous numeric password at row {number}'
        password = str(int(password))
    assert email and email not in seen, f'Duplicate/missing email at row {number}'
    assert isinstance(password, str) and len(password) >= 6, f'Invalid password at row {number}'
    profile = by_email.get(email)
    assert profile, f'No existing role mapping at row {number}'
    assert profile['employeeId'] == row['ID / Employee ID'], f'Employee ID mismatch at row {number}'
    assert profile['fullName'] == row['Full Name'], f'Name mismatch at row {number}'
    if row['Dataset Source'] == 'Active Canonical Matrix':
        assert profile['role'] == row['Role'], f'Role mismatch at row {number}'
    records.append({'email': email, 'password': password, 'source': row['Dataset Source'], 'profile': profile})
    seen.add(email)
out = root / '.temp/government-account-replacement'
out.mkdir(parents=True, exist_ok=True)
(out / 'input.json').write_text(json.dumps(records), encoding='utf-8')
print(json.dumps({'validated': len(records), 'sources': dict(collections.Counter(r['source'] for r in records)), 'existingProfileMatches': len(records), 'passwordsPrinted': False}))
