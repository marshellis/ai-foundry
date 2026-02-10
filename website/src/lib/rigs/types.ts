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
  sourceUrl?: string;
  docsUrl?: string;
}
