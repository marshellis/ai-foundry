# AI Foundry

Pre-built AI rigs for personal and coding tasks. Zero setup friction.

## What is AI Foundry?

AI Foundry is a collection of **rigs** -- pre-packaged AI-powered workflows that solve specific problems. Each rig comes with:

- A clear description of what it does and when to use it
- An automated setup script that handles configuration, secrets, and permissions
- Template files you can copy into your own projects

The website lets you browse available rigs, understand what they do, and get set up quickly.

## Available Rigs

### Igor (Incremental Worker)

A GitHub Action that automatically makes incremental progress on large projects by working through tracking issues with task checklists. Based on [Open Chat Studio's design](https://developers.openchatstudio.com/developer_guides/igor/).

**Use cases:**
- Migrate JS files to ES modules
- Add TypeScript types across a codebase
- Refactor a large module piece by piece
- Any project that can be broken into independent tasks

**Quick start:**
```powershell
# Windows (PowerShell)
.\rigs\igor\setup.ps1 -RepoOwner your-org -RepoName your-repo
```

```bash
# macOS/Linux
./rigs/igor/setup.sh --repo-owner your-org --repo-name your-repo
```

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
