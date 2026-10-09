import fs from 'node:fs';

const usersRaw = JSON.parse(fs.readFileSync('C:/Users/Kryo/.gemini/antigravity/brain/aff42ba4-4093-4a57-9cbb-9571edd8e64c/.system_generated/steps/676/output.txt', 'utf8'));
const complaintsRaw = JSON.parse(fs.readFileSync('C:/Users/Kryo/.gemini/antigravity/brain/aff42ba4-4093-4a57-9cbb-9571edd8e64c/.system_generated/steps/680/output.txt', 'utf8'));

const STAGE_POINTS = { submitted: 10, verified: 20, assigned: 15, inProgress: 20, resolved: 35 };

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

const users = [];
for (const doc of usersRaw.documents || []) {
  const id = doc.name.split('/').pop();
  const fields = {};
  for (const [k, v] of Object.entries(doc.fields || {})) {
    fields[k] = parseValue(v);
  }
  users.push({ id, ...fields });
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

function eligible(data) {
  return (
    data.status !== "rejected" &&
    data.isDuplicate !== true &&
    !data.duplicateOf &&
    !data.duplicateOfComplaintId &&
    data.rewardEligible !== false &&
    data.isFraudulent !== true &&
    data.isEvidenceRejected !== true &&
    data.isAiGeneratedEvidenceRejected !== true &&
    data.evidenceVerificationStatus !== "failed" &&
    data.aiAnalysisStatus !== "failed"
  );
}

function statusToRank(status) {
  switch (status) {
    case "underVerification":
    case "reported":
      return 0;
    case "verified":
      return 1;
    case "assigned":
      return 2;
    case "inProgress":
      return 3;
    case "resolved":
    case "closed":
      return 4;
    default:
      return -1;
  }
}

function reachedStages(data) {
  if (!eligible(data)) return [];
  const maxRank = statusToRank(data.status);
  const stages = ["submitted", "verified", "assigned", "inProgress", "resolved"];
  return stages.slice(0, Math.max(0, Math.min(maxRank + 1, 5)));
}

// Map all unique citizens from complaints or users
const citizenIds = new Set();
for (const c of complaints) if (c.citizenId) citizenIds.add(c.citizenId);
for (const u of users) {
  if (u.role === 'citizen' || (!u.role && u.employeeId === undefined && u.departmentId === undefined)) {
    citizenIds.add(u.id);
  }
}

const reconciliationDryRun = [];

for (const cid of citizenIds) {
  const user = users.find(u => u.id === cid) || { id: cid, fullName: "Citizen (Author)", civicPoints: 20 };
  const citizenComplaints = complaints.filter(c => c.citizenId === cid);
  const currentPoints = Number(user.civicPoints || 0);
  
  let calculatedComplaintPoints = 0;
  const complaintBreakdown = [];

  for (const c of citizenComplaints) {
    const stages = reachedStages(c);
    let pts = 0;
    for (const s of stages) {
      pts += STAGE_POINTS[s];
    }
    pts = Math.min(100, pts);
    calculatedComplaintPoints += pts;
    complaintBreakdown.push({
      complaintId: c.id,
      title: c.title,
      ticket: c.ticketNumber,
      status: c.status,
      stagesReached: stages,
      pointsEarned: pts
    });
  }

  const baselineRegistrationPoints = 20;
  const theoreticalTotal = baselineRegistrationPoints + calculatedComplaintPoints;
  const discrepancy = theoreticalTotal - currentPoints;

  reconciliationDryRun.push({
    citizenId: cid,
    name: user.fullName || user.name || "Citizen (pfZM...lbg1)",
    phone: user.phone ? user.phone.replace(/(\+91 \d{2})\d{4}(\d{4})/, '$1****$2') : "N/A",
    currentStoredPoints: currentPoints,
    complaintCount: citizenComplaints.length,
    complaints: complaintBreakdown,
    theoreticalPoints: theoreticalTotal,
    discrepancy,
    needsAdjustment: discrepancy > 0
  });
}

console.log('==================================================================');
console.log('CIVICFIX READ-ONLY HISTORICAL RECONCILIATION DRY RUN REPORT');
console.log('==================================================================\n');

for (const row of reconciliationDryRun) {
  console.log(`Citizen ID: ${row.citizenId}`);
  console.log(`Name: ${row.name} | Phone: ${row.phone}`);
  console.log(`Stored civicPoints: ${row.currentStoredPoints} | Theoretical Total: ${row.theoreticalPoints} | Discrepancy: +${row.discrepancy} pts`);
  console.log(`Complaints Filed: ${row.complaintCount}`);
  for (const cb of row.complaints) {
    console.log(`  - [${cb.complaintId}] "${cb.title}" | Status: ${cb.status} | Stages: [${cb.stagesReached.join(', ')}] | Points: +${cb.pointsEarned}`);
  }
  console.log('------------------------------------------------------------------');
}

const totalDiscrepancy = reconciliationDryRun.reduce((sum, r) => sum + r.discrepancy, 0);
const affectedCitizens = reconciliationDryRun.filter(r => r.needsAdjustment).length;

console.log(`\nDry Run Summary:`);
console.log(`Total Citizen Profiles Analyzed: ${reconciliationDryRun.length}`);
console.log(`Citizens with Uncredited Points: ${affectedCitizens}`);
console.log(`Total Uncredited Civic Points to Backfill upon Approval: +${totalDiscrepancy} pts`);
console.log(`\n(READ-ONLY MODE: No changes have been written to production Firestore)`);
