# Complaint submission authorization handoff

This bundle preserves the current working-tree version of the complaint submission fix. The repository has many other uncommitted changes; do not reset or overwrite them.

## Files

- `complaint-submission.patch` is a focused diff against `HEAD` for the ten relevant files.
- `snapshot/` contains the exact current contents of those files, including the regression test.
- `SHA256SUMS.txt` records their SHA-256 hashes.

The patch was generated from both staged and unstaged changes. On this Windows checkout, `git apply --reverse --check` failed for the rules and regression test because of line-ending differences. Use the snapshots as the authoritative copy if patch application fails.

## Findings

- The screenshot's message is the UI mapping of a Firestore `permission-denied` error during complaint submission.
- The local creation path now writes an unassigned complaint first. The initial status is `underVerification`, and a `complaint_updates` entry is written in the same Firestore batch.
- Local `firestore.rules` accepts a citizen-owned `underVerification` or legacy `reported` complaint and the matching initial timeline entry. Government assignment fields must be null at creation.
- The configured Firebase project is `civicfix-38d53` (`civic_app/.firebaserc`). The live rules and app deployment were **not** verified or changed here; the Firebase CLI database-list request did not return.
- Targeted Flutter tests passed: 32 tests across `complaint_submission_authorization_regression_test.dart` and `firestore_rules_validation_test.dart`. These include a rule simulation, not a live Firebase submission.

## Antigravity prompt

I need you to finish fixing CivicFix complaint submission using your Firebase MCP access. The project is `civicfix-38d53`, configured in `civic_app/.firebaserc`. Start by reading `civic_app/handoff/complaint-submission-2026-10-02/README.md`, the focused patch, and the exact file snapshots. Preserve all existing staged, unstaged, and untracked changes in this repository.

The user sees: “CivicFix could not submit this complaint because of an authorization problem.” The current local code creates a citizen-owned `underVerification` complaint with null government assignment fields, and creates the initial `complaint_updates` event in an atomic batch. The local Firestore rules allow those writes. The targeted Flutter regression suite passed 32 tests, but the live Firebase rules and running app were not verified.

Use Firebase MCP to identify the Firestore database instance and edition for `civicfix-38d53`, inspect the active rules, and compare them with `civic_app/firestore.rules`. Determine the exact live rule or auth mismatch that denies the initial complaint or timeline write. Apply the smallest secure correction, keeping citizenId equal to the authenticated UID and government assignment fields server-authoritative. Deploy the corrected Firestore rules to the identified project if needed. Do not deploy unrelated Cloud Functions or other uncommitted work. Then verify a real authenticated citizen complaint submission, including the initial timeline event, and confirm it appears to the citizen. If the client build is stale, update/deploy the appropriate client only after identifying its actual deployment target. Report precisely what you changed, deployed, tested, and any remaining blocker.
