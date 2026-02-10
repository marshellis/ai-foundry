---
name: creating-rigs
description: Guide for creating AI Foundry rigs -- pre-packaged AI workflow setups with one-command installers. Use when the user wants to create a new rig, add an AI workflow to the catalog, build installer scripts, or asks about rig structure, registry, or the upstream-first pattern.
---

# Creating Rigs for AI Foundry

## Core Philosophy

A rig is a **thin orchestration layer**, not a fork. It documents setup, fills gaps the original author did not provide (installer scripts, verification steps, clear documentation), and wires things together. It points to the original author's files wherever possible so the rig stays current with upstream improvements.

**Rule of thumb:** If someone else wrote it and maintains it, reference it via URL. If we wrote it to fill a gap, it lives in our repo.

## Rig Directory Structure

```
rigs/<rig-name>/
  config.json          # Required -- rig metadata, credits, and full details
  install.ps1          # Required -- one-command installer for Windows (PowerShell)
  install.sh           # Required -- one-command installer for macOS/Linux (Bash)
  setup.ps1            # Optional -- local setup script (when files are already cloned)
  setup.sh             # Optional -- local setup script
  issue-template.md    # Optional -- any reference templates the rig needs
  README.md            # Required -- documentation with setup, verification, and file list
```

Do NOT bundle files maintained by the original author. Download them from upstream at install time.

## File Sourcing Rules

Each file in a rig is either **ours** or **upstream**:

| Source | When to use | In config.json | In installer |
|--------|-------------|----------------|--------------|
| **Ours** (`path`) | We wrote it to fill a gap | `path: "rigs/<name>/file"` | Bundled or downloaded from our repo |
| **Upstream** (`upstreamUrl`) | Original author maintains it | `upstreamUrl: "https://..."` | Downloaded from upstream at install time |

Example from Igor:
- `install.ps1` -- **ours** (we wrote the installer)
- `claude-incremental.yml` -- **upstream** (maintained by dimagi/open-chat-studio)

## config.json -- The Source of Truth

The rig's `config.json` is the **source of truth** for all rig details. The website fetches this file directly from GitHub and displays its contents. This keeps the rig self-contained and portable.

### Full config.json Schema

```json
{
  "name": "Display Name",
  "slug": "rig-name",
  "version": "1.0.0",
  "tagline": "One-line summary",
  "description": "Full paragraph description",
  "category": "ci-cd",
  "tags": ["tag1", "tag2"],
  "difficulty": "beginner",
  "status": "ready",

  "repository": {
    "owner": "...",
    "name": "...",
    "branch": "main",
    "path": "rigs/..."
  },

  "credits": {
    "name": "Original Author/Project Name",
    "description": "Brief explanation of what we're crediting",
    "url": "https://link-to-original-docs",
    "repository": "https://github.com/original/repo"
  },

  "whatItDoes": "Plain-language explanation of what happens once installed...",

  "useCases": [
    "Example use case 1",
    "Example use case 2"
  ],

  "prerequisites": [
    {
      "name": "Tool Name",
      "description": "What it's used for",
      "link": "https://where-to-get-it"
    }
  ],

  "installerActions": [
    {
      "label": "Step name",
      "detail": "What this step does and why"
    }
  ],

  "verificationSteps": [
    {
      "instruction": "What to do",
      "expectedResult": "What you should see"
    }
  ],

  "files": [
    {
      "name": "install.ps1",
      "description": "One-command installer for Windows",
      "path": "rigs/.../install.ps1"
    },
    {
      "name": "workflow.yml",
      "description": "The workflow file (from upstream)",
      "upstreamUrl": "https://github.com/...",
      "installPath": ".github/workflows/..."
    }
  ],

  "install": {
    "powershell": "irm ... | iex",
    "bash": "curl ... | bash"
  }
}
```

### Required Fields

Every rig config.json MUST have:

| Field | Purpose |
|-------|---------|
| `credits` | Attribution for the source material/approach |
| `whatItDoes` | Plain-language explanation of the full lifecycle |
| `installerActions` | Every step the installer performs (for transparency) |
| `verificationSteps` | How users confirm it works |
| `files` | What gets installed, with upstream vs. ours clearly marked |

## Database vs. config.json

The database stores minimal metadata for listing/searching:
- `slug`, `name`, `tagline`, `description`, `category`
- `repository` (to locate the config.json)
- `submittedBy`, `submittedByAvatar`, timestamps

The config.json stores the full details:
- `credits`, `whatItDoes`, `useCases`, `prerequisites`
- `installerActions`, `verificationSteps`, `files`
- `tags`, `difficulty`, `status`

The rig detail page fetches config.json from GitHub and displays all sections.

## Installer Script Design

### One-command install pattern

Users install rigs via:
- PowerShell: `irm https://raw.githubusercontent.com/OWNER/REPO/BRANCH/rigs/<name>/install.ps1 | iex`
- Bash: `curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/BRANCH/rigs/<name>/install.sh | bash`

### What every installer must do

1. **Check prerequisites** -- Verify required tools are installed (git, gh, curl, etc.)
2. **Detect target repository** -- Read git remote or prompt the user
3. **Download files** -- Upstream files from their original source, rig files from our repo
4. **Configure secrets/permissions** -- Set API keys, labels, Actions permissions as needed
5. **Print what was done** -- List files added, where they came from, and next steps
6. **Print verification steps** -- Tell the user exactly how to confirm it works

### Installer conventions

- Use clear step labels: `Write-Step` / `step()` for section headers
- Use `Write-Ok` / `ok()` for success, `Write-Warn` / `warn()` for non-critical issues
- Always allow skipping optional steps (API keys, sample issues)
- Clearly label upstream downloads: "Downloaded from upstream (owner/repo)"
- Never store secrets locally -- send directly to GitHub via `gh secret set`
- Include a "Files added" summary and "To verify it works" section at the end

## Verification Steps

Every rig MUST have concrete verification steps. Users need to know:
1. What to check immediately after install
2. How to trigger the rig for the first time
3. What success looks like
4. What to do if something goes wrong

Example pattern:
```typescript
verificationSteps: [
  {
    instruction: "Go to GitHub > Actions and confirm the workflow appears",
    expectedResult: "You should see the workflow in the left sidebar...",
  },
  {
    instruction: "Trigger the workflow manually",
    expectedResult: "The workflow run should appear in the Actions tab...",
  },
]
```

## Website Integration

The rig detail page (`/rigs/[slug]`) automatically renders:
- Quick Install banner with one-liner commands
- "What the installer does" section from `installerActions`
- "What this rig does" section from `whatItDoes`
- "How to verify it works" section from `verificationSteps`
- Files sidebar distinguishing upstream vs. ours
- Package info sidebar with repo details

No custom page code is needed -- just populate the registry entry fully.

## Anti-Patterns

- **Do NOT bundle upstream files** -- Download them at install time so they stay current
- **Do NOT create CLAUDE.md** -- Assume the target repo already has one or the user will create it
- **Do NOT use emojis** -- Causes Windows charmap encoding errors
- **Do NOT hardcode secrets** -- Always use `gh secret set` to send directly to GitHub
- **Do NOT skip verification steps** -- Every rig must tell users how to confirm it works
- **Do NOT use vague descriptions** -- `whatItDoes` should explain the full lifecycle in plain language

## Checklist for New Rigs

- [ ] Created `rigs/<name>/` directory with config.json, install scripts, README.md
- [ ] Upstream files referenced by URL, not bundled
- [ ] Install scripts download from upstream and clearly label the source
- [ ] Registry entry in `website/src/lib/rigs/registry.ts` with all required fields
- [ ] `whatItDoes` explains the full lifecycle in plain language
- [ ] `installerActions` lists every step the installer performs
- [ ] `verificationSteps` tells users exactly how to confirm it works
- [ ] Files array uses `upstreamUrl` for external files, `path` for ours
- [ ] README.md includes setup, verification, file list with upstream attribution
- [ ] Website builds successfully (`cd website && npm run build`)
