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
    installerActions: [
      {
        label: "Check prerequisites",
        detail:
          "Verifies that git and the GitHub CLI (gh) are installed and that you are authenticated with gh.",
      },
      {
        label: "Detect target repository",
        detail:
          "Reads your git remote to detect the GitHub repo, or prompts you to enter one. Verifies the repo exists and is accessible.",
      },
      {
        label: "Download workflow file",
        detail:
          "Downloads claude-incremental.yml from the rig source and places it at .github/workflows/claude-incremental.yml in your repo. This is the GitHub Action that runs Igor.",
      },
      {
        label: "Download issue template",
        detail:
          "Downloads a reference issue template to .igor/issue-template.md so you have the checklist format handy when creating tracking issues.",
      },
      {
        label: "Set ANTHROPIC_API_KEY secret",
        detail:
          "Prompts for your Anthropic API key and stores it as a GitHub Actions secret using the gh CLI. You can skip this and set it manually later. The key is sent directly to GitHub -- it is not stored locally.",
      },
      {
        label: "Create 'claude-incremental' label",
        detail:
          "Creates a GitHub label called 'claude-incremental' on your repo. Igor uses this label to find tracking issues to work on.",
      },
      {
        label: "Configure Actions permissions",
        detail:
          "Uses the GitHub API to set workflow permissions to read-write and allow GitHub Actions to create pull requests. This is required for Igor to push branches and open PRs.",
      },
      {
        label: "Optionally create a sample issue",
        detail:
          "Asks if you want to create a sample tracking issue with the correct format so you can see how Igor works right away.",
      },
    ],
    whatItDoes:
      "Once installed, Igor monitors your GitHub repository for issues labeled 'claude-incremental'. Each issue should contain a checklist of tasks. Every day at 2 AM UTC (or when triggered manually), Igor picks the next unchecked task, reads your codebase for context, implements the change on a new branch, opens a pull request, and checks off the task. You review and merge the PR like any other contribution. Over time, Igor chips away at large projects one task at a time.",
    verificationSteps: [
      {
        instruction:
          "Go to your repo's Actions tab on GitHub and confirm the 'Igor' workflow is listed",
        expectedResult:
          "You should see 'Igor' (or 'claude-incremental') in the left sidebar of the Actions page. If it does not appear, make sure you committed and pushed the workflow file.",
      },
      {
        instruction:
          "Create a test issue with the 'claude-incremental' label and a simple one-item checklist",
        expectedResult:
          "The issue should appear in your repo with the label. Use the format: '- [ ] Add a comment to the top of README.md' as a simple test task.",
      },
      {
        instruction:
          "Trigger the workflow manually: Actions > Igor > Run workflow",
        expectedResult:
          "The workflow run should appear in the Actions tab. Click into it to watch the logs in real time.",
      },
      {
        instruction:
          "Wait for the workflow to complete and check for a new pull request",
        expectedResult:
          "Igor should create a new branch, push a commit implementing the task, and open a pull request. The checklist item in the tracking issue should be checked off automatically.",
      },
      {
        instruction: "Review the pull request",
        expectedResult:
          "The PR should contain a focused change matching the task description. If everything looks good, merge it. Igor will pick up the next unchecked task on the next run.",
      },
    ],
    useCases: [
      "Migrate JS files to ES modules",
      "Add TypeScript types across a codebase",
      "Refactor a large module piece by piece",
      "Any project that can be broken into independent tasks",
    ],
    prerequisites: [
      {
        name: "GitHub Repository",
        description:
          "A public or private GitHub repo where you want Igor to work",
      },
      {
        name: "Anthropic API Key",
        description: "An API key from Anthropic for Claude access",
        link: "https://console.anthropic.com/",
      },
      {
        name: "GitHub CLI (gh)",
        description:
          "Used by the installer to configure secrets, labels, and permissions",
        link: "https://cli.github.com/",
      },
    ],
    setupSteps: [
      {
        title: "Run the one-command installer",
        description:
          "Open a terminal in your project directory and run the install command for your platform. The installer walks you through each step interactively.",
        command:
          "# PowerShell (Windows)\nirm https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.ps1 | iex\n\n# Bash (macOS/Linux)\ncurl -fsSL https://raw.githubusercontent.com/marshellis/ai-foundry/main/rigs/igor/install.sh | bash",
      },
      {
        title: "Commit and push",
        description:
          "Commit the workflow file and .igor/ directory, then push to your main branch.",
        command:
          'git add .github/workflows/claude-incremental.yml .igor/\ngit commit -m "Add Igor incremental worker"\ngit push',
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
