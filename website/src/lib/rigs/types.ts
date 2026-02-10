export type RigCategory = "ci-cd" | "coding" | "personal" | "automation";

export interface RigRepository {
  owner: string;
  name: string;
  branch: string;
  path: string;
}

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
