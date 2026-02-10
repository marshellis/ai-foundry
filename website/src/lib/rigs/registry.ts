import type { Rig } from "./types";

export const rigs: Rig[] = [
  {
    slug: "igor",
    name: "Igor",
    tagline: "Incremental AI worker that chips away at large projects",
    description:
      "A GitHub Action that automatically makes incremental progress on large projects by working through tracking issues with task checklists. Create a tracking issue with a checklist, and Igor picks up the next unchecked task each day -- reading context, implementing the change, and opening a PR.",
    status: "ready",
    category: "ci-cd",
    tags: ["github-actions", "claude", "automation", "incremental"],
    difficulty: "beginner",
    repository: {
      owner: "marshellis",
      name: "ai-foundry",
      branch: "main",
      path: "rigs/igor",
    },
    installCommands: {
      powershell:
        "irm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.ps1 | iex",
      bash: "curl -fsSL https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.sh | bash",
    },
    useCases: [
      "Migrate JS files to ES modules",
      "Add TypeScript types across a codebase",
      "Refactor a large module piece by piece",
      "Any project that can be broken into independent tasks",
    ],
    prerequisites: [
      {
        name: "GitHub Repository",
        description: "A public or private GitHub repo where you want Igor to work",
      },
      {
        name: "Anthropic API Key",
        description: "An API key from Anthropic for Claude access",
        link: "https://console.anthropic.com/",
      },
      {
        name: "GitHub CLI (gh)",
        description: "Used by the installer to configure secrets, labels, and permissions",
        link: "https://cli.github.com/",
      },
    ],
    setupSteps: [
      {
        title: "Run the one-command installer",
        description:
          "Open a terminal in your project directory and run the install command for your platform. The installer downloads the workflow, configures secrets, creates labels, and sets permissions -- all interactively.",
        command:
          "# PowerShell (Windows)\nirm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.ps1 | iex\n\n# Bash (macOS/Linux)\ncurl -fsSL https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.sh | bash",
      },
      {
        title: "Edit CLAUDE.md",
        description:
          "The installer creates a CLAUDE.md template in your repo. Fill it in with your project's structure, build commands, and coding conventions. This is how Igor understands your codebase -- the better the context, the better the results.",
      },
      {
        title: "Commit and push",
        description:
          "Commit the workflow file, .igor/ directory, and CLAUDE.md, then push to your main branch.",
        command:
          'git add .github/workflows/claude-incremental.yml .igor/ CLAUDE.md\ngit commit -m "Add Igor incremental worker"\ngit push',
      },
      {
        title: "Create a tracking issue",
        description:
          "Create a GitHub issue with the 'claude-incremental' label using the checklist format. Igor picks up the first unchecked task and opens a PR. It runs daily at 2am UTC, or you can trigger it manually from the Actions tab.",
      },
    ],
    files: [
      {
        name: "install.ps1",
        description: "One-command installer for Windows (PowerShell)",
        path: "rigs/igor/install.ps1",
      },
      {
        name: "install.sh",
        description: "One-command installer for macOS/Linux (Bash)",
        path: "rigs/igor/install.sh",
      },
      {
        name: "workflow.yml",
        description: "The GitHub Actions workflow that powers Igor",
        path: "rigs/igor/workflow.yml",
      },
      {
        name: "issue-template.md",
        description: "Template for creating Igor tracking issues",
        path: "rigs/igor/issue-template.md",
      },
    ],
    sourceUrl:
      "https://developers.openchatstudio.com/developer_guides/igor/",
    docsUrl:
      "https://developers.openchatstudio.com/developer_guides/igor/#how-to-use",
  },
];

export function getRigBySlug(slug: string): Rig | undefined {
  return rigs.find((rig) => rig.slug === slug);
}

export function getRigsByCategory(category: string): Rig[] {
  return rigs.filter((rig) => rig.category === category);
}

export function getFeaturedRigs(): Rig[] {
  return rigs.filter((rig) => rig.status === "ready");
}
