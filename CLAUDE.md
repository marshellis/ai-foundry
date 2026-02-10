# Project Context for Claude

## Overview

AI Foundry is a website and collection of "rigs" -- pre-packaged AI workflows for coding and personal tasks. It is a place to share and test different AI setups. The hardest part of trying new AI workflows is usually the configuration, so each rig comes with a one-command installer. Rigs are hosted as packages on public GitHub repos -- they can live in the ai-foundry catalog or in anyone's own repo.

## Directory Structure

```
ai-foundry/
  .github/workflows/          # GitHub Actions (including Igor)
  website/                     # Next.js 15 web application
    src/
      app/                     # Next.js App Router pages
        layout.tsx             # Root layout with navbar + footer
        page.tsx               # Landing page
        rigs/
          page.tsx             # Rig catalog
          [slug]/page.tsx      # Individual rig detail page
      components/
        ui/                    # shadcn/ui components (do not edit directly)
        layout/                # Navbar, footer
        rigs/                  # Rig-specific components (cards, etc.)
      lib/
        rigs/
          types.ts             # Rig TypeScript interfaces
          registry.ts          # Central rig registry (add new rigs here)
        utils.ts               # Utility functions (cn helper)
  rigs/                        # Rig definitions (portable, may split to own repo)
    igor/                      # Igor rig files
      config.json              # Rig metadata
      workflow.yml             # GitHub Actions workflow template
      issue-template.md        # Issue template for users
      setup.ps1                # Windows setup script
      setup.sh                 # macOS/Linux setup script
      README.md                # Rig documentation
  CLAUDE.md                    # This file - project context for Claude
  README.md                    # Project README
```

## Development

### Install dependencies
```bash
cd website
npm install
```

### Run dev server
```bash
cd website
npm run dev
```
The dev server runs at http://localhost:3000.

### Build for production
```bash
cd website
npm run build
```

### Lint
```bash
cd website
npm run lint
```

## Tech Stack

- **Framework:** Next.js 15 with App Router, React 19, TypeScript
- **Styling:** Tailwind CSS v4 + shadcn/ui components
- **Package Manager:** npm
- **Fonts:** Geist Sans and Geist Mono

## Conventions

- Use TypeScript for all code
- Use the `@/` import alias (maps to `website/src/`)
- Use shadcn/ui components from `@/components/ui/` -- do not modify these directly
- Custom components go in `@/components/layout/` or `@/components/rigs/`
- Rig data is defined in `@/lib/rigs/registry.ts` using the `Rig` interface from `types.ts`
- Pages use Next.js App Router conventions (page.tsx, layout.tsx)
- Server components by default; add "use client" only when needed
- No emojis in code, comments, or documentation (causes Windows encoding issues)
- Use double dashes (--) instead of em dashes

## Adding a New Rig

### Hosted in this repo
1. Create a directory under `rigs/<rig-name>/` with config.json, README.md, install.ps1, install.sh, and any template files
2. The install scripts should be self-contained: download rig files from GitHub raw URLs and run setup interactively
3. Add the rig to the registry in `website/src/lib/rigs/registry.ts` with a `repository` and `installCommands` field
4. The rig will automatically appear on the website catalog and detail pages

### Hosted externally
Rigs can also live in any public GitHub repo. As long as the repo has an install.ps1/install.sh at a known path, users can install via:
  - PowerShell: `irm https://raw.githubusercontent.com/OWNER/REPO/BRANCH/PATH/install.ps1 | iex`
  - Bash: `curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/BRANCH/PATH/install.sh | bash`

External rigs can be added to the website registry by pointing the `repository` field to the external repo.
