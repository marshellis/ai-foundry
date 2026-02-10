#!/usr/bin/env bash
#
# One-command installer for the Igor rig.
#
# Run via:
#   curl -fsSL https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.sh | bash
#
# Or from any public GitHub repo hosting the rig:
#   curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/rigs/igor/install.sh | bash
#
# The script will:
#   1. Detect your current git repo (or prompt for one)
#   2. Download the workflow file and issue template
#   3. Configure GitHub secrets, labels, and Actions permissions
#   4. Optionally create a sample tracking issue
#
# Requires: git, gh (GitHub CLI), authenticated with gh auth login

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step()  { echo -e "\n${CYAN}--- $1${NC}"; }
ok()    { echo -e "    ${GREEN}OK: $1${NC}"; }
warn()  { echo -e "    ${YELLOW}WARN: $1${NC}"; }
fail()  { echo -e "    ${RED}FAIL: $1${NC}"; exit 1; }

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Igor -- Incremental AI Worker${NC}"
echo -e "${CYAN}  One-command installer${NC}"
echo -e "${CYAN}========================================${NC}"

# -------------------------------------------------------
# Upstream source -- the original author's files
# -------------------------------------------------------
# The workflow file is maintained by Dimagi (Open Chat Studio).
# We download it directly from the upstream source so it stays current.
UPSTREAM_WORKFLOW_URL="https://raw.githubusercontent.com/dimagi/open-chat-studio/main/.github/workflows/claude-incremental.yml"

# -------------------------------------------------------
# Rig source -- our installer/template files
# -------------------------------------------------------
RIG_SOURCE_OWNER="marshellis"
RIG_SOURCE_REPO="ai-foundry"
RIG_SOURCE_BRANCH="main"
RIG_SOURCE_PATH="rigs/igor"
RIG_BASE_URL="https://raw.githubusercontent.com/$RIG_SOURCE_OWNER/$RIG_SOURCE_REPO/$RIG_SOURCE_BRANCH/$RIG_SOURCE_PATH"

# -------------------------------------------------------
# Step 1: Check prerequisites
# -------------------------------------------------------
step "Checking prerequisites"

command -v git &> /dev/null || fail "git is not installed."
ok "git found"

command -v gh &> /dev/null || { fail "GitHub CLI (gh) is not installed. Get it at https://cli.github.com/"; }
ok "GitHub CLI (gh) found"

command -v curl &> /dev/null || fail "curl is not installed."
ok "curl found"

gh auth status &> /dev/null || fail "Not authenticated with GitHub CLI. Run: gh auth login"
ok "Authenticated with GitHub"

# -------------------------------------------------------
# Step 2: Determine target repository
# -------------------------------------------------------
step "Determining target repository"

REPO=""

# Try to detect from git remote
if git rev-parse --show-toplevel &> /dev/null; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "$REMOTE_URL" ]]; then
        # Parse owner/repo from various git URL formats
        if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
            DETECTED_OWNER="${BASH_REMATCH[1]}"
            DETECTED_NAME="${BASH_REMATCH[2]}"
            REPO="$DETECTED_OWNER/$DETECTED_NAME"
            echo -e "    ${YELLOW}Detected repository: $REPO${NC}"
            read -rp "    Use this repository? (Y/n) " CONFIRM
            if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
                REPO=""
            fi
        fi
    fi
fi

if [[ -z "$REPO" ]]; then
    echo ""
    read -rp "    Enter target repository (owner/name): " REPO
    [[ -z "$REPO" ]] && fail "No repository specified."
fi

gh repo view "$REPO" --json name &> /dev/null || fail "Repository $REPO not found or not accessible."
ok "Repository $REPO verified"

# -------------------------------------------------------
# Step 3: Download rig files
# -------------------------------------------------------
step "Downloading Igor rig files"

# Ensure we're in the repo root
if git rev-parse --show-toplevel &> /dev/null; then
    ROOT=$(git rev-parse --show-toplevel)
    cd "$ROOT"
    ok "In git repository root: $ROOT"
else
    fail "Not inside a git repository. Run this from your repo directory."
fi

# Create workflow directory
WORKFLOW_DIR=".github/workflows"
mkdir -p "$WORKFLOW_DIR"

# Download workflow file from upstream (dimagi/open-chat-studio)
if curl -fsSL "$UPSTREAM_WORKFLOW_URL" -o "$WORKFLOW_DIR/claude-incremental.yml"; then
    ok "Downloaded workflow from upstream (dimagi/open-chat-studio)"
    echo "    -> $WORKFLOW_DIR/claude-incremental.yml"
else
    fail "Could not download workflow file from $UPSTREAM_WORKFLOW_URL"
fi

# Download issue template
IGOR_DIR=".igor"
mkdir -p "$IGOR_DIR"

if curl -fsSL "$RIG_BASE_URL/issue-template.md" -o "$IGOR_DIR/issue-template.md"; then
    ok "Downloaded issue template -> $IGOR_DIR/issue-template.md"
else
    warn "Could not download issue template (non-critical)"
fi

# -------------------------------------------------------
# Step 4: Set ANTHROPIC_API_KEY secret
# -------------------------------------------------------
step "Configuring ANTHROPIC_API_KEY secret"

echo ""
echo -e "    ${YELLOW}Enter your Anthropic API key (input is hidden):${NC}"
echo -e "    ${YELLOW}(press Enter to skip -- you can set it later in GitHub Settings)${NC}"
read -rs API_KEY
echo ""

if [[ -n "$API_KEY" ]]; then
    if echo "$API_KEY" | gh secret set ANTHROPIC_API_KEY --repo "$REPO" 2>/dev/null; then
        ok "ANTHROPIC_API_KEY secret set"
    else
        warn "Could not set secret. Set it manually:"
        echo "    GitHub repo > Settings > Secrets and variables > Actions > New repository secret"
    fi
else
    warn "Skipped. Set ANTHROPIC_API_KEY later in GitHub repo Settings > Secrets > Actions"
fi

# -------------------------------------------------------
# Step 5: Create label
# -------------------------------------------------------
step "Creating 'claude-incremental' label"

EXISTING_LABEL=$(gh label list --repo "$REPO" --search "claude-incremental" --json name --jq '.[].name' 2>/dev/null || true)
if [[ "$EXISTING_LABEL" == "claude-incremental" ]]; then
    ok "Label already exists"
else
    if gh label create "claude-incremental" --repo "$REPO" --description "Tracked by Igor incremental worker" --color "7057ff" 2>/dev/null; then
        ok "Created 'claude-incremental' label"
    else
        warn "Could not create label (may already exist)"
    fi
fi

# -------------------------------------------------------
# Step 6: Configure Actions permissions
# -------------------------------------------------------
step "Configuring GitHub Actions permissions"

gh api -X PUT "repos/$REPO/actions/permissions" -f "enabled=true" -f "allowed_actions=all" 2>/dev/null || true
if gh api -X PUT "repos/$REPO/actions/permissions/workflow" -f "default_workflow_permissions=write" -F "can_approve_pull_request_reviews=true" 2>/dev/null; then
    ok "Actions permissions configured (read-write + PR approval)"
else
    warn "Could not configure permissions automatically."
    echo "    Go to: Settings > Actions > General"
    echo "    Set 'Workflow permissions' to 'Read and write permissions'"
    echo "    Check 'Allow GitHub Actions to create and approve pull requests'"
fi

# -------------------------------------------------------
# Step 7: Create sample issue (optional)
# -------------------------------------------------------
step "Sample tracking issue"

echo ""
read -rp "    Create a sample Igor tracking issue? (y/N) " CREATE_ISSUE

if [[ "$CREATE_ISSUE" =~ ^[Yy]$ ]]; then
    ISSUE_BODY='## Goal
Sample tracking issue for Igor. Replace this with your actual project goal.

## Context
This is a template issue created by the Igor installer. Edit it to describe your project.

## Tasks

### Task 1: Example task
- [ ] Task 1

Replace this with a real task description. Include file paths, expected behavior, and any relevant context.

## Learnings
<!-- Igor updates this section with discoveries -->'

    ISSUE_URL=$(gh issue create --repo "$REPO" --title "Igor: Sample Tracking Issue" --body "$ISSUE_BODY" --label "claude-incremental" 2>&1)
    if [[ $? -eq 0 ]]; then
        ok "Created sample issue: $ISSUE_URL"
    else
        warn "Could not create issue. Create one manually using .igor/issue-template.md"
    fi
else
    ok "Skipped. Use .igor/issue-template.md as a reference when creating issues."
fi

# -------------------------------------------------------
# Done
# -------------------------------------------------------
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Igor is installed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Files added:${NC}"
echo "  .github/workflows/claude-incremental.yml  (workflow from dimagi/open-chat-studio)"
echo "  .igor/issue-template.md                   (reference template)"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Commit and push the new files:"
echo "     git add .github/workflows/claude-incremental.yml .igor/"
echo "     git commit -m 'Add Igor incremental worker'"
echo "     git push"
echo "  2. Create tracking issues with the 'claude-incremental' label"
echo "  3. Igor runs daily at 2am UTC, or trigger manually:"
echo "     GitHub > Actions > Igor > Run workflow"
echo ""
echo -e "${CYAN}To verify it works:${NC}"
echo "  1. Go to GitHub > Actions and confirm the 'Igor' workflow appears"
echo "  2. Create a tracking issue with a simple task"
echo "  3. Trigger the workflow manually: Actions > Igor > Run workflow"
echo "  4. Check that Igor creates a branch, opens a PR, and checks off the task"
echo ""
