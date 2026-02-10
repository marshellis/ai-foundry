import { RigCard } from "@/components/rigs/rig-card";
import { getAllRigs } from "@/lib/rigs/data";

export const metadata = {
  title: "Rigs | AI Foundry",
  description: "Browse AI rigs -- pre-packaged workflows you can install and try in your own projects.",
};

export const dynamic = "force-dynamic";

export default async function RigsPage() {
  const rigs = await getAllRigs();

  return (
    <div className="container mx-auto px-4 py-12 sm:px-8">
      <div className="mb-8">
        <h1 className="text-4xl font-bold tracking-tight">Rigs</h1>
        <p className="mt-2 text-lg text-muted-foreground">
          AI workflows you can install with one command and try in your own
          projects. Each rig is a package hosted on GitHub.
        </p>
      </div>

      {rigs.length === 0 ? (
        <p className="text-muted-foreground">No rigs yet. Be the first to submit one!</p>
      ) : (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {rigs.map((rig) => (
            <RigCard key={rig.slug} rig={rig} />
          ))}
        </div>
      )}
    </div>
  );
}
