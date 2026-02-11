export type RigCategory = "ci-cd" | "coding" | "personal" | "automation" | "self-hosted";

export interface RigRepository {
  owner: string;
  name: string;
  branch: string;
  path: string;
}

/**
 * Database rig record -- minimal metadata stored in the database.
 * Full rig details are stored in the rig's config.json file.
 */
export interface Rig {
  id: number;
  slug: string;
  name: string;
  tagline: string;
  description: string;
  category: RigCategory;
  repository: RigRepository;
  submittedBy: string;
  submittedByAvatar: string | null;
  createdAt: Date;
  updatedAt: Date;
}

// ---------------------------------------------------------------------------
// Rig Config Schema -- defines the structure of a rig's config.json file
// ---------------------------------------------------------------------------

/**
 * Credits/attribution for the source material the rig is based on.
 */
export interface RigCredits {
  /** Name of the original author or project */
  name: string;
  /** Description of what we're crediting */
  description: string;
  /** URL to the original documentation or project page */
  url: string;
  /** URL to the source repository (if applicable) */
  repository?: string;
}

/**
 * A prerequisite needed before installing the rig.
 */
export interface RigPrerequisite {
  /** Name of the prerequisite (e.g., "GitHub CLI") */
  name: string;
  /** Description of what it's used for */
  description: string;
  /** Optional link to get/install the prerequisite */
  link?: string;
}

/**
 * An action the installer performs -- for transparency.
 */
export interface RigInstallerAction {
  /** Short label for the action */
  label: string;
  /** Detailed explanation of what this step does */
  detail: string;
}

/**
 * A step to verify the rig is working correctly.
 */
export interface RigVerificationStep {
  /** What the user should do */
  instruction: string;
  /** What they should see if it's working */
  expectedResult: string;
}

/**
 * A file included in or referenced by the rig.
 */
export interface RigFile {
  /** Filename */
  name: string;
  /** What this file does */
  description: string;
  /** Path within the rig (for files we author) */
  path?: string;
  /** URL to upstream source (for files we download at install time) */
  upstreamUrl?: string;
  /** Where the file gets installed in the user's project */
  installPath?: string;
}

/**
 * Full rig configuration -- the schema for config.json files.
 * This is the source of truth for rig details.
 */
export interface RigConfig {
  /** Display name */
  name: string;
  /** URL-safe identifier */
  slug: string;
  /** Semantic version */
  version: string;
  /** One-line description */
  tagline: string;
  /** Full description */
  description: string;
  /** Category for filtering */
  category: RigCategory;
  /** Tags for discovery */
  tags: string[];
  /** Difficulty level */
  difficulty: "beginner" | "intermediate" | "advanced";
  /** Readiness status */
  status: "ready" | "beta" | "experimental";

  /** Repository location */
  repository: RigRepository;

  /** Credits for the source material/approach */
  credits: RigCredits;

  /** Plain-language explanation of what the rig does once installed */
  whatItDoes: string;

  /** Example use cases */
  useCases: string[];

  /** What's needed before installation */
  prerequisites: RigPrerequisite[];

  /** What the installer does (for transparency) */
  installerActions: RigInstallerAction[];

  /** How to verify it's working */
  verificationSteps: RigVerificationStep[];

  /** Files included in or referenced by the rig */
  files: RigFile[];

  /** One-command install commands */
  install: {
    powershell: string;
    bash: string;
  };
}

/**
 * Build install commands from repository info.
 */
export function buildInstallCommands(repo: RigRepository): {
  powershell: string;
  bash: string;
} {
  const rawBase = `https://raw.githubusercontent.com/${repo.owner}/${repo.name}/${repo.branch}/${repo.path}`;
  return {
    powershell: `irm ${rawBase}/install.ps1 | iex`,
    bash: `curl -fsSL ${rawBase}/install.sh | bash`,
  };
}

/**
 * Get the GitHub URL for the rig's source.
 */
export function getRepoUrl(repo: RigRepository): string {
  return `https://github.com/${repo.owner}/${repo.name}/tree/${repo.branch}/${repo.path}`;
}

/**
 * Get the GitHub URL for a specific file in the rig.
 */
export function getFileUrl(repo: RigRepository, fileName: string): string {
  return `https://github.com/${repo.owner}/${repo.name}/blob/${repo.branch}/${repo.path}/${fileName}`;
}

/**
 * Get the raw GitHub URL for a specific file in the rig.
 */
export function getRawFileUrl(repo: RigRepository, fileName: string): string {
  return `https://raw.githubusercontent.com/${repo.owner}/${repo.name}/${repo.branch}/${repo.path}/${fileName}`;
}

/**
 * Fetch the rig's config.json from GitHub.
 * Returns null if the config cannot be fetched or parsed.
 */
export async function fetchRigConfig(
  repo: RigRepository
): Promise<RigConfig | null> {
  const url = getRawFileUrl(repo, "config.json");
  try {
    const response = await fetch(url, { next: { revalidate: 300 } }); // Cache for 5 minutes
    if (!response.ok) return null;
    const config = await response.json();
    return config as RigConfig;
  } catch {
    return null;
  }
}
