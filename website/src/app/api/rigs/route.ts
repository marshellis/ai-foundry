import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";
import { rigs } from "@/lib/db/schema";
import { submitRigSchema, validateGitHubRepo, nameToSlug } from "@/lib/rigs/validation";
import { desc } from "drizzle-orm";

// GET /api/rigs -- list all rigs
export async function GET() {
  try {
    const rows = await db
      .select()
      .from(rigs)
      .orderBy(desc(rigs.createdAt));

    return NextResponse.json(rows);
  } catch (error) {
    console.error("Failed to fetch rigs:", error);
    return NextResponse.json(
      { error: "Failed to fetch rigs" },
      { status: 500 }
    );
  }
}

// POST /api/rigs -- submit a new rig
export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.login) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = submitRigSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Validation failed", details: parsed.error.flatten() },
      { status: 400 }
    );
  }

  const data = parsed.data;
  const branch = data.repository.branch || "main";

  // Validate the GitHub repo has install scripts
  const repoCheck = await validateGitHubRepo(
    data.repository.owner,
    data.repository.name,
    branch,
    data.repository.path
  );

  if (!repoCheck.valid) {
    return NextResponse.json(
      { error: repoCheck.error },
      { status: 422 }
    );
  }

  // Generate slug from name
  const slug = nameToSlug(data.name);

  try {
    const [inserted] = await db
      .insert(rigs)
      .values({
        slug,
        name: data.name,
        tagline: data.tagline,
        description: data.description,
        category: data.category,
        repository: {
          owner: data.repository.owner,
          name: data.repository.name,
          branch,
          path: data.repository.path,
        },
        submittedBy: session.user.login,
        submittedByAvatar: session.user.image ?? null,
      })
      .returning();

    return NextResponse.json(inserted, { status: 201 });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes("unique") || message.includes("duplicate")) {
      return NextResponse.json(
        { error: "A rig with this name already exists" },
        { status: 409 }
      );
    }
    console.error("Failed to insert rig:", error);
    return NextResponse.json(
      { error: "Failed to create rig" },
      { status: 500 }
    );
  }
}
