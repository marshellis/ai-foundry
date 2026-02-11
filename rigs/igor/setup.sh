#!/usr/bin/env bash
#
# Local setup script for the Igor rig.
#
# If you already have the rig files locally (e.g., you cloned ai-foundry),
# this script sets up Igor in a target repository.
#
# For a one-command install that downloads everything automatically, use:
#   curl -fsSL https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.sh | bash
#
# Usage:
#   ./setup.sh [--repo-owner OWNER] [--repo-name NAME] [--api-key KEY] [--target-dir DIR] [--skip-issue]
#
# If owner/name are not provided, the script auto-detects from git remote.

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

step()  { echo -e "\n${CYAN}--- $1${NC}"; }
ok()    { echo -e "    ${GREEN}OK: $1${NC}"; }
warn()  { echo -e "    ${YELLOW}WARN: $1${NC}"; }
fail_msg() { echo -e "    ${RED}FAIL: $1${NC}"; }

# Parse arguments
REPO_OWNER=""
REPO_NAME=""
API_KEY=""
TARGET_DIR=""
SKIP_ISSUE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo-owner) REPO_OWNER="$2"; shift 2 ;;
        --repo-name)  REPO_NAME="$2"; shift 2 ;;
        --api-key)    API_KEY="$2"; shift 2 ;;
        --target-dir) TARGET_DIR="$2"; shift 2 ;;
        --skip-issue) SKIP_ISSUE=true; shift ;;
        -h|--help)
            echo "Usage: ./setup.sh [--repo-owner OWNER] [--repo-name NAME] [--api-key KEY] [--target-dir DIR] [--skip-issue]"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Igor -- Local Setup${NC}"
echo -e "${CYAN}========================================${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------------------------------------------------------
# Step 1: Check prerequisites
# -------------------------------------------------------
step "Checking prerequisites"

command -v gh &> /dev/null || { fail_msg "GitHub CLI (gh) is not installed. Get it at https://cli.github.com/"; exit 1; }
ok "GitHub CLI (gh) found"

command -v curl &> /dev/null || { fail_msg "curl is not installed."; exit 1; }
ok "curl found"

gh auth status &> /dev/null || { fail_msg "Not authenticated with GitHub CLI. Run: gh auth login"; exit 1; }
ok "Authenticated with GitHub"

# -------------------------------------------------------
# Step 2: Determine target repo
# -------------------------------------------------------
step "Determining target repository"

DETECT_DIR="${TARGET_DIR:-.}"

if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
    REMOTE_URL=$(cd "$DETECT_DIR" && git remote get-url origin 2>/dev/null || true)
    if [[ -n "$REMOTE_URL" && "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
        DETECTED_OWNER="${BASH_REMATCH[1]}"
        DETECTED_NAME="${BASH_REMATCH[2]}"
        echo -e "    ${YELLOW}Detected: $DETECTED_OWNER/$DETECTED_NAME${NC}"
        read -rp "    Use this repository? (Y/n) " CONFIRM
        if [[ ! "$CONFIRM" =~ ^[Nn]$ ]]; then
            REPO_OWNER="$DETECTED_OWNER"
            REPO_NAME="$DETECTED_NAME"
        fi
    fi

    if [[ -z "$REPO_OWNER" ]]; then
        read -rp "    Enter repository owner: " REPO_OWNER
    fi
    if [[ -z "$REPO_NAME" ]]; then
        read -rp "    Enter repository name: " REPO_NAME
    fi
fi

REPO="$REPO_OWNER/$REPO_NAME"

gh repo view "$REPO" --json name &> /dev/null || { fail_msg "Repository $REPO not found or not accessible."; exit 1; }
ok "Repository $REPO verified"

# -------------------------------------------------------
# Step 3: Copy workflow file from rig
# -------------------------------------------------------
step "Setting up workflow file"

TARGET_ROOT="${TARGET_DIR:-.}"
WORKFLOW_DIR="$TARGET_ROOT/.github/workflows"
SOURCE_WORKFLOW="$SCRIPT_DIR/claude-incremental.yml"

mkdir -p "$WORKFLOW_DIR"

if [[ -f "$SOURCE_WORKFLOW" ]]; then
    cp "$SOURCE_WORKFLOW" "$WORKFLOW_DIR/claude-incremental.yml"
    ok "Copied workflow from rig to $WORKFLOW_DIR/claude-incremental.yml"
else
    fail_msg "Could not find claude-incremental.yml in rig directory."
    echo "    Expected: $SOURCE_WORKFLOW"
    exit 1
fi

# Copy issue template from local rig files
echo ""
echo -e "    ${YELLOW}Where should the issue template be installed?${NC}"
echo "      1) .github/ISSUE_TEMPLATE/ -- appears in GitHub's 'New Issue' picker (recommended)"
echo "      2) .igor/                  -- local reference copy only"
echo "      3) Skip"
read -rp "    Choice (1/2/3): " TEMPLATE_CHOICE

if [[ "$TEMPLATE_CHOICE" == "1" ]]; then
    TEMPLATE_DIR="$TARGET_ROOT/.github/ISSUE_TEMPLATE"
    SOURCE_TEMPLATE="$SCRIPT_DIR/igor-tracking-issue.yml"
    mkdir -p "$TEMPLATE_DIR"
    if [[ -f "$SOURCE_TEMPLATE" ]]; then
        cp "$SOURCE_TEMPLATE" "$TEMPLATE_DIR/igor-tracking-issue.yml"
        ok "Copied GitHub issue template to .github/ISSUE_TEMPLATE/igor-tracking-issue.yml"
    else
        warn "Could not find igor-tracking-issue.yml in rig files"
    fi
elif [[ "$TEMPLATE_CHOICE" == "2" ]]; then
    IGOR_DIR="$TARGET_ROOT/.igor"
    mkdir -p "$IGOR_DIR"
    SOURCE_TEMPLATE="$SCRIPT_DIR/issue-template.md"
    if [[ -f "$SOURCE_TEMPLATE" ]]; then
        cp "$SOURCE_TEMPLATE" "$IGOR_DIR/issue-template.md"
        ok "Copied issue template to .igor/issue-template.md"
    else
        warn "Could not find issue-template.md in rig files"
    fi
else
    ok "Skipped issue template"
fi

# -------------------------------------------------------
# Step 4: Create label
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
# Step 5: Set ANTHROPIC_API_KEY secret
# -------------------------------------------------------
step "Configuring ANTHROPIC_API_KEY secret"

if [[ -z "$API_KEY" ]]; then
    echo ""
    echo -e "    ${YELLOW}Enter your Anthropic API key (input is hidden):${NC}"
    echo -e "    ${YELLOW}(press Enter to skip)${NC}"
    read -rs API_KEY
    echo ""
fi

if [[ -n "$API_KEY" ]]; then
    if echo "$API_KEY" | gh secret set ANTHROPIC_API_KEY --repo "$REPO" 2>/dev/null; then
        ok "ANTHROPIC_API_KEY secret set"
    else
        warn "Could not set secret. Set it manually in GitHub Settings."
    fi
else
    warn "Skipped. Set ANTHROPIC_API_KEY later in GitHub repo Settings > Secrets > Actions"
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
if [[ "$SKIP_ISSUE" != true ]]; then
    step "Sample tracking issue"

    echo ""
    read -rp "    Create a sample Igor tracking issue? (y/N) " CREATE_ISSUE

    if [[ "$CREATE_ISSUE" =~ ^[Yy]$ ]]; then
        ISSUE_BODY='## Goal
Sample tracking issue for Igor. Replace this with your actual project goal.

## Context
This is a template issue created by the Igor setup script. Edit it to describe your project.

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
            warn "Could not create issue."
        fi
    else
        ok "Skipped."
    fi
fi

# -------------------------------------------------------
# Done
# -------------------------------------------------------
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Igor setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Commit and push the new files"
echo "  2. Create tracking issues with the 'claude-incremental' label"
echo "  3. Igor runs daily at 2am UTC, or trigger manually:"
echo "     GitHub > Actions > Igor > Run workflow"
echo ""
