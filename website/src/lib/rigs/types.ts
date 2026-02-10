export type RigStatus = "ready" | "coming-soon" | "beta";

export type RigCategory = "ci-cd" | "coding" | "personal" | "automation";

export interface RigPrerequisite {
  name: string;
  description: string;
  link?: string;
}

export interface RigSetupStep {
  title: string;
  description: string;
  command?: string;
}

export interface RigFile {
  name: string;
  description: string;
  path: string;
}

export interface RigRepository {
  /** GitHub owner (user or org) */
  owner: string;
  /** GitHub repository name */
  name: string;
  /** Branch to fetch from (default: main) */
  branch?: string;
  /** Path within the repo where the rig lives */
  path: string;
}

export interface RigInstallCommands {
  /** One-liner for PowerShell (Windows) */
  powershell: string;
  /** One-liner for bash (macOS/Linux) */
  bash: string;
}

export interface Rig {
  slug: string;
  name: string;
  tagline: string;
  description: string;
  status: RigStatus;
  category: RigCategory;
  tags: string[];
  difficulty: "beginner" | "intermediate" | "advanced";
  useCases: string[];
  prerequisites: RigPrerequisite[];
  setupSteps: RigSetupStep[];
  files: RigFile[];
  /** Where the rig is hosted -- enables package-like referencing from any public GitHub repo */
  repository?: RigRepository;
  /** One-command install strings for each platform */
  installCommands?: RigInstallCommands;
  sourceUrl?: string;
  docsUrl?: string;
}
