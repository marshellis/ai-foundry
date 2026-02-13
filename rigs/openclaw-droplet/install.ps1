<#
.SYNOPSIS
    OpenClaw on DigitalOcean - Remote Installer for Windows

.DESCRIPTION
    Runs on your LOCAL Windows machine and SSHs into your DigitalOcean
    droplet to set up OpenClaw with WhatsApp, Telegram, and Gmail.

    Features:
    - Can create a new droplet using doctl (DigitalOcean CLI)
    - Or connect to an existing droplet
    - Saves progress to a local checkpoint file
    - Can resume from where it left off if interrupted
    - Run with -Reset to start fresh

    Usage:
        irm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/openclaw-droplet/install.ps1 | iex

.PARAMETER Reset
    Clear checkpoint and start fresh

.NOTES
    Requires: OpenSSH client (built into Windows 10+)
    Optional: doctl (DigitalOcean CLI) for droplet creation
#>

param(
    [switch]$Reset
)

$ErrorActionPreference = "Stop"
$ScriptVersion = "1.4.2"
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

function Write-Info {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Gray
}

# -------------------------------------------------------
# Checkpoint functions
# -------------------------------------------------------
function Save-Checkpoint {
    param(
        [int]$Step,
        [string]$DropletIP = "",
        [string]$SSHUser = "root",
        [string]$DropletId = "",
        [string]$DropletName = ""
    )
    $checkpoint = @{
        Step = $Step
        DropletIP = $DropletIP
        SSHUser = $SSHUser
        DropletId = $DropletId
        DropletName = $DropletName
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
$DropletId = if ($Checkpoint) { $Checkpoint.DropletId } else { "" }
$DropletName = if ($Checkpoint) { $Checkpoint.DropletName } else { "" }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OpenClaw on DigitalOcean" -ForegroundColor Cyan
Write-Host "  Local installer v$ScriptVersion" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This installer runs on your LOCAL machine and"
Write-Host "SSHs into your DigitalOcean droplet to set up OpenClaw."
Write-Host ""
Write-Host "The droplet setup script is always re-downloaded" -ForegroundColor Gray
Write-Host "from GitHub to ensure you have the latest version." -ForegroundColor Gray
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
    Write-Step "Step 1/6: Checking local prerequisites"

    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Fail "ssh is not available"
        Write-Host "    OpenSSH should be built into Windows 10+"
        Write-Host "    Try: Settings > Apps > Optional Features > OpenSSH Client"
        exit 1
    }
    Write-Ok "ssh available"

    # Check for doctl (optional - for droplet management)
    $doctlAvailable = $false
    if (Get-Command doctl -ErrorAction SilentlyContinue) {
        # Check if authenticated
        try {
            $authCheck = doctl account get --format Email --no-header 2>&1
            if ($LASTEXITCODE -eq 0) {
                $doctlAvailable = $true
                Write-Ok "doctl available and authenticated as $authCheck"
            } else {
                Write-Warn "doctl found but not authenticated"
                Write-Info "Run 'doctl auth init' to authenticate"
            }
        } catch {
            Write-Warn "doctl found but not authenticated"
        }
    } else {
        Write-Info "doctl not found (optional - for automated droplet creation)"
        Write-Info "Install from: https://docs.digitalocean.com/reference/doctl/how-to/install/"
    }

    # Check for gcloud CLI (required for Gmail channel setup)
    $gcloudAvailable = $false
    if (Get-Command gcloud -ErrorAction SilentlyContinue) {
        $oldErrorAction = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        $gcloudVersion = & gcloud version --format="value(Google Cloud SDK)" 2>&1
        $ErrorActionPreference = $oldErrorAction
        if ($LASTEXITCODE -eq 0) {
            $gcloudAvailable = $true
            Write-Ok "gcloud CLI available ($gcloudVersion)"
        } else {
            $gcloudAvailable = $true
            Write-Ok "gcloud CLI available"
        }
    } else {
        Write-Warn "gcloud CLI not found (required for Gmail channel setup)"
        Write-Host ""
        Write-Host "    The Gmail channel requires gcloud CLI on your local machine" -ForegroundColor Yellow
        Write-Host "    to complete authentication from the headless droplet."
        Write-Host ""

        # Check if chocolatey is available
        $chocoAvailable = $null -ne (Get-Command choco -ErrorAction SilentlyContinue)

        if ($chocoAvailable) {
            Write-Host "    How would you like to install gcloud?" -ForegroundColor Cyan
            Write-Host "    1) Install via Chocolatey (recommended)"
            Write-Host "    2) Skip -- I'll install it manually later"
            Write-Host "       Download: https://cloud.google.com/sdk/docs/install"
            Write-Host ""
            $installChoice = Read-Host "    Enter choice (1 or 2)"

            if ($installChoice -eq "1") {
                Write-Host ""
                Write-Host "    Installing Google Cloud SDK via Chocolatey..." -ForegroundColor Cyan
                Write-Host "    (This may take a few minutes)" -ForegroundColor Gray
                Write-Host ""

                # Chocolatey install needs admin rights - check if we have them
                $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                if ($isAdmin) {
                    choco install gcloudsdk -y --source="https://community.chocolatey.org/api/v2/"
                } else {
                    Write-Host "    Running elevated install (you may see a UAC prompt)..." -ForegroundColor Yellow
                    Start-Process -FilePath "choco" -ArgumentList "install gcloudsdk -y --source=https://community.chocolatey.org/api/v2/" -Verb RunAs -Wait
                }

                # Refresh PATH so we can find gcloud
                $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
                $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
                $env:Path = (($machinePath + ';' + $userPath) -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'

                if (Get-Command gcloud -ErrorAction SilentlyContinue) {
                    $gcloudAvailable = $true
                    Write-Ok "gcloud CLI installed successfully"
                } else {
                    Write-Warn "gcloud installed but not found in PATH"
                    Write-Host "    You may need to restart your terminal, then run this script again."
                }
            }
        } else {
            Write-Host "    Install gcloud CLI from:" -ForegroundColor Cyan
            Write-Host "    https://cloud.google.com/sdk/docs/install" -ForegroundColor Cyan
        }

        if (-not $gcloudAvailable) {
            Write-Host ""
            Write-Host "    You can continue without gcloud, but Gmail setup will" -ForegroundColor Yellow
            Write-Host "    require you to install it before that step." -ForegroundColor Yellow
            Write-Host ""
            $continueChoice = Read-Host "    Continue without gcloud? (y/n)"
            if ($continueChoice -ne "y" -and $continueChoice -ne "Y") {
                Write-Host ""
                Write-Host "    Install gcloud, then run this script again." -ForegroundColor Cyan
                exit 0
            }
        }
    }

    Save-Checkpoint -Step 1
    $CurrentStep = 1
}

# -------------------------------------------------------
# Step 2: Get or create droplet
# -------------------------------------------------------
if ($CurrentStep -lt 2) {
    Write-Step "Step 2/6: Droplet setup"
    
    $skipDropletCreation = $false
    
    # Check if we already have droplet info from a previous interrupted run
    if ($DropletIP -and $DropletId) {
        Write-Host ""
        Write-Host "    Found existing droplet from previous run:" -ForegroundColor Yellow
        Write-Host "    IP: $DropletIP"
        Write-Host "    ID: $DropletId"
        Write-Host ""
        $useExisting = Read-Host "    Use this droplet? (y/n)"
        
        if ($useExisting -eq "y" -or $useExisting -eq "Y") {
            Write-Ok "Using existing droplet"
            $skipDropletCreation = $true
            $SSHUser = "root"
        } else {
            # Clear the old droplet info
            $DropletIP = ""
            $DropletId = ""
            $DropletName = ""
        }
    }
    
    if (-not $skipDropletCreation) {
    # Re-check doctl availability and handle authentication
    $doctlAvailable = $false
    if (Get-Command doctl -ErrorAction SilentlyContinue) {
        # Temporarily allow errors so doctl failure doesn't stop the script
        $oldErrorAction = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        $authCheck = & doctl account get --format Email --no-header 2>&1
        $authExitCode = $LASTEXITCODE
        $ErrorActionPreference = $oldErrorAction
        
        if ($authExitCode -eq 0 -and $authCheck -notmatch "Error:") {
            $doctlAvailable = $true
            Write-Ok "doctl authenticated as $authCheck"
        } else {
            # doctl exists but not authenticated - offer to authenticate
            Write-Host ""
            Write-Host "    doctl is installed but not authenticated." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "    To authenticate, you need a DigitalOcean API token:"
            Write-Host "    1. Go to: https://cloud.digitalocean.com/account/api/tokens"
            Write-Host "    2. Click 'Generate New Token'"
            Write-Host "    3. Give it a name (e.g., 'doctl') and select read+write scopes"
            Write-Host "    4. Copy the token (you won't see it again)"
            Write-Host ""
            $authChoice = Read-Host "    Would you like to authenticate doctl now? (y/n)"
            
            if ($authChoice -eq "y" -or $authChoice -eq "Y") {
                Write-Host ""
                Write-Host "    Running 'doctl auth init'..." -ForegroundColor Cyan
                Write-Host "    Paste your API token when prompted:" -ForegroundColor Yellow
                Write-Host ""
                
                doctl auth init
                
                if ($LASTEXITCODE -eq 0) {
                    # Verify authentication worked
                    $authCheck = doctl account get --format Email --no-header 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $doctlAvailable = $true
                        Write-Host ""
                        Write-Ok "doctl authenticated as $authCheck"
                    }
                }
                
                if (-not $doctlAvailable) {
                    Write-Host ""
                    Write-Warn "Authentication failed. Continuing with manual IP entry."
                }
            } else {
                Write-Info "Skipping doctl authentication. You can enter a droplet IP manually."
            }
        }
    }

    if ($doctlAvailable) {
        Write-Host ""
        Write-Host "    How would you like to proceed?" -ForegroundColor Yellow
        Write-Host "    1) Create a new droplet (using doctl)"
        Write-Host "    2) Use an existing droplet (enter IP manually)"
        Write-Host ""
        $choice = Read-Host "    Enter choice (1 or 2)"

        if ($choice -eq "1") {
            # Create new droplet flow
            Write-Host ""
            Write-Host "    Creating a new DigitalOcean droplet..." -ForegroundColor Cyan
            Write-Host ""

            # Get SSH keys
            Write-Host "    Fetching your SSH keys..."
            $oldErrorAction = $ErrorActionPreference
            $ErrorActionPreference = "SilentlyContinue"
            $sshKeys = & doctl compute ssh-key list --format ID,Name,FingerPrint --no-header 2>&1
            $sshKeysExitCode = $LASTEXITCODE
            $ErrorActionPreference = $oldErrorAction
            
            if ($sshKeysExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($sshKeys) -or $sshKeys -match "Error:") {
                Write-Warn "No SSH keys found in your DigitalOcean account"
                Write-Host ""
                Write-Host "    You need an SSH key to access your droplet." -ForegroundColor Yellow
                Write-Host "    Let's add one now."
                Write-Host ""
                
                # Check for local SSH key
                $sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub"
                $sshKeyPathEd = "$env:USERPROFILE\.ssh\id_ed25519.pub"
                $localKeyPath = $null
                
                if (Test-Path $sshKeyPathEd) {
                    $localKeyPath = $sshKeyPathEd
                    Write-Ok "Found local SSH key: $sshKeyPathEd"
                } elseif (Test-Path $sshKeyPath) {
                    $localKeyPath = $sshKeyPath
                    Write-Ok "Found local SSH key: $sshKeyPath"
                } else {
                    Write-Host "    No local SSH key found. Let's create one."
                    Write-Host ""
                    $createKey = Read-Host "    Create a new SSH key? (y/n)"
                    
                    if ($createKey -eq "y" -or $createKey -eq "Y") {
                        Write-Host ""
                        Write-Host "    Creating SSH key..." -ForegroundColor Cyan
                        
                        # Create .ssh directory if needed
                        $sshDir = "$env:USERPROFILE\.ssh"
                        if (-not (Test-Path $sshDir)) {
                            New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
                        }
                        
                        # Generate key (non-interactive with empty passphrase)
                        ssh-keygen -t ed25519 -f "$sshDir\id_ed25519" -N '""' -C "openclaw-droplet"
                        
                        if (Test-Path $sshKeyPathEd) {
                            $localKeyPath = $sshKeyPathEd
                            Write-Ok "SSH key created: $sshKeyPathEd"
                        } else {
                            Write-Fail "Failed to create SSH key"
                            Write-Host "    You can create one manually with: ssh-keygen -t ed25519"
                            exit 1
                        }
                    } else {
                        Write-Host ""
                        Write-Host "    To create an SSH key manually:"
                        Write-Host "      ssh-keygen -t ed25519"
                        Write-Host ""
                        Write-Host "    Then run this installer again."
                        exit 1
                    }
                }
                
                # Upload key to DigitalOcean
                Write-Host ""
                $keyName = Read-Host "    Name for this key in DigitalOcean (default: openclaw-key)"
                if ([string]::IsNullOrWhiteSpace($keyName)) {
                    $keyName = "openclaw-key"
                }
                
                Write-Host "    Uploading SSH key to DigitalOcean..." -ForegroundColor Cyan
                $oldErrorAction = $ErrorActionPreference
                $ErrorActionPreference = "SilentlyContinue"
                $uploadResult = & doctl compute ssh-key import $keyName --public-key-file $localKeyPath 2>&1
                $uploadExitCode = $LASTEXITCODE
                $ErrorActionPreference = $oldErrorAction
                
                if ($uploadExitCode -eq 0 -and $uploadResult -notmatch "Error:") {
                    Write-Ok "SSH key uploaded to DigitalOcean"
                    
                    # Re-fetch keys
                    $sshKeys = & doctl compute ssh-key list --format ID,Name,FingerPrint --no-header 2>&1
                } else {
                    Write-Fail "Failed to upload SSH key"
                    Write-Host "    Error: $uploadResult"
                    Write-Host ""
                    Write-Host "    You can upload manually at: https://cloud.digitalocean.com/account/security"
                    exit 1
                }
            }

            Write-Host ""
            Write-Host "    Available SSH keys:" -ForegroundColor Yellow
            $keyLines = $sshKeys -split "`n" | Where-Object { $_ -match '\S' }
            $keyIndex = 1
            $keyMap = @{}
            foreach ($line in $keyLines) {
                $parts = $line -split '\s+', 3
                $keyId = $parts[0]
                $keyName = if ($parts.Length -gt 1) { $parts[1] } else { "unnamed" }
                Write-Host "    $keyIndex) $keyName (ID: $keyId)"
                $keyMap[$keyIndex] = $keyId
                $keyIndex++
            }

            Write-Host ""
            $keyChoice = Read-Host "    Select SSH key number"
            if (-not $keyMap.ContainsKey([int]$keyChoice)) {
                Write-Fail "Invalid selection"
                exit 1
            }
            $selectedKeyId = $keyMap[[int]$keyChoice]
            Write-Ok "Selected SSH key ID: $selectedKeyId"

            # Get regions
            Write-Host ""
            Write-Host "    Fetching available regions..."
            $regions = doctl compute region list --format Slug,Name,Available --no-header 2>&1
            $availableRegions = $regions -split "`n" | Where-Object { $_ -match 'true$' }

            Write-Host ""
            Write-Host "    Available regions:" -ForegroundColor Yellow
            $regionIndex = 1
            $regionMap = @{}
            # Show common regions first
            $commonRegions = @("nyc1", "nyc3", "sfo3", "lon1", "ams3", "sgp1", "fra1", "tor1", "blr1", "syd1")
            foreach ($slug in $commonRegions) {
                $match = $availableRegions | Where-Object { $_ -match "^$slug\s" }
                if ($match) {
                    $parts = ($match -split '\s+', 3)
                    $regionSlug = $parts[0]
                    $regionName = if ($parts.Length -gt 1) { $parts[1] } else { $regionSlug }
                    Write-Host "    $regionIndex) $regionName ($regionSlug)"
                    $regionMap[$regionIndex] = $regionSlug
                    $regionIndex++
                }
            }

            Write-Host ""
            $regionChoice = Read-Host "    Select region number"
            if (-not $regionMap.ContainsKey([int]$regionChoice)) {
                Write-Fail "Invalid selection"
                exit 1
            }
            $selectedRegion = $regionMap[[int]$regionChoice]
            Write-Ok "Selected region: $selectedRegion"

            # Droplet name
            Write-Host ""
            $defaultName = "openclaw-$(Get-Date -Format 'yyyyMMdd')"
            $inputName = Read-Host "    Droplet name (default: $defaultName)"
            $DropletName = if ([string]::IsNullOrWhiteSpace($inputName)) { $defaultName } else { $inputName }

            # Create the droplet
            Write-Host ""
            Write-Host "    Creating droplet '$DropletName'..." -ForegroundColor Yellow
            Write-Host "    - Size: s-1vcpu-1gb (1 vCPU, 1GB RAM, 25GB SSD) - `$6/month"
            Write-Host "    - Image: Ubuntu 24.04 LTS"
            Write-Host "    - Region: $selectedRegion"
            Write-Host ""

            $createResult = doctl compute droplet create $DropletName `
                --size s-1vcpu-1gb `
                --image ubuntu-24-04-x64 `
                --region $selectedRegion `
                --ssh-keys $selectedKeyId `
                --format ID,Name,PublicIPv4,Status `
                --no-header `
                --wait 2>&1

            if ($LASTEXITCODE -ne 0) {
                Write-Fail "Failed to create droplet"
                Write-Host "    Error: $createResult"
                exit 1
            }

            # Parse the result
            $parts = $createResult -split '\s+'
            $DropletId = $parts[0]
            $DropletIP = $parts[2]

            Write-Ok "Droplet created!"
            Write-Host "    ID: $DropletId"
            Write-Host "    IP: $DropletIP"
            
            # Save checkpoint immediately so we don't lose the droplet info
            $SSHUser = "root"
            Save-Checkpoint -Step 1 -DropletIP $DropletIP -SSHUser $SSHUser -DropletId $DropletId -DropletName $DropletName
            Write-Info "Droplet info saved - if interrupted, run script again to resume"

            # Wait for SSH to be ready
            Write-Host ""
            Write-Host "    Waiting for SSH to become available..." -ForegroundColor Yellow
            $maxAttempts = 30
            $attempt = 0
            $sshReady = $false

            while ($attempt -lt $maxAttempts -and -not $sshReady) {
                $attempt++
                Start-Sleep -Seconds 5
                Write-Host "    Attempt $attempt/$maxAttempts..." -NoNewline

                $oldErrorAction = $ErrorActionPreference
                $ErrorActionPreference = "SilentlyContinue"
                $testResult = & ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes "root@$DropletIP" "echo ready" 2>&1
                $sshExitCode = $LASTEXITCODE
                $ErrorActionPreference = $oldErrorAction
                
                if ($sshExitCode -eq 0 -and $testResult -match "ready") {
                    $sshReady = $true
                    Write-Host " Ready!" -ForegroundColor Green
                } else {
                    Write-Host " Not yet"
                }
            }

            if (-not $sshReady) {
                Write-Warn "SSH not ready after $maxAttempts attempts"
                Write-Host "    The droplet may still be initializing."
                Write-Host "    Try running this script again in a minute."
                Save-Checkpoint -Step 1 -DropletIP $DropletIP -SSHUser "root" -DropletId $DropletId -DropletName $DropletName
                exit 1
            }

            $SSHUser = "root"
        } else {
            # Use existing droplet - list available droplets
            Write-Host ""
            Write-Host "    Fetching your existing droplets..." -ForegroundColor Cyan
            $oldErrorAction = $ErrorActionPreference
            $ErrorActionPreference = "SilentlyContinue"
            $droplets = & doctl compute droplet list --format ID,Name,PublicIPv4,Region,Status --no-header 2>&1
            $dropletsExitCode = $LASTEXITCODE
            $ErrorActionPreference = $oldErrorAction

            if ($dropletsExitCode -eq 0 -and $droplets -and $droplets.Trim()) {
                $dropletLines = $droplets -split "`n" | Where-Object { $_.Trim() }
                
                if ($dropletLines.Count -gt 0) {
                    Write-Host ""
                    Write-Host "    Your existing droplets:" -ForegroundColor Yellow
                    Write-Host "    ---------------------------------------------------------------"
                    Write-Host "    #   Name                    IP               Region    Status"
                    Write-Host "    ---------------------------------------------------------------"
                    
                    $dropletIndex = 1
                    $dropletMap = @{}
                    foreach ($line in $dropletLines) {
                        $parts = $line -split '\s+'
                        if ($parts.Count -ge 4) {
                            $dId = $parts[0]
                            $dName = $parts[1]
                            $dIP = $parts[2]
                            $dRegion = $parts[3]
                            $dStatus = if ($parts.Count -ge 5) { $parts[4] } else { "unknown" }
                            
                            $displayName = if ($dName.Length -gt 20) { $dName.Substring(0, 17) + "..." } else { $dName.PadRight(20) }
                            $displayIP = $dIP.PadRight(15)
                            $displayRegion = $dRegion.PadRight(8)
                            
                            Write-Host "    $dropletIndex)  $displayName  $displayIP  $displayRegion  $dStatus"
                            $dropletMap[$dropletIndex] = @{ ID = $dId; Name = $dName; IP = $dIP }
                            $dropletIndex++
                        }
                    }
                    Write-Host "    ---------------------------------------------------------------"
                    Write-Host "    0)  Enter IP manually"
                    Write-Host ""
                    
                    $dropletChoice = Read-Host "    Select droplet number (or 0 for manual)"
                    
                    if ($dropletChoice -eq "0" -or [string]::IsNullOrWhiteSpace($dropletChoice)) {
                        Write-Host ""
                        $DropletIP = Read-Host "    Enter your droplet IP address"
                        $SSHUser = "root"
                    } elseif ($dropletMap.ContainsKey([int]$dropletChoice)) {
                        $selected = $dropletMap[[int]$dropletChoice]
                        $DropletIP = $selected.IP
                        $DropletId = $selected.ID
                        $DropletName = $selected.Name
                        $SSHUser = "root"
                        Write-Ok "Selected: $DropletName ($DropletIP)"
                    } else {
                        Write-Fail "Invalid selection"
                        exit 1
                    }
                } else {
                    Write-Info "No existing droplets found"
                    Write-Host ""
                    $DropletIP = Read-Host "    Enter your droplet IP address"
                    $SSHUser = "root"
                }
            } else {
                Write-Info "Could not fetch droplets"
                Write-Host ""
                $DropletIP = Read-Host "    Enter your droplet IP address"
                $SSHUser = "root"
            }

            if ([string]::IsNullOrWhiteSpace($DropletIP)) {
                Write-Fail "No IP address provided"
                exit 1
            }
        }
    } else {
        # No doctl - manual entry only
        Write-Host ""
        Write-Host "    To create a droplet automatically, install doctl:" -ForegroundColor Gray
        Write-Host "    https://docs.digitalocean.com/reference/doctl/how-to/install/" -ForegroundColor Gray
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
    }
    } # End of: if (-not $skipDropletCreation)

    Save-Checkpoint -Step 2 -DropletIP $DropletIP -SSHUser $SSHUser -DropletId $DropletId -DropletName $DropletName
    $CurrentStep = 2
}

# -------------------------------------------------------
# Step 3: Test SSH connection
# -------------------------------------------------------
if ($CurrentStep -lt 3) {
    Write-Step "Step 3/6: Testing SSH connection"

    Write-Host "    Connecting to $SSHUser@$DropletIP..."

    try {
        $testResult = ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes "$SSHUser@$DropletIP" "echo 'SSH OK'" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Key-based auth failed"
        }
        Write-Ok "SSH connection verified (key-based)"
    } catch {
        Write-Warn "Key-based auth failed, will try interactive..."
        Write-Host "    You may be prompted for a password."
        
        $testResult = ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSHUser@$DropletIP" "echo 'SSH OK'" 2>&1
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

    Save-Checkpoint -Step 3 -DropletIP $DropletIP -SSHUser $SSHUser -DropletId $DropletId -DropletName $DropletName
    $CurrentStep = 3
}

# -------------------------------------------------------
# Step 4/5: Download latest setup script and run on droplet
# -------------------------------------------------------
if ($CurrentStep -lt 5) {
    # Always re-download the droplet script to ensure latest version
    Write-Step "Step 4/6: Downloading latest setup script to droplet"

    $oldErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    # Download script via GitHub API (avoids raw.githubusercontent.com CDN caching)
    $apiUrl = "https://api.github.com/repos/marshellis/ai-foundry/contents/rigs/openclaw-droplet/droplet-setup.sh?ref=main"
    $downloadResult = & ssh -o StrictHostKeyChecking=no "$SSHUser@$DropletIP" "curl -fsSL -H 'Accept: application/vnd.github.v3.raw' '$apiUrl' | sed 's/\r$//' > /tmp/openclaw-setup.sh && chmod +x /tmp/openclaw-setup.sh && echo 'DOWNLOAD_OK'" 2>&1
    $downloadExitCode = $LASTEXITCODE
    $ErrorActionPreference = $oldErrorAction
    
    if ($downloadExitCode -ne 0 -or $downloadResult -notmatch "DOWNLOAD_OK") {
        Write-Fail "Could not download setup script on droplet"
        Write-Host "    Error: $downloadResult"
        exit 1
    }

    # Fetch the droplet script version for display
    $oldErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $dropletScriptVersion = & ssh -o StrictHostKeyChecking=no "$SSHUser@$DropletIP" "grep 'SCRIPT_VERSION=' /tmp/openclaw-setup.sh | head -1 | cut -d'""' -f2" 2>&1
    $ErrorActionPreference = $oldErrorAction
    if ($dropletScriptVersion) {
        Write-Ok "Setup script v$dropletScriptVersion downloaded to droplet"
    } else {
        Write-Ok "Setup script downloaded to droplet"
    }

    Save-Checkpoint -Step 4 -DropletIP $DropletIP -SSHUser $SSHUser -DropletId $DropletId -DropletName $DropletName
    $CurrentStep = 4

    Write-Step "Step 5/6: Running setup on droplet"

    Write-Host ""
    Write-Host "    The setup will now run on your droplet." -ForegroundColor Yellow
    Write-Host "    This may take several minutes." -ForegroundColor Yellow
    Write-Host "    If interrupted, run this script again to resume." -ForegroundColor Yellow
    Write-Host ""

    # Run the setup script interactively
    # The droplet script has its own checkpointing
    ssh -o StrictHostKeyChecking=no -t "$SSHUser@$DropletIP" "bash /tmp/openclaw-setup.sh"
    $sshExitCode = $LASTEXITCODE

    # Always save checkpoint with droplet info so we don't lose state
    Save-Checkpoint -Step 5 -DropletIP $DropletIP -SSHUser $SSHUser -DropletId $DropletId -DropletName $DropletName
    $CurrentStep = 5

    if ($sshExitCode -ne 0) {
        Write-Warn "Setup may not have completed successfully (exit code: $sshExitCode)"
        Write-Host "    Run this script again to retry/resume"
    }
}

# -------------------------------------------------------
# Step 6: Final verification
# -------------------------------------------------------
if ($CurrentStep -lt 6) {
    Write-Step "Step 6/6: Verifying installation"

    $verifyResult = ssh -o StrictHostKeyChecking=no "$SSHUser@$DropletIP" "openclaw --version" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "OpenClaw installed: $verifyResult"
    } else {
        Write-Warn "Could not verify OpenClaw installation"
    }

    Save-Checkpoint -Step 6 -DropletIP $DropletIP -SSHUser $SSHUser -DropletId $DropletId -DropletName $DropletName
    $CurrentStep = 6
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
if ($DropletId) {
    Write-Host "Droplet ID: " -NoNewline -ForegroundColor Cyan
    Write-Host "$DropletId"
}
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
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Droplet Management (doctl)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "List your droplets:" -ForegroundColor Gray
Write-Host "  doctl compute droplet list"
Write-Host ""
Write-Host "SSH into droplet:" -ForegroundColor Gray
Write-Host "  ssh $SSHUser@$DropletIP"
Write-Host ""
Write-Host "Delete droplet (when done):" -ForegroundColor Gray
if ($DropletId) {
    Write-Host "  doctl compute droplet delete $DropletId"
} else {
    Write-Host "  doctl compute droplet delete <droplet-id>"
}
Write-Host ""
