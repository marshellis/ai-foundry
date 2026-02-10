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
  /** Relative path within the rig source repo */
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

/** A single action the installer performs, shown to users for transparency */
export interface InstallerAction {
  /** Short label, e.g. "Download workflow file" */
  label: string;
  /** Longer explanation of what this step does and why */
  detail: string;
}

/** A step the user can follow to verify the rig is working correctly */
export interface VerificationStep {
  /** Short instruction, e.g. "Check the Actions tab" */
  instruction: string;
  /** What the user should see if it's working */
  expectedResult: string;
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
  /** Exactly what the installer script does, step by step, for transparency */
  installerActions?: InstallerAction[];
  /** Plain-language summary of what this rig does once installed */
  whatItDoes?: string;
  /** Steps users can follow to confirm the rig is working as designed */
  verificationSteps?: VerificationStep[];
  sourceUrl?: string;
  docsUrl?: string;
}
