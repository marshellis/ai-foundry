"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Loader2 } from "lucide-react";

const categories = [
  { value: "ci-cd", label: "CI/CD" },
  { value: "coding", label: "Coding" },
  { value: "personal", label: "Personal" },
  { value: "automation", label: "Automation" },
];

interface GitHubBranch {
  name: string;
}

interface GitHubContent {
  name: string;
  type: string;
  path: string;
}

function parseRepoInput(input: string): { owner: string; name: string } | null {
  const trimmed = input.trim();
  
  // Handle full GitHub URLs: https://github.com/owner/repo or https://github.com/owner/repo.git
  const urlMatch = trimmed.match(/github\.com\/([^/]+)\/([^/.]+)/);
  if (urlMatch) {
    return { owner: urlMatch[1], name: urlMatch[2] };
  }
  
  // Handle owner/repo format
  const slashMatch = trimmed.match(/^([^/]+)\/([^/]+)$/);
  if (slashMatch) {
    return { owner: slashMatch[1], name: slashMatch[2] };
  }
  
  return null;
}

export function SubmitRigForm() {
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string[]>>({});

  // Form state
  const [name, setName] = useState("");
  const [tagline, setTagline] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState("");
  const [repoInput, setRepoInput] = useState("");
  const [repoBranch, setRepoBranch] = useState("");
  const [repoPath, setRepoPath] = useState("");

  // Dynamic data from GitHub
  const [parsedRepo, setParsedRepo] = useState<{ owner: string; name: string } | null>(null);
  const [branches, setBranches] = useState<string[]>([]);
  const [paths, setPaths] = useState<string[]>([]);
  const [isLoadingBranches, setIsLoadingBranches] = useState(false);
  const [isLoadingPaths, setIsLoadingPaths] = useState(false);
  const [repoError, setRepoError] = useState<string | null>(null);

  // Parse repo input and fetch branches when it changes
  useEffect(() => {
    const parsed = parseRepoInput(repoInput);
    setParsedRepo(parsed);
    
    if (!parsed) {
      setBranches([]);
      setPaths([]);
      setRepoBranch("");
      setRepoPath("");
      setRepoError(repoInput.trim() ? "Enter a valid repository (owner/repo or GitHub URL)" : null);
      return;
    }

    setRepoError(null);
    setIsLoadingBranches(true);
    setBranches([]);
    setRepoBranch("");
    setPaths([]);
    setRepoPath("");

    fetch(`https://api.github.com/repos/${parsed.owner}/${parsed.name}/branches`, {
      headers: { Accept: "application/vnd.github.v3+json" },
    })
      .then((res) => {
        if (!res.ok) {
          throw new Error(res.status === 404 ? "Repository not found" : "Failed to fetch branches");
        }
        return res.json();
      })
      .then((data: GitHubBranch[]) => {
        const branchNames = data.map((b) => b.name);
        setBranches(branchNames);
        // Auto-select main or master if available
        if (branchNames.includes("main")) {
          setRepoBranch("main");
        } else if (branchNames.includes("master")) {
          setRepoBranch("master");
        } else if (branchNames.length > 0) {
          setRepoBranch(branchNames[0]);
        }
      })
      .catch((err) => {
        setRepoError(err.message);
      })
      .finally(() => {
        setIsLoadingBranches(false);
      });
  }, [repoInput]);

  // Fetch paths containing install scripts when branch changes
  const findRigPaths = useCallback(async (owner: string, repo: string, branch: string, currentPath = ""): Promise<string[]> => {
    const url = currentPath
      ? `https://api.github.com/repos/${owner}/${repo}/contents/${currentPath}?ref=${branch}`
      : `https://api.github.com/repos/${owner}/${repo}/contents?ref=${branch}`;

    const res = await fetch(url, {
      headers: { Accept: "application/vnd.github.v3+json" },
    });

    if (!res.ok) return [];

    const contents: GitHubContent[] = await res.json();
    if (!Array.isArray(contents)) return [];

    const rigPaths: string[] = [];
    const fileNames = contents.map((c) => c.name);

    // Check if this directory has at least one install script
    if (fileNames.includes("install.ps1") || fileNames.includes("install.sh")) {
      rigPaths.push(currentPath || ".");
    }

    // Recursively check subdirectories (limit depth to avoid too many API calls)
    const depth = currentPath.split("/").filter(Boolean).length;
    if (depth < 3) {
      const dirs = contents.filter((c) => c.type === "dir" && !c.name.startsWith(".") && c.name !== "node_modules");
      const subResults = await Promise.all(
        dirs.slice(0, 10).map((d) => findRigPaths(owner, repo, branch, d.path))
      );
      rigPaths.push(...subResults.flat());
    }

    return rigPaths;
  }, []);

  useEffect(() => {
    if (!parsedRepo || !repoBranch) {
      setPaths([]);
      setRepoPath("");
      return;
    }

    setIsLoadingPaths(true);
    setPaths([]);
    setRepoPath("");

    findRigPaths(parsedRepo.owner, parsedRepo.name, repoBranch)
      .then((foundPaths) => {
        setPaths(foundPaths);
        if (foundPaths.length === 1) {
          setRepoPath(foundPaths[0]);
        }
      })
      .catch(() => {
        setPaths([]);
      })
      .finally(() => {
        setIsLoadingPaths(false);
      });
  }, [parsedRepo, repoBranch, findRigPaths]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    
    if (!parsedRepo) {
      setError("Please enter a valid GitHub repository");
      return;
    }

    setIsSubmitting(true);
    setError(null);
    setFieldErrors({});

    const body = {
      name,
      tagline,
      description,
      category,
      repository: {
        owner: parsedRepo.owner,
        name: parsedRepo.name,
        branch: repoBranch,
        path: repoPath === "." ? "" : repoPath,
      },
    };

    try {
      const res = await fetch("/api/rigs", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      const data = await res.json();

      if (!res.ok) {
        if (data.details?.fieldErrors) {
          setFieldErrors(data.details.fieldErrors);
        }
        setError(data.error || "Something went wrong");
        setIsSubmitting(false);
        return;
      }

      // Redirect to the new rig's page
      router.push(`/rigs/${data.slug}`);
    } catch {
      setError("Network error. Please try again.");
      setIsSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="rounded-lg border border-red-500/20 bg-red-500/10 p-4 text-sm text-red-700 dark:text-red-400">
          {error}
        </div>
      )}

      <Card>
        <CardHeader>
          <CardTitle>About Your Rig</CardTitle>
          <CardDescription>
            Give your rig a name and describe what it does.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="name">Name</Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="My Awesome Rig"
              required
            />
            {fieldErrors.name && (
              <p className="text-xs text-red-500">{fieldErrors.name[0]}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="tagline">Tagline</Label>
            <Input
              id="tagline"
              value={tagline}
              onChange={(e) => setTagline(e.target.value)}
              placeholder="A short one-liner about what this rig does"
              required
            />
            {fieldErrors.tagline && (
              <p className="text-xs text-red-500">{fieldErrors.tagline[0]}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="What does this rig do? How does it work?"
              rows={3}
              required
            />
            {fieldErrors.description && (
              <p className="text-xs text-red-500">{fieldErrors.description[0]}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="category">Category</Label>
            <Select value={category} onValueChange={setCategory} required>
              <SelectTrigger id="category">
                <SelectValue placeholder="Select a category" />
              </SelectTrigger>
              <SelectContent>
                {categories.map((c) => (
                  <SelectItem key={c.value} value={c.value}>
                    {c.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {fieldErrors.category && (
              <p className="text-xs text-red-500">{fieldErrors.category[0]}</p>
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>GitHub Repository</CardTitle>
          <CardDescription>
            Where your rig lives. Must contain install.ps1 or install.sh.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="repoInput">Repository</Label>
            <Input
              id="repoInput"
              value={repoInput}
              onChange={(e) => setRepoInput(e.target.value)}
              placeholder="owner/repo or https://github.com/owner/repo"
              required
            />
            {repoError && (
              <p className="text-xs text-red-500">{repoError}</p>
            )}
            {parsedRepo && !repoError && (
              <p className="text-xs text-green-600">
                Found: {parsedRepo.owner}/{parsedRepo.name}
              </p>
            )}
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="repoBranch">Branch</Label>
              {isLoadingBranches ? (
                <div className="flex h-10 items-center gap-2 text-sm text-muted-foreground">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Loading branches...
                </div>
              ) : branches.length > 0 ? (
                <Select value={repoBranch} onValueChange={setRepoBranch} required>
                  <SelectTrigger id="repoBranch">
                    <SelectValue placeholder="Select a branch" />
                  </SelectTrigger>
                  <SelectContent>
                    {branches.map((b) => (
                      <SelectItem key={b} value={b}>
                        {b}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              ) : (
                <Input
                  id="repoBranch"
                  value={repoBranch}
                  onChange={(e) => setRepoBranch(e.target.value)}
                  placeholder="main"
                  disabled={!parsedRepo}
                />
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="repoPath">Path</Label>
              {isLoadingPaths ? (
                <div className="flex h-10 items-center gap-2 text-sm text-muted-foreground">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Scanning for rigs...
                </div>
              ) : paths.length > 0 ? (
                <Select value={repoPath} onValueChange={setRepoPath} required>
                  <SelectTrigger id="repoPath">
                    <SelectValue placeholder="Select rig location" />
                  </SelectTrigger>
                  <SelectContent>
                    {paths.map((p) => (
                      <SelectItem key={p} value={p}>
                        {p === "." ? "(root)" : p}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              ) : (
                <Input
                  id="repoPath"
                  value={repoPath}
                  onChange={(e) => setRepoPath(e.target.value)}
                  placeholder="rigs/my-rig"
                  required
                  disabled={!repoBranch}
                />
              )}
              <p className="text-xs text-muted-foreground">
                {paths.length === 0 && repoBranch && !isLoadingPaths
                  ? "No install scripts found. Enter path manually or check your repo."
                  : "Folder containing install.ps1 or install.sh"}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="flex justify-end gap-4">
        <Button
          type="button"
          variant="outline"
          onClick={() => router.back()}
          disabled={isSubmitting}
        >
          Cancel
        </Button>
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting ? "Submitting..." : "Submit Rig"}
        </Button>
      </div>
    </form>
  );
}
