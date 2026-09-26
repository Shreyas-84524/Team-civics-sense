<#
.SYNOPSIS
    CivicFix Quick Tunnel Secret Updater
.DESCRIPTION
    Safely validates and updates the Supabase SMS_GATEWAY_URL secret when
    Cloudflare Quick Tunnel rotates its ephemeral trycloudflare.com URL.
    Contains zero credentials, tokens, or hardcoded secrets.
#>

param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$TunnelUrl
)

$ErrorActionPreference = "Stop"
$ProjectRef = "hkgwsqasmboadvpjckbj"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "CivicFix - SMS Gateway Quick Tunnel Recovery Workflow" -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# 1. Prompt for URL if not provided via argument
if ([string]::IsNullOrWhiteSpace($TunnelUrl)) {
    Write-Host "When you start Cloudflare Quick Tunnel on your gateway host:" -ForegroundColor Yellow
    Write-Host "  cloudflared tunnel --url http://<android-ip>:8080`n" -ForegroundColor DarkGray
    $TunnelUrl = Read-Host "Enter the new Cloudflare Quick Tunnel URL (e.g. https://xxxx.trycloudflare.com)"
}

$TunnelUrl = $TunnelUrl.Trim().TrimEnd('/')

# 2. Format & Security Validation
if (-not ($TunnelUrl -match '^https:\/\/[a-zA-Z0-9\-_\.]+\.[a-zA-Z]{2,}')) {
    Write-Error "INVALID URL FORMAT: The tunnel URL must be a valid HTTPS address (e.g. https://random-subdomain.trycloudflare.com)."
    exit 1
}

if (-not ($TunnelUrl.StartsWith("https://", [System.StringComparison]::OrdinalIgnoreCase))) {
    Write-Error "INSECURE PROTOCOL: Plaintext HTTP is prohibited. Quick Tunnel URLs must use HTTPS."
    exit 1
}

Write-Host "`n[1/3] Validated Tunnel URL format: $TunnelUrl" -ForegroundColor Green

# 3. Optional Gateway Connectivity Verification
$infoUrl = "$TunnelUrl/api/info"
Write-Host "[2/3] Checking gateway connectivity at $infoUrl ..." -ForegroundColor Yellow
try {
    $infoResponse = Invoke-RestMethod -Uri $infoUrl -Method Get -TimeoutSec 5 -ErrorAction Stop
    $serviceName = if ($infoResponse.app_name) { $infoResponse.app_name } else { $infoResponse.name }
    $serviceVersion = $infoResponse.version
    Write-Host "      [OK] Gateway online! Service: $serviceName v$serviceVersion" -ForegroundColor Green
} catch {
    $errMsg = $_.Exception.Message
    Write-Host "      [WARN] Gateway /api/info check was unreachable ($errMsg)" -ForegroundColor Yellow
    Write-Host "      Continuing with secret update in case tunnel was just established..." -ForegroundColor DarkGray
}

# 4. Update Supabase Secret
Write-Host "[3/3] Updating Supabase secret SMS_GATEWAY_URL on project [$ProjectRef]..." -ForegroundColor Yellow

$cmdOutput = npx supabase secrets set "SMS_GATEWAY_URL=$TunnelUrl" --project-ref $ProjectRef 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] Supabase SMS_GATEWAY_URL secret updated successfully!" -ForegroundColor Green
    Write-Host "  New Tunnel URL:       $TunnelUrl" -ForegroundColor White
    Write-Host "  Supabase Edge Functions will route new OTP requests to this gateway immediately." -ForegroundColor White
    Write-Host "  NO Flutter changes or rebuilds required.`n" -ForegroundColor White
} else {
    Write-Host "Failed to update Supabase secret: $cmdOutput" -ForegroundColor Red
    exit 1
}
