#!/usr/bin/env bash
# CivicFix — Quick Tunnel Secret Updater (Cross-Platform Bash)
# Safely updates the Supabase SMS_GATEWAY_URL secret when Quick Tunnel rotates.

set -euo pipefail

PROJECT_REF="hkgwsqasmboadvpjckbj"
TUNNEL_URL="${1:-}"

echo "================================================================"
echo "CivicFix - SMS Gateway Quick Tunnel Recovery Workflow"
echo "================================================================"

if [ -z "$TUNNEL_URL" ]; then
  echo "When you start Cloudflare Quick Tunnel on your gateway host:"
  echo "  cloudflared tunnel --url http://<android-ip>:8080"
  echo ""
  read -r -p "Enter the new Cloudflare Quick Tunnel URL (e.g. https://xxxx.trycloudflare.com): " TUNNEL_URL
fi

# Trim trailing slash
TUNNEL_URL="${TUNNEL_URL%/}"

# Validate format
if [[ ! "$TUNNEL_URL" =~ ^https://[a-zA-Z0-9._-]+\.[a-zA-Z]{2,} ]]; then
  echo "ERROR: Invalid URL format. Must start with https:// and be a valid hostname." >&2
  exit 1
fi

echo "[1/3] Validated Tunnel URL format: $TUNNEL_URL"

# Check gateway connectivity
echo "[2/3] Checking gateway connectivity at $TUNNEL_URL/api/info..."
if curl -s --max-time 5 "$TUNNEL_URL/api/info" > /dev/null; then
  echo "      [OK] Gateway online!"
else
  echo "      [WARN] Gateway /api/info check was unreachable. Continuing..."
fi

# Update Supabase secret
echo "[3/3] Updating Supabase secret SMS_GATEWAY_URL on project [$PROJECT_REF]..."
npx supabase secrets set "SMS_GATEWAY_URL=$TUNNEL_URL" --project-ref "$PROJECT_REF"

echo ""
echo "[SUCCESS] Supabase SMS_GATEWAY_URL secret updated successfully!"
echo "  New Tunnel URL: $TUNNEL_URL"
echo "  Supabase Edge Functions will route new OTP requests to this gateway immediately."
echo "  NO Flutter changes or rebuilds required."
