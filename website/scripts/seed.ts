import { neon } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-http";
import { pgTable, serial, text, timestamp, jsonb } from "drizzle-orm/pg-core";

// Schema definition (duplicated here for standalone script)
const rigs = pgTable("rigs", {
  id: serial("id").primaryKey(),
  slug: text("slug").notNull().unique(),
  name: text("name").notNull(),
  tagline: text("tagline").notNull(),
  description: text("description").notNull(),
  category: text("category").notNull(),
  repository: jsonb("repository")
    .$type<{ owner: string; name: string; branch: string; path: string }>()
    .notNull(),
  submittedBy: text("submitted_by").notNull(),
  submittedByAvatar: text("submitted_by_avatar"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

async function main() {
  const sql = neon(process.env.DATABASE_URL!);
  const db = drizzle(sql);

  // Drop old table and create new one
  console.log("Dropping old tables...");
  await sql`DROP TABLE IF EXISTS community_rigs`;
  await sql`DROP TABLE IF EXISTS rigs`;

  console.log("Creating rigs table...");
  await sql`
    CREATE TABLE rigs (
      id SERIAL PRIMARY KEY,
      slug TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      tagline TEXT NOT NULL,
      description TEXT NOT NULL,
      category TEXT NOT NULL,
      repository JSONB NOT NULL,
      submitted_by TEXT NOT NULL,
      submitted_by_avatar TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `;

  console.log("Seeding Igor rig...");
  await db.insert(rigs).values({
    slug: "igor",
    name: "Igor",
    tagline: "Incremental AI worker that chips away at large projects",
    description: `A GitHub Action that automatically makes incremental progress on large projects by working through tracking issues with task checklists.

Create a tracking issue with a checklist, and Igor picks up the next unchecked task each day -- reading context, implementing the change, and opening a PR.

Once installed, Igor monitors your GitHub repository for issues labeled 'claude-incremental'. Each issue should contain a checklist of tasks. Every day at 2 AM UTC (or when triggered manually), Igor picks the next unchecked task, reads your codebase for context, implements the change on a new branch, opens a pull request, and checks off the task. You review and merge the PR like any other contribution.`,
    category: "ci-cd",
    repository: {
      owner: "marshellis",
      name: "ai-foundry",
      branch: "main",
      path: "rigs/igor",
    },
    submittedBy: "jjackson",
    submittedByAvatar: "https://avatars.githubusercontent.com/u/70459?v=4",
  });

  console.log("Done!");
}

main().catch(console.error);
