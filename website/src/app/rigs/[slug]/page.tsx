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
              Run one command in your project directory to install {rig.name}.
              The script handles everything interactively.
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
            {repoUrl && (
              <p className="text-xs text-muted-foreground pt-1">
                Hosted at{" "}
                <a
                  href={repoUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary hover:underline font-mono"
                >
                  {rig.repository!.owner}/{rig.repository!.name}
                </a>
                {" -- "}or point to your own fork.
              </p>
            )}
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

          {/* Files */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Files</CardTitle>
              <CardDescription>Included in this rig</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              {rig.files.map((file) => (
                <div key={file.name}>
                  <p className="font-mono text-sm">{file.name}</p>
                  <p className="text-xs text-muted-foreground">
                    {file.description}
                  </p>
                </div>
              ))}
            </CardContent>
          </Card>

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
