import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";
import { rigs } from "@/lib/db/schema";
import { eq } from "drizzle-orm";

// GET /api/rigs/[slug] -- get a single rig
export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params;

  try {
    const [rig] = await db
      .select()
      .from(rigs)
      .where(eq(rigs.slug, slug))
      .limit(1);

    if (!rig) {
      return NextResponse.json({ error: "Rig not found" }, { status: 404 });
    }

    return NextResponse.json(rig);
  } catch (error) {
    console.error("Failed to fetch rig:", error);
    return NextResponse.json(
      { error: "Failed to fetch rig" },
      { status: 500 }
    );
  }
}

// DELETE /api/rigs/[slug] -- delete own rig
export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ slug: string }> }
) {
  const session = await auth();
  if (!session?.user?.login) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const { slug } = await params;

  try {
    const [rig] = await db
      .select()
      .from(rigs)
      .where(eq(rigs.slug, slug))
      .limit(1);

    if (!rig) {
      return NextResponse.json({ error: "Rig not found" }, { status: 404 });
    }

    if (rig.submittedBy !== session.user.login) {
      return NextResponse.json(
        { error: "You can only delete your own rigs" },
        { status: 403 }
      );
    }

    await db.delete(rigs).where(eq(rigs.slug, slug));

    return NextResponse.json({ deleted: true });
  } catch (error) {
    console.error("Failed to delete rig:", error);
    return NextResponse.json(
      { error: "Failed to delete rig" },
      { status: 500 }
    );
  }
}
