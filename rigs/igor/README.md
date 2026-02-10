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
- Downloads the workflow file directly from the [upstream source](https://github.com/dimagi/open-chat-studio/blob/main/.github/workflows/claude-incremental.yml) (dimagi/open-chat-studio)
- Creates the `claude-incremental` label
- Sets the `ANTHROPIC_API_KEY` secret
- Configures GitHub Actions permissions
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

1. Download the workflow from the [upstream source](https://raw.githubusercontent.com/dimagi/open-chat-studio/main/.github/workflows/claude-incremental.yml) and save it as `.github/workflows/claude-incremental.yml` in your repo
2. Create a `claude-incremental` label in your repo
3. Add `ANTHROPIC_API_KEY` as a repository secret (Settings > Secrets > Actions)
4. Set Actions permissions to "Read and write" (Settings > Actions > General)
5. Check "Allow GitHub Actions to create and approve pull requests"

### Hosting your own fork

Igor is a package -- you can fork it and host it in your own repo. Just update the
`RIG_BASE_URL` / `$RigBaseUrl` in the install scripts to point to your fork. Anyone
can then install from your repo using the same one-liner pattern.

## Verifying It Works

After installation, follow these steps to confirm Igor is working:

1. **Check the Actions tab** -- Go to your repo on GitHub, click "Actions" in the top nav. You should see "Igor" (or "claude-incremental") listed in the left sidebar. If it does not appear, make sure you committed and pushed the workflow file.

2. **Create a test issue** -- Create a new issue with the `claude-incremental` label and a simple one-item checklist, e.g.:
   ```
   ## Tasks
   ### Task 1: Add a comment to README
   - [ ] Task 1
   Add a comment to the top of README.md saying "Igor was here".
   ```

3. **Trigger the workflow manually** -- Go to Actions > Igor > "Run workflow" and click the green button. Watch the logs in real time.

4. **Check for a pull request** -- When the workflow completes, Igor should have created a new branch, pushed a commit, and opened a PR. The checklist item in the tracking issue should be checked off.

5. **Review the PR** -- The PR should contain a focused change matching the task. Merge it if it looks good. Igor will pick up the next unchecked task on the next run.

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
| `issue-template.md` | Template for creating tracking issues (sourced from Open Chat Studio docs) |
| `config.json` | Rig metadata and package info |

**Upstream files** (downloaded at install time, not bundled here):

| File | Source |
|------|--------|
| `claude-incremental.yml` | [dimagi/open-chat-studio](https://github.com/dimagi/open-chat-studio/blob/main/.github/workflows/claude-incremental.yml) |

## Credits

Based on [Open Chat Studio's Igor design](https://developers.openchatstudio.com/developer_guides/igor/).
