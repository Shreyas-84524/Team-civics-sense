import fs from 'node:fs';

const usersRaw = JSON.parse(fs.readFileSync('C:/Users/Kryo/.gemini/antigravity/brain/aff42ba4-4093-4a57-9cbb-9571edd8e64c/.system_generated/steps/676/output.txt', 'utf8'));
const complaintsRaw = JSON.parse(fs.readFileSync('C:/Users/Kryo/.gemini/antigravity/brain/aff42ba4-4093-4a57-9cbb-9571edd8e64c/.system_generated/steps/680/output.txt', 'utf8'));

function parseValue(v) {
  if (!v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return parseInt(v.integerValue, 10);
  if ('doubleValue' in v) return parseFloat(v.doubleValue);
  if ('booleanValue' in v) return v.booleanValue;
  if ('timestampValue' in v) return v.timestampValue;
  if ('nullValue' in v) return null;
  if ('mapValue' in v) {
    const res = {};
    for (const [k, val] of Object.entries(v.mapValue.fields || {})) {
      res[k] = parseValue(val);
    }
    return res;
  }
  if ('arrayValue' in v) {
    return (v.arrayValue.values || []).map(parseValue);
  }
  return null;
}

const complaints = [];
for (const doc of complaintsRaw.documents || []) {
  const id = doc.name.split('/').pop();
  const fields = {};
  for (const [k, v] of Object.entries(doc.fields || {})) {
    fields[k] = parseValue(v);
  }
  complaints.push({ id, ...fields });
}

console.log('Complaints Citizen IDs:');
const citizenIdsOnComplaints = new Set();
for (const c of complaints) {
  citizenIdsOnComplaints.add(c.citizenId);
  console.log(`Complaint ${c.id} | Citizen: ${c.citizenId} | Title: ${c.title} | Status: ${c.status}`);
}

console.log('\nUnique Citizen IDs on complaints:', [...citizenIdsOnComplaints]);
