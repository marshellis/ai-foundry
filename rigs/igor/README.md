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

### One-command install (recommended)

Open a terminal in your project directory and run:

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.ps1 | iex
```

**macOS/Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.sh | bash
```

The installer handles everything interactively:
- Downloads the workflow file to `.github/workflows/`
- Creates the `claude-incremental` label
- Sets the `ANTHROPIC_API_KEY` secret
- Configures GitHub Actions permissions
- Creates a `CLAUDE.md` template
- Optionally creates a sample tracking issue

After the installer finishes, commit and push the new files.

### Local setup (if you cloned this repo)

If you already have the rig files locally:

**Windows (PowerShell):**
```powershell
.\setup.ps1
```

**macOS/Linux:**
```bash
./setup.sh
```

### Manual

1. Copy `workflow.yml` to `.github/workflows/claude-incremental.yml` in your repo
2. Create a `claude-incremental` label in your repo
3. Add `ANTHROPIC_API_KEY` as a repository secret (Settings > Secrets > Actions)
4. Set Actions permissions to "Read and write" (Settings > Actions > General)
5. Check "Allow GitHub Actions to create and approve pull requests"
6. Create a `CLAUDE.md` at your repo root describing your project

### Hosting your own fork

Igor is a package -- you can fork it and host it in your own repo. Just update the
`RIG_BASE_URL` / `$RigBaseUrl` in the install scripts to point to your fork. Anyone
can then install from your repo using the same one-liner pattern.

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
| `install.ps1` | One-command installer for Windows (PowerShell) |
| `install.sh` | One-command installer for macOS/Linux (Bash) |
| `setup.ps1` | Local setup script for Windows (if you have files locally) |
| `setup.sh` | Local setup script for macOS/Linux (if you have files locally) |
| `workflow.yml` | The GitHub Actions workflow to copy into your repo |
| `issue-template.md` | Template for creating tracking issues |
| `config.json` | Rig metadata and package info |

## Credits

Based on [Open Chat Studio's Igor design](https://developers.openchatstudio.com/developer_guides/igor/).
