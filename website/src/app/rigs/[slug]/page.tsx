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
import {
  buildInstallCommands,
  getRepoUrl,
  getFileUrl,
  fetchRigConfig,
} from "@/lib/rigs/types";

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

  // Fetch full config from the rig's config.json
  const config = await fetchRigConfig(rig.repository);

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
          {config?.tags?.map((tag) => (
            <Badge key={tag} variant="outline">
              {tag}
            </Badge>
          ))}
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

          {/* About */}
          <section>
            <h2 className="text-2xl font-semibold mb-4">About</h2>
            <p className="text-muted-foreground leading-relaxed whitespace-pre-wrap">
              {rig.description}
            </p>
          </section>

          {/* What It Does */}
          {config?.whatItDoes && (
            <section>
              <h2 className="text-2xl font-semibold mb-4">What It Does</h2>
              <p className="text-muted-foreground leading-relaxed">
                {config.whatItDoes}
              </p>
            </section>
          )}

          {/* Use Cases */}
          {config?.useCases && config.useCases.length > 0 && (
            <section>
              <h2 className="text-2xl font-semibold mb-4">Use Cases</h2>
              <ul className="list-disc list-inside space-y-2 text-muted-foreground">
                {config.useCases.map((useCase, i) => (
                  <li key={i}>{useCase}</li>
                ))}
              </ul>
            </section>
          )}

          {/* What the Installer Does */}
          {config?.installerActions && config.installerActions.length > 0 && (
            <section>
              <h2 className="text-2xl font-semibold mb-4">
                What the Installer Does
              </h2>
              <p className="text-sm text-muted-foreground mb-4">
                For transparency, here is exactly what the installer does:
              </p>
              <ol className="space-y-4">
                {config.installerActions.map((action, i) => (
                  <li key={i} className="flex gap-3">
                    <span className="flex-shrink-0 flex items-center justify-center w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium">
                      {i + 1}
                    </span>
                    <div>
                      <p className="font-medium">{action.label}</p>
                      <p className="text-sm text-muted-foreground">
                        {action.detail}
                      </p>
                    </div>
                  </li>
                ))}
              </ol>
            </section>
          )}

          {/* Verification Steps */}
          {config?.verificationSteps &&
            config.verificationSteps.length > 0 && (
              <section>
                <h2 className="text-2xl font-semibold mb-4">
                  Verifying It Works
                </h2>
                <p className="text-sm text-muted-foreground mb-4">
                  After installation, follow these steps to confirm everything
                  is working:
                </p>
                <ol className="space-y-6">
                  {config.verificationSteps.map((step, i) => (
                    <li key={i} className="flex gap-3">
                      <span className="flex-shrink-0 flex items-center justify-center w-6 h-6 rounded-full bg-primary/10 text-primary text-sm font-medium">
                        {i + 1}
                      </span>
                      <div className="space-y-2">
                        <p className="font-medium">{step.instruction}</p>
                        <p className="text-sm text-muted-foreground bg-muted/50 rounded-lg p-3">
                          <span className="font-medium text-foreground">
                            Expected:{" "}
                          </span>
                          {step.expectedResult}
                        </p>
                      </div>
                    </li>
                  ))}
                </ol>
              </section>
            )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Credits */}
          {config?.credits && (
            <Card className="border-amber-500/20 bg-amber-500/5">
              <CardHeader>
                <CardTitle className="text-lg">Based On</CardTitle>
                <CardDescription>{config.credits.description}</CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <a
                  href={config.credits.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block text-sm text-primary hover:underline"
                >
                  {config.credits.name} Documentation
                </a>
                {config.credits.repository && (
                  <a
                    href={config.credits.repository}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block text-sm text-primary hover:underline"
                  >
                    Source Repository
                  </a>
                )}
              </CardContent>
            </Card>
          )}

          {/* Prerequisites */}
          {config?.prerequisites && config.prerequisites.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Prerequisites</CardTitle>
                <CardDescription>What you need before installing</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {config.prerequisites.map((prereq, i) => (
                  <div key={i}>
                    <p className="text-sm font-medium">
                      {prereq.link ? (
                        <a
                          href={prereq.link}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-primary hover:underline"
                        >
                          {prereq.name}
                        </a>
                      ) : (
                        prereq.name
                      )}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {prereq.description}
                    </p>
                  </div>
                ))}
              </CardContent>
            </Card>
          )}

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

          {/* Files */}
          {config?.files && config.files.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Files</CardTitle>
                <CardDescription>What gets installed</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {config.files.map((file, i) => (
                  <div key={i}>
                    <p className="text-sm font-medium font-mono">
                      {file.upstreamUrl ? (
                        <a
                          href={file.upstreamUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-primary hover:underline"
                        >
                          {file.name}
                        </a>
                      ) : file.path ? (
                        <a
                          href={getFileUrl(rig.repository, file.name)}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-primary hover:underline"
                        >
                          {file.name}
                        </a>
                      ) : (
                        file.name
                      )}
                      {file.upstreamUrl && (
                        <span className="ml-2 text-xs font-normal text-muted-foreground">
                          (upstream)
                        </span>
                      )}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {file.description}
                    </p>
                    {file.installPath && (
                      <p className="text-xs text-muted-foreground font-mono">
                        Installs to: {file.installPath}
                      </p>
                    )}
                  </div>
                ))}
              </CardContent>
            </Card>
          )}

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
