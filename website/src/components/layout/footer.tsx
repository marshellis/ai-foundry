import { Separator } from "@/components/ui/separator";

export function Footer() {
  return (
    <footer className="border-t">
      <div className="container mx-auto flex flex-col items-center gap-4 px-4 py-8 sm:px-8 md:flex-row md:justify-between">
        <p className="text-sm text-muted-foreground">
          AI Foundry -- A place to share and test different AI setups.
        </p>
        <div className="flex items-center gap-4 text-sm text-muted-foreground">
          <a
            href="https://github.com/marshellis/ai-foundry"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors hover:text-foreground"
          >
            GitHub
          </a>
          <Separator orientation="vertical" className="h-4" />
          <span>MIT License</span>
        </div>
      </div>
    </footer>
  );
}
