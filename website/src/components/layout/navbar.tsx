"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const navLinks = [
  { href: "/", label: "Home" },
  { href: "/rigs", label: "Rigs" },
];

export function Navbar() {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto flex h-14 max-w-screen-2xl items-center px-4 sm:px-8">
        <Link href="/" className="mr-8 flex items-center space-x-2">
          <span className="text-lg font-bold tracking-tight">
            AI Foundry
          </span>
        </Link>
        <nav className="flex items-center gap-6 text-sm">
          {navLinks.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className={cn(
                "transition-colors hover:text-foreground/80",
                pathname === link.href
                  ? "text-foreground font-medium"
                  : "text-foreground/60"
              )}
            >
              {link.label}
            </Link>
          ))}
        </nav>
        <div className="ml-auto flex items-center gap-4">
          <a
            href="https://github.com/marshellis/ai-foundry"
            target="_blank"
            rel="noopener noreferrer"
            className="text-foreground/60 transition-colors hover:text-foreground/80 text-sm"
          >
            GitHub
          </a>
        </div>
      </div>
    </header>
  );
}
