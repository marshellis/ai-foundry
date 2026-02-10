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
          A place to share and test
          <span className="block text-muted-foreground mt-2">
            different AI setups.
          </span>
        </h1>
        <p className="max-w-2xl text-lg text-muted-foreground sm:text-xl">
          AI Foundry is an open collection of &quot;rigs&quot; -- pre-packaged
          AI workflows for coding and personal tasks. Each rig comes with a
          one-command installer so you can try it out without wrestling with
          configuration.
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
                Browse the catalog of AI workflows people have shared. Each rig
                is a different approach to using AI -- from incremental code
                refactoring to automated documentation.
              </p>
            </div>
            <div className="flex flex-col items-center gap-4 text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary text-primary-foreground text-lg font-bold">
                2
              </div>
              <h3 className="text-xl font-semibold">Run the Installer</h3>
              <p className="text-muted-foreground">
                Each rig has a one-command installer. Run it, answer a few
                prompts, and it handles the tedious parts -- secrets, configs,
                permissions, file copying.
              </p>
            </div>
            <div className="flex flex-col items-center gap-4 text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary text-primary-foreground text-lg font-bold">
                3
              </div>
              <h3 className="text-xl font-semibold">Try It Out</h3>
              <p className="text-muted-foreground">
                See how the rig works in your own project. Tweak it, fork it,
                or share your own setup back with the community.
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
