# CivicFix Public Certificate Verification Portal (Vercel Ready)

This portal powers the public QR verification route for CivicFix certificates:
`https://<civicfix-domain>/verify/{verificationSlug}`

## Features
- **Zero Authentication Required**: Open verification for universities, employers, NGOs, and municipal authorities.
- **Privacy Safe**: Never exposes Firebase UIDs, phone numbers, emails, internal complaint identifiers, or credentials.
- **Authoritative States**:
  - `VALID`: Renders verified checkmark, recipient display name, snapshot points/reports, and importance summary.
  - `REVOKED`: Prominently displays revocation status, warning, and reason without verified badge.
  - `INVALID`: Safe generic message without leaking database structure.
- **Vercel Serverless Ready**: Includes `vercel.json` rewrites and `api/verify.js` endpoint.

## Deployment on Vercel
1. Install Vercel CLI: `npm i -g vercel`
2. Run `vercel` in this directory:
   ```bash
   cd verification_portal
   vercel
   ```
3. Set environment variables in Vercel project dashboard:
   - `PUBLIC_BASE_URL`: e.g. `https://civicfix.vercel.app`
   - `FIREBASE_PROJECT_ID`: your Firebase project ID
   - `FIREBASE_API_KEY`: Firebase web API key
