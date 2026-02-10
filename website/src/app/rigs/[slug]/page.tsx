import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { getRigBySlug } from "@/lib/rigs/data";
import { buildInstallCommands, getRepoUrl, getFileUrl } from "@/lib/rigs/types";

export const dynamic = "force-dynamic";

const categoryLabels: Record<string, string> = {
  "ci-cd": "CI/CD",
  coding: "Coding",
  personal: "Personal",
  automation: "Automation",
};

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const rig = await getRigBySlug(slug);
  if (!rig) return { title: "Not Found" };
  return {
    title: `${rig.name} | AI Foundry`,
    description: rig.tagline,
  };
}

export default async function RigDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const rig = await getRigBySlug(slug);

  if (!rig) notFound();

  const installCommands = buildInstallCommands(rig.repository);
  const repoUrl = getRepoUrl(rig.repository);

  return (
    <div className="container mx-auto px-4 py-12 sm:px-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold tracking-tight">{rig.name}</h1>
        <p className="mt-2 text-xl text-muted-foreground">{rig.tagline}</p>
        <div className="mt-4 flex flex-wrap items-center gap-3">
          <Badge variant="secondary">
            {categoryLabels[rig.category] ?? rig.category}
          </Badge>
          <span className="flex items-center gap-1.5 text-sm text-muted-foreground">
            {rig.submittedByAvatar && (
              <img
                src={rig.submittedByAvatar}
                alt={rig.submittedBy}
                className="h-5 w-5 rounded-full"
              />
            )}
            by{" "}
            <a
              href={`https://github.com/${rig.submittedBy}`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-primary hover:underline"
            >
              {rig.submittedBy}
            </a>
          </span>
        </div>
      </div>

      <div className="grid gap-8 lg:grid-cols-3">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-8">
          {/* Quick Install */}
          <Card className="border-primary/20 bg-primary/5">
            <CardHeader className="pb-3">
              <CardTitle className="text-lg">Quick Install</CardTitle>
              <CardDescription>
                Run one command in your project directory.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-xs font-medium text-muted-foreground mb-1">
                  PowerShell (Windows)
                </p>
                <pre className="overflow-x-auto rounded-lg bg-muted p-3 text-sm">
                  <code>{installCommands.powershell}</code>
                </pre>
              </div>
              <div>
                <p className="text-xs font-medium text-muted-foreground mb-1">
                  Bash (macOS / Linux)
                </p>
                <pre className="overflow-x-auto rounded-lg bg-muted p-3 text-sm">
                  <code>{installCommands.bash}</code>
                </pre>
              </div>
            </CardContent>
          </Card>

          {/* Description */}
          <section>
            <h2 className="text-2xl font-semibold mb-4">About</h2>
            <p className="text-muted-foreground leading-relaxed whitespace-pre-wrap">
              {rig.description}
            </p>
          </section>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Source */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Source</CardTitle>
              <CardDescription>View the rig on GitHub</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-xs font-medium text-muted-foreground">
                  Repository
                </p>
                <a
                  href={repoUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm font-mono text-primary hover:underline"
                >
                  {rig.repository.owner}/{rig.repository.name}
                </a>
              </div>
              <div>
                <p className="text-xs font-medium text-muted-foreground">
                  Path
                </p>
                <p className="text-sm font-mono">{rig.repository.path}</p>
              </div>
              <div>
                <p className="text-xs font-medium text-muted-foreground">
                  Branch
                </p>
                <p className="text-sm font-mono">{rig.repository.branch}</p>
              </div>
            </CardContent>
          </Card>

          {/* Install Scripts */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Install Scripts</CardTitle>
              <CardDescription>View source before running</CardDescription>
            </CardHeader>
            <CardContent className="space-y-2">
              <a
                href={getFileUrl(rig.repository, "install.ps1")}
                target="_blank"
                rel="noopener noreferrer"
                className="block text-sm text-primary hover:underline"
              >
                install.ps1
              </a>
              <a
                href={getFileUrl(rig.repository, "install.sh")}
                target="_blank"
                rel="noopener noreferrer"
                className="block text-sm text-primary hover:underline"
              >
                install.sh
              </a>
            </CardContent>
          </Card>

          <Button asChild variant="outline" className="w-full">
            <a href={repoUrl} target="_blank" rel="noopener noreferrer">
              View on GitHub
            </a>
          </Button>
        </div>
      </div>
    </div>
  );
}
