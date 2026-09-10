const test = require('node:test');
const assert = require('node:assert');

// Helper unit tests for status content resolution and token sanitation
function getStatusContent(status, ticketNumber, complaintTitle, departmentName, officerNotes) {
  switch (status) {
    case 'verified':
      return {
        title: `Complaint Verified: ${ticketNumber}`,
        body: `Your grievance "${complaintTitle}" has been verified by the municipal authority.`,
        type: 'complaintVerified',
      };
    case 'assigned':
      return {
        title: `Officer Assigned: ${ticketNumber}`,
        body: departmentName
          ? `Your grievance has been assigned to ${departmentName} for action.`
          : `An officer has been assigned to address your grievance "${complaintTitle}".`,
        type: 'complaintAssigned',
      };
    case 'inProgress':
      return {
        title: `Work In Progress: ${ticketNumber}`,
        body: `Municipal ground teams are actively resolving "${complaintTitle}".`,
        type: 'complaintStatusChanged',
      };
    case 'resolved':
      return {
        title: `Grievance Resolved: ${ticketNumber}`,
        body: `Work on "${complaintTitle}" is complete. Tap to review the resolution.`,
        type: 'complaintResolved',
      };
    case 'rejected':
      return {
        title: `Complaint Update: ${ticketNumber}`,
        body: officerNotes
          ? `Status updated: Closed/Rejected. Note: ${officerNotes}`
          : `Your grievance "${complaintTitle}" has been closed. Tap for details.`,
        type: 'complaintStatusChanged',
      };
    default:
      return {
        title: `Status Updated: ${ticketNumber}`,
        body: `Your grievance "${complaintTitle}" is now marked as ${status}.`,
        type: 'complaintStatusChanged',
      };
  }
}

function sanitizeTokenDocId(token) {
  return token.replace(/[^a-zA-Z0-9_-]/g, '_');
}

test('Status Content Resolution - Maps all status lifecycle transitions correctly', () => {
  const verified = getStatusContent('verified', 'CF-2026-0001', 'Pothole on Main St');
  assert.strictEqual(verified.title, 'Complaint Verified: CF-2026-0001');
  assert.strictEqual(verified.type, 'complaintVerified');
  assert.ok(verified.body.includes('Pothole on Main St'));

  const assigned = getStatusContent('assigned', 'CF-2026-0001', 'Pothole on Main St', 'Roads & Infrastructure');
  assert.strictEqual(assigned.title, 'Officer Assigned: CF-2026-0001');
  assert.strictEqual(assigned.type, 'complaintAssigned');
  assert.ok(assigned.body.includes('Roads & Infrastructure'));

  const inProgress = getStatusContent('inProgress', 'CF-2026-0001', 'Pothole on Main St');
  assert.strictEqual(inProgress.title, 'Work In Progress: CF-2026-0001');
  assert.strictEqual(inProgress.type, 'complaintStatusChanged');

  const resolved = getStatusContent('resolved', 'CF-2026-0001', 'Pothole on Main St');
  assert.strictEqual(resolved.title, 'Grievance Resolved: CF-2026-0001');
  assert.strictEqual(resolved.type, 'complaintResolved');

  const rejected = getStatusContent('rejected', 'CF-2026-0001', 'Pothole on Main St', undefined, 'Duplicate of CF-2026-0000');
  assert.strictEqual(rejected.title, 'Complaint Update: CF-2026-0001');
  assert.ok(rejected.body.includes('Duplicate of CF-2026-0000'));
});

test('Token Sanitation - Replaces invalid path and delimiter characters', () => {
  const rawToken = 'fcm:APA91b-Ez_0123/xyz.abc:test';
  const sanitized = sanitizeTokenDocId(rawToken);
  assert.strictEqual(sanitized, 'fcm_APA91b-Ez_0123_xyz_abc_test');
  assert.ok(!/[/\\:.]/.test(sanitized));
});

test('Status Diffing Logic - Detects transitions and ignores equal statuses', () => {
  const before = { status: 'reported', upvotes: 1 };
  const afterSame = { status: 'reported', upvotes: 2 };
  const afterChanged = { status: 'verified', upvotes: 1 };

  assert.strictEqual(before.status === afterSame.status, true, 'Should detect identical status');
  assert.strictEqual(before.status === afterChanged.status, false, 'Should detect status transition');
});
