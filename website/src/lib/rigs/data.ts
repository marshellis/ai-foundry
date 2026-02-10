import { db } from "@/lib/db";
import { rigs } from "@/lib/db/schema";
import { eq, desc } from "drizzle-orm";
import type { Rig } from "./types";

/**
 * Fetch all rigs from the database.
 */
export async function getAllRigs(): Promise<Rig[]> {
  const rows = await db
    .select()
    .from(rigs)
    .orderBy(desc(rigs.createdAt));

  return rows.map((row) => ({
    ...row,
    category: row.category as Rig["category"],
    repository: row.repository as Rig["repository"],
  }));
}

/**
 * Fetch a single rig by slug.
 */
export async function getRigBySlug(slug: string): Promise<Rig | null> {
  const [row] = await db
    .select()
    .from(rigs)
    .where(eq(rigs.slug, slug))
    .limit(1);

  if (!row) return null;

  return {
    ...row,
    category: row.category as Rig["category"],
    repository: row.repository as Rig["repository"],
  };
}
