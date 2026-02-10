import Link from "next/link";
import { Button } from "@/components/ui/button";
import { RigCard } from "@/components/rigs/rig-card";
import { getFeaturedRigs } from "@/lib/rigs/registry";

export default function Home() {
  const featuredRigs = getFeaturedRigs();

  return (
    <div className="flex flex-col">
      {/* Hero Section */}
      <section className="container mx-auto flex flex-col items-center gap-8 px-4 py-24 text-center sm:px-8 md:py-32">
        <h1 className="max-w-3xl text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl">
          AI rigs, ready to run.
          <span className="block text-muted-foreground mt-2">
            Zero setup friction.
          </span>
        </h1>
        <p className="max-w-2xl text-lg text-muted-foreground sm:text-xl">
          AI Foundry is a collection of pre-built AI-powered workflows for
          personal and coding tasks. Browse rigs, follow the setup guide, and
          get running in minutes -- not hours.
        </p>
        <div className="flex gap-4">
          <Button asChild size="lg">
            <Link href="/rigs">Browse Rigs</Link>
          </Button>
          <Button asChild variant="outline" size="lg">
            <a
              href="https://github.com/marshellis/ai-foundry"
              target="_blank"
              rel="noopener noreferrer"
            >
              View on GitHub
            </a>
          </Button>
        </div>
      </section>

      {/* How It Works */}
      <section className="border-t bg-muted/50">
        <div className="container mx-auto px-4 py-16 sm:px-8">
          <h2 className="mb-12 text-center text-3xl font-bold tracking-tight">
            How It Works
          </h2>
          <div className="grid gap-8 md:grid-cols-3">
            <div className="flex flex-col items-center gap-4 text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary text-primary-foreground text-lg font-bold">
                1
              </div>
              <h3 className="text-xl font-semibold">Pick a Rig</h3>
              <p className="text-muted-foreground">
                Browse the catalog of pre-built AI workflows. Each rig solves a
                specific problem -- from incremental code refactoring to
                automated documentation.
              </p>
            </div>
            <div className="flex flex-col items-center gap-4 text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary text-primary-foreground text-lg font-bold">
                2
              </div>
              <h3 className="text-xl font-semibold">Run the Setup</h3>
              <p className="text-muted-foreground">
                Each rig comes with an automated setup script. Run it, answer a
                few prompts, and the rig handles the rest -- secrets, configs,
                permissions.
              </p>
            </div>
            <div className="flex flex-col items-center gap-4 text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary text-primary-foreground text-lg font-bold">
                3
              </div>
              <h3 className="text-xl font-semibold">Let It Work</h3>
              <p className="text-muted-foreground">
                Your rig runs on autopilot. It picks up tasks, makes changes,
                opens PRs, and reports back. You review and merge.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Featured Rigs */}
      <section className="container mx-auto px-4 py-16 sm:px-8">
        <div className="mb-8 flex items-center justify-between">
          <h2 className="text-3xl font-bold tracking-tight">Featured Rigs</h2>
          <Button asChild variant="ghost">
            <Link href="/rigs">View all</Link>
          </Button>
        </div>
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {featuredRigs.map((rig) => (
            <RigCard key={rig.slug} rig={rig} />
          ))}
        </div>
      </section>
    </div>
  );
}
