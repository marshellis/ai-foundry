<#
.SYNOPSIS
    Local setup script for the Igor rig.

.DESCRIPTION
    If you already have the rig files locally (e.g., you cloned ai-foundry),
    this script sets up Igor in a target repository.

    For a one-command install that downloads everything automatically, use:
        irm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.ps1 | iex

    This script can also be used when the install script is not suitable
    (e.g., air-gapped environments, custom rig modifications).

.PARAMETER RepoOwner
    The GitHub organization or user that owns the target repository.

.PARAMETER RepoName
    The name of the target GitHub repository.

.PARAMETER ApiKey
    The Anthropic API key. If not provided, the script will prompt for it.

.PARAMETER SkipIssue
    Skip creating the sample tracking issue.

.PARAMETER TargetDir
    The target repository directory. Defaults to current directory.

.EXAMPLE
    .\setup.ps1 -RepoOwner myorg -RepoName myrepo

.EXAMPLE
    .\setup.ps1 -RepoOwner myorg -RepoName myrepo -TargetDir C:\projects\myrepo
#>

param(
    [string]$RepoOwner,
    [string]$RepoName,
    [string]$ApiKey,
    [string]$TargetDir,
    [switch]$SkipIssue
)

$ErrorActionPreference = "Stop"

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
Write-Host "  Igor -- Local Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# -------------------------------------------------------
# Step 1: Check prerequisites
# -------------------------------------------------------
Write-Step "Checking prerequisites"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Fail "GitHub CLI (gh) is not installed."
    Write-Host "    Install it from: https://cli.github.com/"
    exit 1
}
Write-Ok "GitHub CLI (gh) found"

$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Not authenticated with GitHub CLI."
    Write-Host "    Run: gh auth login"
    exit 1
}
Write-Ok "Authenticated with GitHub"

# -------------------------------------------------------
# Step 2: Determine target repo
# -------------------------------------------------------
Write-Step "Determining target repository"

# Auto-detect if not provided
if (-not $RepoOwner -or -not $RepoName) {
    $detectDir = if ($TargetDir) { $TargetDir } else { Get-Location }
    Push-Location $detectDir
    $remoteUrl = git remote get-url origin 2>&1
    Pop-Location

    if ($LASTEXITCODE -eq 0 -and $remoteUrl -match "github\.com[:/]([^/]+)/([^/.]+)") {
        $detectedOwner = $Matches[1]
        $detectedName = $Matches[2]
        Write-Host "    Detected: $detectedOwner/$detectedName" -ForegroundColor Yellow
        $confirm = Read-Host "    Use this repository? (Y/n)"
        if ($confirm -ne "n" -and $confirm -ne "N") {
            $RepoOwner = $detectedOwner
            $RepoName = $detectedName
        }
    }

    if (-not $RepoOwner) {
        $RepoOwner = Read-Host "    Enter repository owner"
    }
    if (-not $RepoName) {
        $RepoName = Read-Host "    Enter repository name"
    }
}

$Repo = "$RepoOwner/$RepoName"

$repoCheck = gh repo view $Repo --json name 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Repository $Repo not found or not accessible."
    exit 1
}
Write-Ok "Repository $Repo verified"

# -------------------------------------------------------
# Step 3: Copy workflow file
# -------------------------------------------------------
Write-Step "Setting up workflow file"

$targetRoot = if ($TargetDir) { $TargetDir } else { Get-Location }
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceWorkflow = Join-Path $scriptDir "workflow.yml"
$workflowDir = Join-Path $targetRoot ".github/workflows"
$workflowFile = Join-Path $workflowDir "claude-incremental.yml"

if (-not (Test-Path $workflowDir)) {
    New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
}

if (Test-Path $sourceWorkflow) {
    Copy-Item $sourceWorkflow $workflowFile -Force
    Write-Ok "Copied workflow to $workflowFile"
} else {
    Write-Fail "Source workflow not found at $sourceWorkflow"
    Write-Host "    For automatic download, use the install script instead:"
    Write-Host "    irm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.ps1 | iex"
    exit 1
}

# Copy issue template
$igorDir = Join-Path $targetRoot ".igor"
$sourceTemplate = Join-Path $scriptDir "issue-template.md"
if (-not (Test-Path $igorDir)) {
    New-Item -ItemType Directory -Path $igorDir -Force | Out-Null
}
if (Test-Path $sourceTemplate) {
    Copy-Item $sourceTemplate (Join-Path $igorDir "issue-template.md") -Force
    Write-Ok "Copied issue template to .igor/issue-template.md"
}

# -------------------------------------------------------
# Step 4: Create label
# -------------------------------------------------------
Write-Step "Creating 'claude-incremental' label"

$labelCheck = gh label list --repo $Repo --search "claude-incremental" --json name --jq '.[].name' 2>&1
if ($labelCheck -eq "claude-incremental") {
    Write-Ok "Label already exists"
} else {
    gh label create "claude-incremental" --repo $Repo --description "Tracked by Igor incremental worker" --color "7057ff" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Created 'claude-incremental' label"
    } else {
        Write-Warn "Could not create label (may already exist)"
    }
}

# -------------------------------------------------------
# Step 5: Set ANTHROPIC_API_KEY secret
# -------------------------------------------------------
Write-Step "Configuring ANTHROPIC_API_KEY secret"

if (-not $ApiKey) {
    Write-Host ""
    Write-Host "    Enter your Anthropic API key (input is hidden):" -ForegroundColor Yellow
    Write-Host "    (press Enter to skip)" -ForegroundColor Yellow
    $secureKey = Read-Host -AsSecureString
    $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    )
}

if ($ApiKey) {
    $ApiKey | gh secret set ANTHROPIC_API_KEY --repo $Repo 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "ANTHROPIC_API_KEY secret set"
    } else {
        Write-Warn "Could not set secret. Set it manually in GitHub Settings."
    }
} else {
    Write-Warn "Skipped. Set ANTHROPIC_API_KEY later in GitHub repo Settings > Secrets > Actions"
}

# -------------------------------------------------------
# Step 6: Configure Actions permissions
# -------------------------------------------------------
Write-Step "Configuring GitHub Actions permissions"

gh api -X PUT "repos/$Repo/actions/permissions" -f "enabled=true" -f "allowed_actions=all" 2>&1 | Out-Null
gh api -X PUT "repos/$Repo/actions/permissions/workflow" -f "default_workflow_permissions=write" -F "can_approve_pull_request_reviews=true" 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Ok "Actions permissions configured (read-write + PR approval)"
} else {
    Write-Warn "Could not configure permissions automatically."
    Write-Host "    Go to: Settings > Actions > General"
    Write-Host "    Set 'Workflow permissions' to 'Read and write permissions'"
    Write-Host "    Check 'Allow GitHub Actions to create and approve pull requests'"
}

# -------------------------------------------------------
# Step 7: Create sample issue (optional)
# -------------------------------------------------------
if (-not $SkipIssue) {
    Write-Step "Sample tracking issue"

    Write-Host ""
    $createIssue = Read-Host "    Create a sample Igor tracking issue? (y/N)"

    if ($createIssue -eq "y" -or $createIssue -eq "Y") {
        $issueBody = @"
## Goal
Sample tracking issue for Igor. Replace this with your actual project goal.

## Context
This is a template issue created by the Igor setup script. Edit it to describe your project.

## Tasks

### Task 1: Example task
- [ ] Task 1

Replace this with a real task description. Include file paths, expected behavior, and any relevant context.

## Learnings
<!-- Igor updates this section with discoveries -->
"@

        $issueUrl = gh issue create --repo $Repo --title "Igor: Sample Tracking Issue" --body $issueBody --label "claude-incremental" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Created sample issue: $issueUrl"
        } else {
            Write-Warn "Could not create issue."
        }
    } else {
        Write-Ok "Skipped."
    }
}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Igor setup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Commit and push the new files"
Write-Host "  2. Create tracking issues with the 'claude-incremental' label"
Write-Host "  3. Igor runs daily at 2am UTC, or trigger manually:"
Write-Host "     GitHub > Actions > Igor > Run workflow"
Write-Host ""
