# Project Context for Claude

## Overview

AI Foundry is a website and collection of "rigs" -- pre-built AI-powered workflows for personal and coding tasks. The core value proposition is eliminating setup friction. Users browse rigs on the website, then use automated setup scripts to get them running.

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

1. Create a directory under `rigs/<rig-name>/` with config.json, README.md, and any template files
2. Add the rig to the registry in `website/src/lib/rigs/registry.ts`
3. The rig will automatically appear on the website catalog and detail pages
