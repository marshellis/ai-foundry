"use client";

import { useSession, signIn, signOut } from "next-auth/react";
import Link from "next/link";
import { Button } from "@/components/ui/button";

export function UserMenu() {
  const { data: session, status } = useSession();

  if (status === "loading") {
    return (
      <div className="h-8 w-20 animate-pulse rounded bg-muted" />
    );
  }

  if (!session?.user) {
    return (
      <Button
        variant="outline"
        size="sm"
        onClick={() => signIn("github")}
      >
        Sign in
      </Button>
    );
  }

  return (
    <div className="flex items-center gap-3">
      <Link
        href="/rigs/submit"
        className="text-sm text-foreground/60 transition-colors hover:text-foreground/80"
      >
        Submit Rig
      </Link>
      <div className="flex items-center gap-2">
        {session.user.image && (
          <img
            src={session.user.image}
            alt={session.user.name ?? "User avatar"}
            className="h-7 w-7 rounded-full"
          />
        )}
        <span className="text-sm text-foreground/80 hidden sm:inline">
          {session.user.name ?? session.user.login}
        </span>
      </div>
      <Button
        variant="ghost"
        size="sm"
        onClick={() => signOut()}
        className="text-xs text-foreground/60"
      >
        Sign out
      </Button>
    </div>
  );
}
