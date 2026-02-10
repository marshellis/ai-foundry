# AI Foundry

A place to share and test different AI setups.

## What is AI Foundry?

AI Foundry is an open collection of **rigs** -- pre-packaged AI workflows for coding and personal tasks. The hardest part of trying new AI setups is usually the configuration, so each rig comes with:

- A clear description of what it does and when to use it
- A **one-command installer** that handles configuration, secrets, and permissions
- Template files and documentation so you can understand what you are running

Rigs are hosted as packages on public GitHub repos. You can install rigs from the AI Foundry catalog, from someone else's repo, or share your own.

## Available Rigs

### Igor (Incremental Worker)

A GitHub Action that automatically makes incremental progress on large projects by working through tracking issues with task checklists. Based on [Open Chat Studio's design](https://developers.openchatstudio.com/developer_guides/igor/).

**Use cases:**
- Migrate JS files to ES modules
- Add TypeScript types across a codebase
- Refactor a large module piece by piece
- Any project that can be broken into independent tasks

**Quick start -- run from your project directory:**
```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.ps1 | iex
```

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.sh | bash
```

The installer handles everything interactively: downloads the workflow, configures secrets, creates labels, and sets permissions.

## Development

The website is a Next.js 15 application.

```bash
cd website
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the site.

## Project Structure

```
ai-foundry/
  website/          # Next.js web application
  rigs/             # Rig definitions and setup scripts
    igor/           # Igor incremental worker rig
  .github/          # GitHub Actions workflows
  CLAUDE.md         # AI context file for Claude/Igor
```

## Contributing

This project uses Igor to help build itself. Check the [Issues](https://github.com/marshellis/ai-foundry/issues) page for tracked work items.

## License

MIT
