<#
.SYNOPSIS
    OpenClaw on DigitalOcean - Remote Installer for Windows

.DESCRIPTION
    Runs on your LOCAL Windows machine and SSHs into your DigitalOcean
    droplet to set up OpenClaw with WhatsApp, Telegram, and Gmail.

    Features:
    - Saves progress to a local checkpoint file
    - Can resume from where it left off if interrupted
    - Run with -Reset to start fresh

    Usage:
        irm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet/install.ps1 | iex

.PARAMETER Reset
    Clear checkpoint and start fresh

.NOTES
    Requires: OpenSSH client (built into Windows 10+)
#>

param(
    [switch]$Reset
)

$ErrorActionPreference = "Stop"
$ScriptVersion = "1.1.0"
$RigBaseUrl = "https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet"
$CheckpointFile = "$env:TEMP\openclaw-droplet-checkpoint.json"

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

# -------------------------------------------------------
# Checkpoint functions
# -------------------------------------------------------
function Save-Checkpoint {
    param(
        [int]$Step,
        [string]$DropletIP = "",
        [string]$SSHUser = "root"
    )
    $checkpoint = @{
        Step = $Step
        DropletIP = $DropletIP
        SSHUser = $SSHUser
        Timestamp = (Get-Date).ToString("o")
    }
    $checkpoint | ConvertTo-Json | Set-Content -Path $CheckpointFile -Encoding UTF8
    Write-Ok "Progress saved (step: $Step)"
}

function Load-Checkpoint {
    if (Test-Path $CheckpointFile) {
        try {
            $checkpoint = Get-Content $CheckpointFile -Raw | ConvertFrom-Json
            return $checkpoint
        } catch {
            return $null
        }
    }
    return $null
}

function Clear-Checkpoint {
    if (Test-Path $CheckpointFile) {
        Remove-Item $CheckpointFile -Force
    }
}

# Handle -Reset flag
if ($Reset) {
    Clear-Checkpoint
    Write-Host "Checkpoint cleared. Starting fresh."
}

# Load existing checkpoint
$Checkpoint = Load-Checkpoint
$CurrentStep = if ($Checkpoint) { $Checkpoint.Step } else { 0 }
$DropletIP = if ($Checkpoint) { $Checkpoint.DropletIP } else { "" }
$SSHUser = if ($Checkpoint) { $Checkpoint.SSHUser } else { "root" }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OpenClaw on DigitalOcean" -ForegroundColor Cyan
Write-Host "  Remote Installer v$ScriptVersion" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This installer runs on your LOCAL machine and"
Write-Host "SSHs into your DigitalOcean droplet to set up OpenClaw."
Write-Host ""

if ($CurrentStep -gt 0) {
    Write-Host "Resuming from step $CurrentStep" -ForegroundColor Yellow
    if ($DropletIP) {
        Write-Host "Droplet: $SSHUser@$DropletIP" -ForegroundColor Yellow
    }
    Write-Host "Run with -Reset to start fresh" -ForegroundColor Yellow
    Write-Host ""
}

# -------------------------------------------------------
# Step 1: Check local prerequisites
# -------------------------------------------------------
if ($CurrentStep -lt 1) {
    Write-Step "Step 1/5: Checking local prerequisites"

    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Fail "ssh is not available"
        Write-Host "    OpenSSH should be built into Windows 10+"
        Write-Host "    Try: Settings > Apps > Optional Features > OpenSSH Client"
        exit 1
    }
    Write-Ok "ssh available"

    Save-Checkpoint -Step 1
    $CurrentStep = 1
}

# -------------------------------------------------------
# Step 2: Get droplet information
# -------------------------------------------------------
if ($CurrentStep -lt 2) {
    Write-Step "Step 2/5: Droplet connection details"

    Write-Host ""
    $DropletIP = Read-Host "    Enter your droplet IP address"

    if ([string]::IsNullOrWhiteSpace($DropletIP)) {
        Write-Fail "No IP address provided"
        exit 1
    }

    $inputUser = Read-Host "    SSH username (default: root)"
    if (-not [string]::IsNullOrWhiteSpace($inputUser)) {
        $SSHUser = $inputUser
    }

    Save-Checkpoint -Step 2 -DropletIP $DropletIP -SSHUser $SSHUser
    $CurrentStep = 2
}

# -------------------------------------------------------
# Step 3: Test SSH connection
# -------------------------------------------------------
if ($CurrentStep -lt 3) {
    Write-Step "Step 3/5: Testing SSH connection"

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

    Save-Checkpoint -Step 3 -DropletIP $DropletIP -SSHUser $SSHUser
    $CurrentStep = 3
}

# -------------------------------------------------------
# Step 4: Download and upload setup script
# -------------------------------------------------------
if ($CurrentStep -lt 4) {
    Write-Step "Step 4/5: Downloading and uploading setup script"

    try {
        $SetupScript = Invoke-RestMethod "$RigBaseUrl/droplet-setup.sh"
        Write-Ok "Setup script downloaded"
    } catch {
        Write-Fail "Could not download droplet-setup.sh"
        Write-Host "    Error: $_"
        exit 1
    }

    # Write script to temp file, then upload
    $TempFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $TempFile -Value $SetupScript -Encoding UTF8

    Write-Host "    Uploading to droplet..."

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

    Save-Checkpoint -Step 4 -DropletIP $DropletIP -SSHUser $SSHUser
    $CurrentStep = 4
}

# -------------------------------------------------------
# Step 5: Execute setup on droplet
# -------------------------------------------------------
if ($CurrentStep -lt 5) {
    Write-Step "Step 5/5: Running setup on droplet"

    Write-Host ""
    Write-Host "    The setup will now run on your droplet." -ForegroundColor Yellow
    Write-Host "    This may take several minutes." -ForegroundColor Yellow
    Write-Host "    If interrupted, run this script again to resume." -ForegroundColor Yellow
    Write-Host ""

    # Run the setup script interactively
    # The droplet script has its own checkpointing
    ssh -t "$SSHUser@$DropletIP" "bash /tmp/openclaw-setup.sh"

    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Setup may not have completed successfully"
        Write-Host "    Run this script again to retry/resume"
        exit 1
    }

    Save-Checkpoint -Step 5 -DropletIP $DropletIP -SSHUser $SSHUser
    $CurrentStep = 5
}

# -------------------------------------------------------
# Done - Clear checkpoint and print guide
# -------------------------------------------------------
Clear-Checkpoint

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
