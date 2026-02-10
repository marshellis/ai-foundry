# Igor -- Incremental AI Worker

A GitHub Action that automatically makes incremental progress on large projects by working through tracking issues with task checklists.

## How It Works

1. You create a GitHub issue with the `claude-incremental` label and a task checklist
2. Igor finds the oldest eligible issue (one without an open PR)
3. Claude reads the issue and implements the first unchecked, non-blocked task
4. Igor commits the changes, pushes a branch, and opens a PR
5. Igor updates the issue (checks off the task, adds learnings)
6. You review the PR and merge

Igor runs daily at 2am UTC and can be triggered manually from the Actions tab.

## Setup

### Automated (recommended)

Run the setup script from your repository root:

**Windows (PowerShell):**
```powershell
.\setup.ps1 -RepoOwner your-org -RepoName your-repo
```

**macOS/Linux:**
```bash
./setup.sh --repo-owner your-org --repo-name your-repo
```

The script handles:
- Copying the workflow file to `.github/workflows/`
- Creating the `claude-incremental` label
- Setting the `ANTHROPIC_API_KEY` secret
- Configuring GitHub Actions permissions
- Creating a `CLAUDE.md` template
- Optionally creating a sample tracking issue

### Manual

1. Copy `workflow.yml` to `.github/workflows/claude-incremental.yml` in your repo
2. Create a `claude-incremental` label in your repo
3. Add `ANTHROPIC_API_KEY` as a repository secret (Settings > Secrets > Actions)
4. Set Actions permissions to "Read and write" (Settings > Actions > General)
5. Check "Allow GitHub Actions to create and approve pull requests"
6. Create a `CLAUDE.md` at your repo root describing your project

## Issue Format

```markdown
## Goal
Brief description of what the project aims to achieve.

## Context
Optional background info the AI should know about.

## Tasks

### Task 1: Short description
- [ ] Task 1

Detailed context for this task. Include relevant file paths, expected
behavior, edge cases, or links to related code.

### Task 2: Short description
- [ ] Task 2

More context here.

### Task 3: Already completed
- [x] Task 3

### Task 4: Blocked task
- [ ] blocked: Task 4 - explain why

## Learnings
<!-- Igor updates this section with discoveries -->
```

## Files

| File | Description |
|------|-------------|
| `workflow.yml` | The GitHub Actions workflow to copy into your repo |
| `issue-template.md` | Template for creating tracking issues |
| `setup.ps1` | Automated setup script for Windows (PowerShell) |
| `setup.sh` | Automated setup script for macOS/Linux (Bash) |
| `config.json` | Rig metadata |

## Credits

Based on [Open Chat Studio's Igor design](https://developers.openchatstudio.com/developer_guides/igor/).
