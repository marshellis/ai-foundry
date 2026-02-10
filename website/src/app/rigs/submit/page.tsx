import { redirect } from "next/navigation";
import { auth } from "@/lib/auth";
import { SubmitRigForm } from "@/components/rigs/submit-form";

export const metadata = {
  title: "Submit a Rig | AI Foundry",
  description: "Share your AI rig with the community.",
};

export default async function SubmitRigPage() {
  const session = await auth();

  if (!session?.user) {
    redirect("/api/auth/signin?callbackUrl=/rigs/submit");
  }

  return (
    <div className="container mx-auto max-w-3xl px-4 py-12 sm:px-8">
      <div className="mb-8">
        <h1 className="text-4xl font-bold tracking-tight">Submit a Rig</h1>
        <p className="mt-2 text-lg text-muted-foreground">
          Share your AI workflow with the community. Your rig must be hosted in a
          public GitHub repo with install.ps1 and install.sh scripts.
        </p>
      </div>
      <SubmitRigForm />
    </div>
  );
}
