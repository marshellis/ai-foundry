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
    useCases: [
      "Migrate JS files to ES modules",
      "Add TypeScript types across a codebase",
      "Refactor a large module piece by piece",
      "Any project that can be broken into independent tasks",
    ],
    prerequisites: [
      {
        name: "GitHub Repository",
        description: "A GitHub repo where you want Igor to work",
      },
      {
        name: "Anthropic API Key",
        description: "An API key from Anthropic for Claude access",
        link: "https://console.anthropic.com/",
      },
      {
        name: "GitHub CLI (gh)",
        description: "Required for the automated setup script",
        link: "https://cli.github.com/",
      },
    ],
    setupSteps: [
      {
        title: "Run the setup script",
        description:
          "The setup script handles everything: copies the workflow file, creates labels, configures secrets, and sets permissions.",
        command: "# PowerShell (Windows)\n.\\setup.ps1 -RepoOwner your-org -RepoName your-repo\n\n# Bash (macOS/Linux)\n./setup.sh --repo-owner your-org --repo-name your-repo",
      },
      {
        title: "Create a tracking issue",
        description:
          "Create a GitHub issue using the provided template. Add the 'claude-incremental' label and structure your tasks as a checklist.",
      },
      {
        title: "Set status to In Progress",
        description:
          "When you're ready for Igor to start working, set the issue status. Igor runs daily at 2am UTC or can be triggered manually.",
      },
    ],
    files: [
      {
        name: "claude-incremental.yml",
        description: "The GitHub Actions workflow that powers Igor",
        path: "rigs/igor/workflow.yml",
      },
      {
        name: "issue-template.md",
        description: "Template for creating Igor tracking issues",
        path: "rigs/igor/issue-template.md",
      },
      {
        name: "setup.ps1",
        description: "Automated setup script for Windows (PowerShell)",
        path: "rigs/igor/setup.ps1",
      },
      {
        name: "setup.sh",
        description: "Automated setup script for macOS/Linux (Bash)",
        path: "rigs/igor/setup.sh",
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
