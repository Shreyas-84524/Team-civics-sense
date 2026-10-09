# Government account replacement

Completed on 2 October 2026 in Firebase project `civicfix-38d53`.

The user selected only the **Active Canonical Matrix** from `Untitled spreadsheet.xlsx`.

- Replaced passwords for all 2,642 existing canonical Firebase Authentication accounts with their corresponding spreadsheet values.
- Preserved canonical Firebase UIDs, officer profiles, roles, and assignment references.
- Deleted all 1,057 Legacy Roster Firebase Authentication accounts.
- Retained legacy historical profiles with `active: false`, role `retired_government`, and empty permissions in the government and user profile collections.
- Updated the three bundled/source government rosters to contain only the 2,642 selected accounts.
- Did not store passwords in application assets, Firestore profiles, or this report. The temporary extracted password file was removed after completion.

## Verification

- Confirmed 2,642 canonical Auth accounts remain enabled and every password update has a new server timestamp.
- Successfully authenticated a representative account from each of the six canonical roles using the supplied passwords.
- Confirmed all 1,057 legacy Auth accounts are absent and a legacy login is rejected.
- Confirmed 1,057 historical government profiles are inactive and retired.
- Passed all 50 government hierarchy, authorization, authentication, and routing tests across `bmc_government_matrix_test.dart` and `phase2_government_auth_routing_test.dart`.

The credential changes are live for both the website and app. Local roster changes will be included in subsequent builds. Original profile snapshots and the non-password completion report are in the ignored `.temp/government-account-replacement` directory.
