<#
.SYNOPSIS
    One-command installer for the Igor rig.

.DESCRIPTION
    Downloads all Igor rig files from a GitHub repository and runs the
    interactive setup. This script is designed to be run via:

        irm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.ps1 | iex

    Or from any public GitHub repo hosting the rig:

        irm https://raw.githubusercontent.com/OWNER/REPO/main/rigs/igor/install.ps1 | iex

    The script will:
    1. Detect your current git repo (or prompt for one)
    2. Download the workflow file and issue template
    3. Configure GitHub secrets, labels, and Actions permissions
    4. Optionally create a sample tracking issue

.NOTES
    Requires: git, gh (GitHub CLI), authenticated with gh auth login
#>

$ErrorActionPreference = "Stop"

# Version number -- increment this when making changes
$ScriptVersion = "1.3.0"

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
Write-Host "  Igor -- Incremental AI Worker" -ForegroundColor Cyan
Write-Host "  One-command installer v$ScriptVersion" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# -------------------------------------------------------
# Upstream source -- the original author's files
# -------------------------------------------------------
# The workflow file is maintained by Dimagi (Open Chat Studio).
# We download it directly from the upstream source so it stays current.
$UpstreamWorkflowUrl = "https://raw.githubusercontent.com/dimagi/open-chat-studio/main/.github/workflows/claude-incremental.yml"

# -------------------------------------------------------
# Rig source -- our installer/template files
# -------------------------------------------------------
$RigSourceOwner = "marshellis"
$RigSourceRepo = "ai-foundry"
$RigSourceBranch = "main"
$RigSourcePath = "rigs/igor"
$RigBaseUrl = "https://raw.githubusercontent.com/$RigSourceOwner/$RigSourceRepo/$RigSourceBranch/$RigSourcePath"

# -------------------------------------------------------
# Step 1: Check prerequisites
# -------------------------------------------------------
Write-Step "Checking prerequisites"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Fail "git is not installed."
    exit 1
}
Write-Ok "git found"

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
# Step 2: Determine target repository
# -------------------------------------------------------
Write-Step "Determining target repository"

$Repo = $null

# Try to detect from git remote
$gitRoot = git rev-parse --show-toplevel 2>&1
if ($LASTEXITCODE -eq 0) {
    $remoteUrl = git remote get-url origin 2>&1
    if ($LASTEXITCODE -eq 0) {
        # Parse owner/repo from git remote URL
        if ($remoteUrl -match "github\.com[:/]([^/]+)/([^/.]+)") {
            $detectedOwner = $Matches[1]
            $detectedName = $Matches[2]
            $Repo = "$detectedOwner/$detectedName"
            Write-Host "    Detected repository: $Repo" -ForegroundColor Yellow
            $confirm = Read-Host "    Use this repository? (Y/n)"
            if ($confirm -eq "n" -or $confirm -eq "N") {
                $Repo = $null
            }
        }
    }
}

if (-not $Repo) {
    Write-Host ""
    $repoInput = Read-Host "    Enter target repository (owner/name)"
    if (-not $repoInput) {
        Write-Fail "No repository specified."
        exit 1
    }
    $Repo = $repoInput
}

# Verify repo exists
$repoCheck = gh repo view $Repo --json name 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Repository $Repo not found or not accessible."
    exit 1
}
Write-Ok "Repository $Repo verified"

# -------------------------------------------------------
# Step 3: Download rig files
# -------------------------------------------------------
Write-Step "Downloading Igor rig files"

# Ensure we're in the repo root
if (Test-Path ".git") {
    Write-Ok "In git repository root"
} else {
    # Try to find git root
    $root = git rev-parse --show-toplevel 2>&1
    if ($LASTEXITCODE -eq 0) {
        Set-Location $root
        Write-Ok "Changed to repository root: $root"
    } else {
        Write-Fail "Not inside a git repository. Run this from your repo directory."
        exit 1
    }
}

# Create workflow directory
$workflowDir = ".github/workflows"
if (-not (Test-Path $workflowDir)) {
    New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
}

# Download workflow file from upstream (dimagi/open-chat-studio)
try {
    $workflowContent = Invoke-RestMethod $UpstreamWorkflowUrl
    Set-Content -Path "$workflowDir/claude-incremental.yml" -Value $workflowContent -Encoding UTF8
    Write-Ok "Downloaded workflow from upstream (dimagi/open-chat-studio)"
    Write-Host "    -> $workflowDir/claude-incremental.yml"
} catch {
    Write-Fail "Could not download workflow file from $UpstreamWorkflowUrl"
    Write-Host "    Error: $_"
    exit 1
}

# Download issue template
Write-Host ""
Write-Host "    Where should the issue template be installed?" -ForegroundColor Yellow
Write-Host "      1) .github/ISSUE_TEMPLATE/ -- appears in GitHub's 'New Issue' picker (recommended)"
Write-Host "      2) .igor/                  -- local reference copy only"
Write-Host "      3) Skip"
$templateChoice = Read-Host "    Choice (1/2/3)"

if ($templateChoice -eq "1") {
    $templateDir = ".github/ISSUE_TEMPLATE"
    $templateFile = "$templateDir/igor-tracking-issue.yml"
    if (-not (Test-Path $templateDir)) {
        New-Item -ItemType Directory -Path $templateDir -Force | Out-Null
    }
    try {
        $templateContent = Invoke-RestMethod "$RigBaseUrl/igor-tracking-issue.yml"
        Set-Content -Path $templateFile -Value $templateContent -Encoding UTF8
        Write-Ok "Downloaded GitHub issue template -> $templateFile"
    } catch {
        Write-Warn "Could not download issue template (non-critical)"
    }
} elseif ($templateChoice -eq "2") {
    $rigDir = ".igor"
    if (-not (Test-Path $rigDir)) {
        New-Item -ItemType Directory -Path $rigDir -Force | Out-Null
    }
    try {
        $templateContent = Invoke-RestMethod "$RigBaseUrl/issue-template.md"
        Set-Content -Path "$rigDir/issue-template.md" -Value $templateContent -Encoding UTF8
        Write-Ok "Downloaded issue template -> $rigDir/issue-template.md"
    } catch {
        Write-Warn "Could not download issue template (non-critical)"
    }
} else {
    Write-Ok "Skipped issue template"
}

# -------------------------------------------------------
# Step 4: Set ANTHROPIC_API_KEY secret
# -------------------------------------------------------
Write-Step "Configuring ANTHROPIC_API_KEY secret"

Write-Host ""
Write-Host "    Enter your Anthropic API key (input is hidden):" -ForegroundColor Yellow
Write-Host "    (press Enter to skip -- you can set it later in GitHub Settings)" -ForegroundColor Yellow
$secureKey = Read-Host -AsSecureString
$ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
)

if ($ApiKey) {
    $ApiKey | gh secret set ANTHROPIC_API_KEY --repo $Repo 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "ANTHROPIC_API_KEY secret set"
    } else {
        Write-Warn "Could not set secret. Set it manually:"
        Write-Host "    GitHub repo > Settings > Secrets and variables > Actions > New repository secret"
    }
} else {
    Write-Warn "Skipped. Set ANTHROPIC_API_KEY later in GitHub repo Settings > Secrets > Actions"
}

# -------------------------------------------------------
# Step 5: Create label
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
# Step 6: Configure Actions permissions
# -------------------------------------------------------
Write-Step "Configuring GitHub Actions permissions"

# Set workflow permissions (read-write + PR approval)
# Note: The first API call (repos/.../actions/permissions) only exists at org level,
# so we only configure the workflow-level permissions here.
# Suppress stderr to avoid ugly error output when org policy blocks this.
$ErrorActionPreference = "SilentlyContinue"
$permResult = gh api -X PUT "repos/$Repo/actions/permissions/workflow" `
    -f "default_workflow_permissions=write" `
    -F "can_approve_pull_request_reviews=true" 2>$null
$permExitCode = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($permExitCode -eq 0) {
    Write-Ok "Actions permissions configured (read-write + PR approval)"
} else {
    Write-Warn "Could not configure workflow permissions automatically."
    Write-Host ""
    Write-Host "    Igor REQUIRES write permissions to create branches and PRs." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    This is likely blocked by an organization-level policy." -ForegroundColor Yellow
    Write-Host "    To fix this, you have two options:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Option 1: Change organization settings (if you're an org admin)" -ForegroundColor Cyan
    Write-Host "      1. Go to: https://github.com/organizations/$($Repo.Split('/')[0])/settings/actions"
    Write-Host "      2. Under 'Workflow permissions', select 'Read and write permissions'"
    Write-Host "      3. Check 'Allow GitHub Actions to create and approve pull requests'"
    Write-Host "      4. Re-run this installer"
    Write-Host ""
    Write-Host "    Option 2: Change repository settings (if org allows it)" -ForegroundColor Cyan
    Write-Host "      1. Go to: https://github.com/$Repo/settings/actions"
    Write-Host "      2. Under 'Workflow permissions', select 'Read and write permissions'"
    Write-Host "      3. Check 'Allow GitHub Actions to create and approve pull requests'"
    Write-Host ""
    Write-Host "    Without these permissions, Igor will fail when it tries to run." -ForegroundColor Red
    Write-Host ""
}

# -------------------------------------------------------
# Step 7: Create sample issue (optional)
# -------------------------------------------------------
Write-Step "Sample tracking issue"

Write-Host ""
$createIssue = Read-Host "    Create a sample Igor tracking issue? (y/N)"

if ($createIssue -eq "y" -or $createIssue -eq "Y") {
    $issueBody = @"
## Goal
Sample tracking issue for Igor. Replace this with your actual project goal.

## Context
This is a template issue created by the Igor installer. Edit it to describe your project.

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
    Write-Ok "Skipped. Create tracking issues with the 'claude-incremental' label when ready."
}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Igor is installed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files added:" -ForegroundColor Cyan
Write-Host "  .github/workflows/claude-incremental.yml  (workflow from dimagi/open-chat-studio)"
if ($templateChoice -eq "1") {
    Write-Host "  .github/ISSUE_TEMPLATE/igor-tracking-issue.yml  (GitHub issue template)"
} elseif ($templateChoice -eq "2") {
    Write-Host "  .igor/issue-template.md                   (reference template)"
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Commit and push the new files:"
Write-Host "     git add .github/"
if ($templateChoice -eq "2") {
    Write-Host "     git add .igor/"
}
Write-Host "     git commit -m 'Add Igor incremental worker'"
Write-Host "     git push"
Write-Host "  2. Create tracking issues with the 'claude-incremental' label"
Write-Host "  3. Igor runs daily at 2am UTC, or trigger manually:"
Write-Host "     GitHub > Actions > Igor > Run workflow"
Write-Host ""
Write-Host "To verify it works:" -ForegroundColor Cyan
Write-Host "  1. Go to GitHub > Actions and confirm the 'Igor' workflow appears"
Write-Host "  2. Create a tracking issue with a simple task"
Write-Host "  3. Trigger the workflow manually: Actions > Igor > Run workflow"
Write-Host "  4. Check that Igor creates a branch, opens a PR, and checks off the task"
Write-Host ""
