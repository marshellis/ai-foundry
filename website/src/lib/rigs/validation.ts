import { z } from "zod";

const slugRegex = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export const submitRigSchema = z.object({
  name: z.string().min(1, "Name is required").max(100),
  tagline: z.string().min(1, "Tagline is required").max(200),
  description: z.string().min(10, "Description must be at least 10 characters").max(2000),
  category: z.enum(["ci-cd", "coding", "personal", "automation"]),
  repository: z.object({
    owner: z.string().min(1, "Repository owner is required"),
    name: z.string().min(1, "Repository name is required"),
    branch: z.string().default("main"),
    path: z.string().min(1, "Path within the repository is required"),
  }),
});

export type SubmitRigInput = z.infer<typeof submitRigSchema>;

/**
 * Generate a URL-friendly slug from a name.
 */
export function nameToSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

/**
 * Validate that a GitHub repo exists and contains install.ps1 and install.sh
 * at the specified path.
 */
export async function validateGitHubRepo(
  owner: string,
  name: string,
  branch: string,
  path: string
): Promise<{ valid: boolean; error?: string }> {
  const url = `https://api.github.com/repos/${owner}/${name}/contents/${path}?ref=${branch}`;

  try {
    const res = await fetch(url, {
      headers: {
        Accept: "application/vnd.github.v3+json",
        "User-Agent": "ai-foundry",
      },
    });

    if (res.status === 404) {
      return {
        valid: false,
        error: `Repository or path not found: ${owner}/${name}/${path} (branch: ${branch})`,
      };
    }

    if (!res.ok) {
      return {
        valid: false,
        error: `GitHub API error: ${res.status} ${res.statusText}`,
      };
    }

    const files = await res.json();
    if (!Array.isArray(files)) {
      return {
        valid: false,
        error: "The specified path is not a directory",
      };
    }

    const fileNames = files.map((f: { name: string }) => f.name);

    if (!fileNames.includes("install.ps1")) {
      return {
        valid: false,
        error: "Missing install.ps1 in the specified path",
      };
    }

    if (!fileNames.includes("install.sh")) {
      return {
        valid: false,
        error: "Missing install.sh in the specified path",
      };
    }

    return { valid: true };
  } catch {
    return {
      valid: false,
      error: "Failed to reach GitHub API. Please try again.",
    };
  }
}

/**
 * Build install commands from repository info.
 */
export function buildInstallCommands(repo: {
  owner: string;
  name: string;
  branch: string;
  path: string;
}): { powershell: string; bash: string } {
  const rawBase = `https://raw.githubusercontent.com/${repo.owner}/${repo.name}/${repo.branch}/${repo.path}`;
  return {
    powershell: `irm ${rawBase}/install.ps1 | iex`,
    bash: `curl -fsSL ${rawBase}/install.sh | bash`,
  };
}
