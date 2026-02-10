#!/usr/bin/env bash
#
# Automated setup script for the Igor rig (Incremental AI Worker).
#
# This script configures a GitHub repository to use Igor by:
#   1. Verifying prerequisites (gh CLI, authentication)
#   2. Copying the workflow file to .github/workflows/
#   3. Creating the 'claude-incremental' label
#   4. Setting the ANTHROPIC_API_KEY secret
#   5. Configuring GitHub Actions permissions
#   6. Creating a CLAUDE.md file if one doesn't exist
#   7. Optionally creating a sample tracking issue
#
# Usage:
#   ./setup.sh --repo-owner myorg --repo-name myrepo [--api-key KEY] [--skip-issue]

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
fail()  { echo -e "    ${RED}FAIL: $1${NC}"; }

# Parse arguments
REPO_OWNER=""
REPO_NAME=""
API_KEY=""
SKIP_ISSUE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo-owner) REPO_OWNER="$2"; shift 2 ;;
        --repo-name)  REPO_NAME="$2"; shift 2 ;;
        --api-key)    API_KEY="$2"; shift 2 ;;
        --skip-issue) SKIP_ISSUE=true; shift ;;
        -h|--help)
            echo "Usage: ./setup.sh --repo-owner OWNER --repo-name NAME [--api-key KEY] [--skip-issue]"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
    echo "Error: --repo-owner and --repo-name are required."
    echo "Usage: ./setup.sh --repo-owner OWNER --repo-name NAME"
    exit 1
fi

REPO="$REPO_OWNER/$REPO_NAME"

# -------------------------------------------------------
# Step 1: Check prerequisites
# -------------------------------------------------------
step "Checking prerequisites"

if ! command -v gh &> /dev/null; then
    fail "GitHub CLI (gh) is not installed."
    echo "    Install it from: https://cli.github.com/"
    exit 1
fi
ok "GitHub CLI (gh) found"

if ! gh auth status &> /dev/null; then
    fail "Not authenticated with GitHub CLI."
    echo "    Run: gh auth login"
    exit 1
fi
ok "Authenticated with GitHub"

if ! gh repo view "$REPO" --json name &> /dev/null; then
    fail "Repository $REPO not found or not accessible."
    exit 1
fi
ok "Repository $REPO found"

# -------------------------------------------------------
# Step 2: Copy workflow file
# -------------------------------------------------------
step "Setting up workflow file"

WORKFLOW_DIR=".github/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/claude-incremental.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_WORKFLOW="$SCRIPT_DIR/workflow.yml"

if ! git rev-parse --show-toplevel &> /dev/null; then
    fail "Not inside a git repository. Run this script from your repo root."
    exit 1
fi

mkdir -p "$WORKFLOW_DIR"

if [[ -f "$SOURCE_WORKFLOW" ]]; then
    cp "$SOURCE_WORKFLOW" "$WORKFLOW_FILE"
    ok "Copied workflow to $WORKFLOW_FILE"
else
    warn "Source workflow not found at $SOURCE_WORKFLOW"
    echo "    You can manually copy the workflow from the AI Foundry rigs/igor/ directory."
fi

# -------------------------------------------------------
# Step 3: Create label
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
# Step 4: Set ANTHROPIC_API_KEY secret
# -------------------------------------------------------
step "Configuring ANTHROPIC_API_KEY secret"

if [[ -z "$API_KEY" ]]; then
    echo ""
    echo -e "    ${YELLOW}Enter your Anthropic API key (input is hidden):${NC}"
    read -rs API_KEY
    echo ""
fi

if [[ -n "$API_KEY" ]]; then
    if echo "$API_KEY" | gh secret set ANTHROPIC_API_KEY --repo "$REPO" 2>/dev/null; then
        ok "ANTHROPIC_API_KEY secret set"
    else
        fail "Could not set secret. You may need admin access to the repository."
        echo "    Set it manually: GitHub repo > Settings > Secrets > Actions > New repository secret"
    fi
else
    warn "No API key provided. Set it manually in GitHub repo settings."
fi

# -------------------------------------------------------
# Step 5: Configure Actions permissions
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
# Step 6: Create CLAUDE.md if missing
# -------------------------------------------------------
step "Checking for CLAUDE.md"

if [[ ! -f "CLAUDE.md" ]]; then
    warn "No CLAUDE.md found. Creating a basic one."
    echo "    CLAUDE.md gives Claude context about your project."
    echo "    Edit it to describe your project structure, conventions, and how to build/test."

    cat > CLAUDE.md << 'TEMPLATE'
# Project Context for Claude

## Overview
<!-- Describe your project here -->

## Directory Structure
<!-- Describe your directory layout -->

## Development
<!-- How to install, build, test, and lint -->

## Conventions
<!-- Code style, naming conventions, patterns to follow -->
TEMPLATE

    ok "Created CLAUDE.md template -- edit it to describe your project"
else
    ok "CLAUDE.md already exists"
fi

# -------------------------------------------------------
# Step 7: Create sample issue (optional)
# -------------------------------------------------------
if [[ "$SKIP_ISSUE" != true ]]; then
    step "Creating sample tracking issue"

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
            warn "Could not create issue. Create one manually using the issue template."
        fi
    else
        ok "Skipped sample issue creation"
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
echo "  1. Review and edit CLAUDE.md to describe your project"
echo "  2. Commit and push the workflow file and CLAUDE.md"
echo "  3. Create tracking issues with the 'claude-incremental' label"
echo "  4. Igor runs daily at 2am UTC, or trigger manually:"
echo "     Actions > Igor > Run workflow"
echo ""
