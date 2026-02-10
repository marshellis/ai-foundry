<#
.SYNOPSIS
    Automated setup script for the Igor rig (Incremental AI Worker).

.DESCRIPTION
    This script configures a GitHub repository to use Igor by:
    1. Verifying prerequisites (gh CLI, authentication)
    2. Copying the workflow file to .github/workflows/
    3. Creating the 'claude-incremental' label
    4. Setting the ANTHROPIC_API_KEY secret
    5. Configuring GitHub Actions permissions
    6. Creating a CLAUDE.md file if one doesn't exist
    7. Optionally creating a sample tracking issue

.PARAMETER RepoOwner
    The GitHub organization or user that owns the repository.

.PARAMETER RepoName
    The name of the GitHub repository.

.PARAMETER ApiKey
    The Anthropic API key. If not provided, the script will prompt for it.

.PARAMETER SkipIssue
    Skip creating the sample tracking issue.

.EXAMPLE
    .\setup.ps1 -RepoOwner myorg -RepoName myrepo
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$RepoOwner,

    [Parameter(Mandatory = $true)]
    [string]$RepoName,

    [string]$ApiKey,

    [switch]$SkipIssue
)

$ErrorActionPreference = "Stop"
$Repo = "$RepoOwner/$RepoName"

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
# Step 1: Check prerequisites
# -------------------------------------------------------
Write-Step "Checking prerequisites"

# Check gh CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Fail "GitHub CLI (gh) is not installed."
    Write-Host "    Install it from: https://cli.github.com/"
    exit 1
}
Write-Ok "GitHub CLI (gh) found"

# Check gh auth
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Not authenticated with GitHub CLI."
    Write-Host "    Run: gh auth login"
    exit 1
}
Write-Ok "Authenticated with GitHub"

# Check repo exists
$repoCheck = gh repo view $Repo --json name 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Repository $Repo not found or not accessible."
    exit 1
}
Write-Ok "Repository $Repo found"

# -------------------------------------------------------
# Step 2: Copy workflow file
# -------------------------------------------------------
Write-Step "Setting up workflow file"

$workflowDir = ".github/workflows"
$workflowFile = "$workflowDir/claude-incremental.yml"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceWorkflow = Join-Path $scriptDir "workflow.yml"

# Check if we're in a git repo
$gitRoot = git rev-parse --show-toplevel 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Not inside a git repository. Run this script from your repo root."
    exit 1
}

# Create workflow directory if needed
if (-not (Test-Path $workflowDir)) {
    New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
    Write-Ok "Created $workflowDir directory"
}

# Copy workflow
if (Test-Path $sourceWorkflow) {
    Copy-Item $sourceWorkflow $workflowFile -Force
    Write-Ok "Copied workflow to $workflowFile"
} else {
    Write-Warn "Source workflow not found at $sourceWorkflow"
    Write-Host "    You can manually copy the workflow from the AI Foundry rigs/igor/ directory."
}

# -------------------------------------------------------
# Step 3: Create label
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
# Step 4: Set ANTHROPIC_API_KEY secret
# -------------------------------------------------------
Write-Step "Configuring ANTHROPIC_API_KEY secret"

if (-not $ApiKey) {
    Write-Host ""
    Write-Host "    Enter your Anthropic API key (input is hidden):" -ForegroundColor Yellow
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
        Write-Fail "Could not set secret. You may need admin access to the repository."
        Write-Host "    Set it manually: GitHub repo > Settings > Secrets > Actions > New repository secret"
    }
} else {
    Write-Warn "No API key provided. Set it manually in GitHub repo settings."
}

# -------------------------------------------------------
# Step 5: Configure Actions permissions
# -------------------------------------------------------
Write-Step "Configuring GitHub Actions permissions"

# Enable Actions with write permissions
gh api -X PUT "repos/$Repo/actions/permissions" -f "enabled=true" -f "allowed_actions=all" 2>&1 | Out-Null

# Set workflow permissions to read-write
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
# Step 6: Create CLAUDE.md if missing
# -------------------------------------------------------
Write-Step "Checking for CLAUDE.md"

if (-not (Test-Path "CLAUDE.md")) {
    Write-Warn "No CLAUDE.md found. Creating a basic one."
    Write-Host "    CLAUDE.md gives Claude context about your project."
    Write-Host "    Edit it to describe your project structure, conventions, and how to build/test."

    @"
# Project Context for Claude

## Overview
<!-- Describe your project here -->

## Directory Structure
<!-- Describe your directory layout -->

## Development
<!-- How to install, build, test, and lint -->

## Conventions
<!-- Code style, naming conventions, patterns to follow -->
"@ | Set-Content "CLAUDE.md" -Encoding UTF8

    Write-Ok "Created CLAUDE.md template -- edit it to describe your project"
} else {
    Write-Ok "CLAUDE.md already exists"
}

# -------------------------------------------------------
# Step 7: Create sample issue (optional)
# -------------------------------------------------------
if (-not $SkipIssue) {
    Write-Step "Creating sample tracking issue"

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
            Write-Warn "Could not create issue. Create one manually using the issue template."
        }
    } else {
        Write-Ok "Skipped sample issue creation"
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
Write-Host "  1. Review and edit CLAUDE.md to describe your project"
Write-Host "  2. Commit and push the workflow file and CLAUDE.md"
Write-Host "  3. Create tracking issues with the 'claude-incremental' label"
Write-Host "  4. Igor runs daily at 2am UTC, or trigger manually:"
Write-Host "     Actions > Igor > Run workflow"
Write-Host ""
