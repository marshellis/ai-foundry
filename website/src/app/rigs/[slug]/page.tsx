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
import { Separator } from "@/components/ui/separator";
import { getRigBySlug, rigs } from "@/lib/rigs/registry";

export function generateStaticParams() {
  return rigs.map((rig) => ({ slug: rig.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const rig = getRigBySlug(slug);
  if (!rig) return { title: "Not Found" };
  return {
    title: `${rig.name} | AI Foundry`,
    description: rig.tagline,
  };
}

function getFileGitHubUrl(
  repo: { owner: string; name: string; branch?: string; path: string },
  filePath: string
) {
  const branch = repo.branch ?? "main";
  return `https://github.com/${repo.owner}/${repo.name}/blob/${branch}/${filePath}`;
}

function getRawFileUrl(
  repo: { owner: string; name: string; branch?: string },
  filePath: string
) {
  const branch = repo.branch ?? "main";
  return `https://raw.githubusercontent.com/${repo.owner}/${repo.name}/${branch}/${filePath}`;
}

export default async function RigDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const rig = getRigBySlug(slug);
  if (!rig) notFound();

  const repoUrl = rig.repository
    ? `https://github.com/${rig.repository.owner}/${rig.repository.name}/tree/${rig.repository.branch ?? "main"}/${rig.repository.path}`
    : null;

  return (
    <div className="container mx-auto px-4 py-12 sm:px-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-start gap-4">
          <div className="flex-1">
            <h1 className="text-4xl font-bold tracking-tight">{rig.name}</h1>
            <p className="mt-2 text-xl text-muted-foreground">{rig.tagline}</p>
          </div>
          <Badge
            variant="outline"
            className={
              rig.status === "ready"
                ? "bg-green-500/10 text-green-700 dark:text-green-400 border-green-500/20"
                : ""
            }
          >
            {rig.status === "coming-soon" ? "Coming Soon" : rig.status}
          </Badge>
        </div>
        <div className="mt-4 flex flex-wrap gap-2">
          <Badge variant="secondary">{rig.difficulty}</Badge>
          <Badge variant="secondary">{rig.category}</Badge>
          {rig.tags.map((tag) => (
            <Badge key={tag} variant="outline">
              {tag}
            </Badge>
          ))}
        </div>
      </div>

      {/* Quick Install Banner */}
      {rig.installCommands && (
        <Card className="mb-8 border-primary/20 bg-primary/5">
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">Quick Install</CardTitle>
            <CardDescription>
              Run one command in your project directory. The script walks you
              through each step interactively.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <div>
              <p className="text-xs font-medium text-muted-foreground mb-1">
                PowerShell (Windows)
              </p>
              <pre className="overflow-x-auto rounded-lg bg-muted p-3 text-sm">
                <code>{rig.installCommands.powershell}</code>
              </pre>
            </div>
            <div>
              <p className="text-xs font-medium text-muted-foreground mb-1">
                Bash (macOS / Linux)
              </p>
              <pre className="overflow-x-auto rounded-lg bg-muted p-3 text-sm">
                <code>{rig.installCommands.bash}</code>
              </pre>
            </div>
            <div className="flex flex-wrap items-center gap-x-4 gap-y-1 pt-1 text-xs text-muted-foreground">
              {repoUrl && (
                <span>
                  Hosted at{" "}
                  <a
                    href={repoUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary hover:underline font-mono"
                  >
                    {rig.repository!.owner}/{rig.repository!.name}
                  </a>
                </span>
              )}
              {rig.repository && (
                <>
                  <a
                    href={getFileGitHubUrl(rig.repository, `${rig.repository.path}/install.ps1`)}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary hover:underline"
                  >
                    View install.ps1 source
                  </a>
                  <a
                    href={getFileGitHubUrl(rig.repository, `${rig.repository.path}/install.sh`)}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary hover:underline"
                  >
                    View install.sh source
                  </a>
                </>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* What the installer does */}
      {rig.installerActions && rig.installerActions.length > 0 && (
        <Card className="mb-8">
          <CardHeader>
            <CardTitle className="text-lg">
              What the installer does
            </CardTitle>
            <CardDescription>
              Exactly what happens when you run the install command, step by
              step. Nothing hidden.
              {rig.repository && (
                <>
                  {" "}
                  <a
                    href={repoUrl!}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary hover:underline"
                  >
                    Read the full source on GitHub.
                  </a>
                </>
              )}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ol className="space-y-4">
              {rig.installerActions.map((action, index) => (
                <li key={action.label} className="flex gap-3">
                  <span className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-muted text-xs font-medium text-muted-foreground">
                    {index + 1}
                  </span>
                  <div>
                    <p className="font-medium text-sm">{action.label}</p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {action.detail}
                    </p>
                  </div>
                </li>
              ))}
            </ol>
          </CardContent>
        </Card>
      )}

      {/* What this rig does */}
      {rig.whatItDoes && (
        <Card className="mb-8 border-blue-500/20 bg-blue-500/5">
          <CardHeader>
            <CardTitle className="text-lg">What this rig does</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground leading-relaxed">
              {rig.whatItDoes}
            </p>
          </CardContent>
        </Card>
      )}

      {/* How to verify it works */}
      {rig.verificationSteps && rig.verificationSteps.length > 0 && (
        <Card className="mb-8 border-green-500/20 bg-green-500/5">
          <CardHeader>
            <CardTitle className="text-lg">
              How to verify it works
            </CardTitle>
            <CardDescription>
              Follow these steps after installation to confirm the rig is
              working as designed.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ol className="space-y-4">
              {rig.verificationSteps.map((step, index) => (
                <li key={step.instruction} className="flex gap-3">
                  <span className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-green-500/20 text-xs font-medium text-green-700 dark:text-green-400">
                    {index + 1}
                  </span>
                  <div>
                    <p className="font-medium text-sm">{step.instruction}</p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      Expected: {step.expectedResult}
                    </p>
                  </div>
                </li>
              ))}
            </ol>
          </CardContent>
        </Card>
      )}

      <div className="grid gap-8 lg:grid-cols-3">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-8">
          {/* Description */}
          <section>
            <h2 className="text-2xl font-semibold mb-4">About</h2>
            <p className="text-muted-foreground leading-relaxed">
              {rig.description}
            </p>
          </section>

          {/* Use Cases */}
          <section>
            <h2 className="text-2xl font-semibold mb-4">Use Cases</h2>
            <ul className="space-y-2">
              {rig.useCases.map((useCase) => (
                <li
                  key={useCase}
                  className="flex items-start gap-2 text-muted-foreground"
                >
                  <span className="mt-1.5 h-1.5 w-1.5 rounded-full bg-primary flex-shrink-0" />
                  {useCase}
                </li>
              ))}
            </ul>
          </section>

          <Separator />

          {/* Setup Steps */}
          <section>
            <h2 className="text-2xl font-semibold mb-6">
              Step-by-Step Setup
            </h2>
            <div className="space-y-6">
              {rig.setupSteps.map((step, index) => (
                <div key={step.title} className="flex gap-4">
                  <div className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground text-sm font-bold">
                    {index + 1}
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold">{step.title}</h3>
                    <p className="mt-1 text-sm text-muted-foreground">
                      {step.description}
                    </p>
                    {step.command && (
                      <pre className="mt-3 overflow-x-auto rounded-lg bg-muted p-4 text-sm">
                        <code>{step.command}</code>
                      </pre>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </section>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Prerequisites */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Prerequisites</CardTitle>
              <CardDescription>What you need before setup</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {rig.prerequisites.map((prereq) => (
                <div key={prereq.name}>
                  <p className="font-medium text-sm">{prereq.name}</p>
                  <p className="text-xs text-muted-foreground">
                    {prereq.description}
                  </p>
                  {prereq.link && (
                    <a
                      href={prereq.link}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-primary hover:underline"
                    >
                      Get it here
                    </a>
                  )}
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Files -- with links to source (upstream or rig repo) */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Files</CardTitle>
              <CardDescription>
                Included in this rig -- click to view source
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              {rig.files.map((file) => {
                // Upstream files link directly to the original author's repo
                // Our files link to the rig's own repo
                const fileUrl = file.upstreamUrl
                  ? file.upstreamUrl
                  : file.path && rig.repository
                    ? getFileGitHubUrl(rig.repository, file.path)
                    : null;
                const isUpstream = !!file.upstreamUrl;
                return (
                  <div key={file.name}>
                    {fileUrl ? (
                      <a
                        href={fileUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="font-mono text-sm text-primary hover:underline"
                      >
                        {file.name}
                      </a>
                    ) : (
                      <p className="font-mono text-sm">{file.name}</p>
                    )}
                    <p className="text-xs text-muted-foreground">
                      {file.description}
                    </p>
                    {isUpstream && (
                      <p className="text-xs text-muted-foreground/70 italic">
                        upstream -- downloaded at install time
                      </p>
                    )}
                    {file.installPath && !isUpstream && (
                      <p className="text-xs text-muted-foreground/70">
                        installs to {file.installPath}
                      </p>
                    )}
                  </div>
                );
              })}
            </CardContent>
          </Card>

          {/* Package Info */}
          {rig.repository && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Package</CardTitle>
                <CardDescription>
                  Install from any public GitHub repo hosting this rig
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <div>
                  <p className="text-xs font-medium text-muted-foreground">
                    Source
                  </p>
                  <a
                    href={repoUrl!}
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
                  <p className="text-sm font-mono">
                    {rig.repository.branch ?? "main"}
                  </p>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Links */}
          <div className="flex flex-col gap-2">
            {rig.sourceUrl && (
              <Button asChild variant="outline" className="w-full">
                <a
                  href={rig.sourceUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Original Source
                </a>
              </Button>
            )}
            {rig.docsUrl && (
              <Button asChild variant="outline" className="w-full">
                <a
                  href={rig.docsUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Documentation
                </a>
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
