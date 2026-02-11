<#
.SYNOPSIS
    OpenClaw on DigitalOcean - Remote Installer for Windows

.DESCRIPTION
    Runs on your LOCAL Windows machine and SSHs into your DigitalOcean
    droplet to set up OpenClaw with WhatsApp, Telegram, and Gmail.

    Usage:
        irm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet/install.ps1 | iex

.NOTES
    Requires: OpenSSH client (built into Windows 10+)
#>

$ErrorActionPreference = "Stop"
$ScriptVersion = "1.0.0"
$RigBaseUrl = "https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "--- $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    OK: $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    WARN: $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "    FAIL: $Message" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OpenClaw on DigitalOcean" -ForegroundColor Cyan
Write-Host "  Remote Installer v$ScriptVersion" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This installer runs on your LOCAL machine and"
Write-Host "SSHs into your DigitalOcean droplet to set up OpenClaw."
Write-Host ""

# -------------------------------------------------------
# Step 1: Check local prerequisites
# -------------------------------------------------------
Write-Step "Checking local prerequisites"

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Fail "ssh is not available"
    Write-Host "    OpenSSH should be built into Windows 10+"
    Write-Host "    Try: Settings > Apps > Optional Features > OpenSSH Client"
    exit 1
}
Write-Ok "ssh available"

# -------------------------------------------------------
# Step 2: Get droplet information
# -------------------------------------------------------
Write-Step "Droplet connection details"

Write-Host ""
$DropletIP = Read-Host "    Enter your droplet IP address"

if ([string]::IsNullOrWhiteSpace($DropletIP)) {
    Write-Fail "No IP address provided"
    exit 1
}

$SSHUser = Read-Host "    SSH username (default: root)"
if ([string]::IsNullOrWhiteSpace($SSHUser)) {
    $SSHUser = "root"
}

# -------------------------------------------------------
# Step 3: Test SSH connection
# -------------------------------------------------------
Write-Step "Testing SSH connection"

Write-Host "    Connecting to $SSHUser@$DropletIP..."

try {
    $testResult = ssh -o ConnectTimeout=10 -o BatchMode=yes "$SSHUser@$DropletIP" "echo 'SSH OK'" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Key-based auth failed"
    }
    Write-Ok "SSH connection verified (key-based)"
} catch {
    Write-Warn "Key-based auth failed, will try interactive..."
    Write-Host "    You may be prompted for a password."
    
    $testResult = ssh -o ConnectTimeout=10 "$SSHUser@$DropletIP" "echo 'SSH OK'" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Could not connect to $SSHUser@$DropletIP"
        Write-Host ""
        Write-Host "    Make sure:"
        Write-Host "    1. The droplet is running"
        Write-Host "    2. The IP address is correct"
        Write-Host "    3. SSH is enabled on the droplet"
        Write-Host "    4. Your SSH key is added or you know the password"
        exit 1
    }
    Write-Ok "SSH connection verified (password)"
}

# -------------------------------------------------------
# Step 4: Download and upload setup script
# -------------------------------------------------------
Write-Step "Downloading setup script"

try {
    $SetupScript = Invoke-RestMethod "$RigBaseUrl/droplet-setup.sh"
    Write-Ok "Setup script downloaded"
} catch {
    Write-Fail "Could not download droplet-setup.sh"
    Write-Host "    Error: $_"
    exit 1
}

Write-Step "Uploading setup script to droplet"

# Write script to temp file, then upload
$TempFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $TempFile -Value $SetupScript -Encoding UTF8

# Use scp to upload
scp -o ConnectTimeout=10 $TempFile "${SSHUser}@${DropletIP}:/tmp/openclaw-setup.sh" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    # Fallback: pipe through ssh
    Get-Content $TempFile -Raw | ssh "$SSHUser@$DropletIP" "cat > /tmp/openclaw-setup.sh"
}

# Make executable
ssh "$SSHUser@$DropletIP" "chmod +x /tmp/openclaw-setup.sh" 2>&1 | Out-Null

Remove-Item $TempFile -Force
Write-Ok "Setup script uploaded to /tmp/openclaw-setup.sh"

# -------------------------------------------------------
# Step 5: Execute setup on droplet
# -------------------------------------------------------
Write-Step "Running setup on droplet"

Write-Host ""
Write-Host "    The setup will now run on your droplet." -ForegroundColor Yellow
Write-Host "    This may take several minutes." -ForegroundColor Yellow
Write-Host ""

# Run the setup script interactively
ssh -t "$SSHUser@$DropletIP" "bash /tmp/openclaw-setup.sh"

# -------------------------------------------------------
# Done - Print channel setup guide
# -------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Base installation complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your droplet IP: " -NoNewline -ForegroundColor Cyan
Write-Host "$DropletIP"
Write-Host ""
Write-Host "To access the Control UI:" -ForegroundColor Cyan
Write-Host "  ssh -L 18789:localhost:18789 $SSHUser@$DropletIP"
Write-Host "  Then open: http://localhost:18789"
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Channel Setup Guide" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. WhatsApp Setup" -ForegroundColor Yellow
Write-Host "   First, get a dedicated phone number (see README for options):"
Write-Host "   - Google Voice (US, free): voice.google.com"
Write-Host "   - Prepaid SIM card (`$10-20)"
Write-Host "   - Twilio number (~`$1/month)"
Write-Host ""
Write-Host "   Then link WhatsApp:"
Write-Host "   ssh $SSHUser@$DropletIP"
Write-Host "   openclaw channels login --channel whatsapp"
Write-Host "   # Scan the QR code with WhatsApp on your dedicated number"
Write-Host ""
Write-Host "2. Telegram Setup" -ForegroundColor Yellow
Write-Host "   a) Open Telegram and message @BotFather"
Write-Host "   b) Send /newbot and follow the prompts"
Write-Host "   c) Copy the bot token (format: 123456789:ABCdef...)"
Write-Host "   d) Configure OpenClaw:"
Write-Host "      ssh $SSHUser@$DropletIP"
Write-Host "      openclaw channels add --channel telegram --token <YOUR_BOT_TOKEN>"
Write-Host ""
Write-Host "3. Gmail Setup (requires GCP project)" -ForegroundColor Yellow
Write-Host "   See the full guide in the README or run:"
Write-Host "   ssh $SSHUser@$DropletIP"
Write-Host "   openclaw webhooks gmail setup --account your-assistant@gmail.com"
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  https://docs.openclaw.ai/channels/whatsapp"
Write-Host "  https://docs.openclaw.ai/channels/telegram"
Write-Host "  https://docs.openclaw.ai/automation/gmail-pubsub"
Write-Host ""
