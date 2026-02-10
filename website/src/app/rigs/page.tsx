import { RigCard } from "@/components/rigs/rig-card";
import { rigs } from "@/lib/rigs/registry";

export const metadata = {
  title: "Rigs | AI Foundry",
  description: "Browse pre-built AI rigs for personal and coding tasks.",
};

export default function RigsPage() {
  return (
    <div className="container mx-auto px-4 py-12 sm:px-8">
      <div className="mb-8">
        <h1 className="text-4xl font-bold tracking-tight">Rigs</h1>
        <p className="mt-2 text-lg text-muted-foreground">
          Pre-built AI workflows you can set up in minutes.
        </p>
      </div>
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {rigs.map((rig) => (
          <RigCard key={rig.slug} rig={rig} />
        ))}
      </div>
    </div>
  );
}
