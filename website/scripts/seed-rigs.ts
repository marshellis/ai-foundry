/**
 * Seed script for rigs database
 * 
 * Usage:
 *   npx tsx scripts/seed-rigs.ts
 * 
 * This script inserts or updates the core rigs in the database.
 * Safe to run multiple times - uses upsert logic.
 */

import { neon } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-http";
import { rigs } from "../src/lib/db/schema";
import { eq } from "drizzle-orm";

// Load environment variables
import "dotenv/config";

if (!process.env.DATABASE_URL) {
  console.error("ERROR: DATABASE_URL environment variable is not set");
  console.error("Make sure you have a .env file with DATABASE_URL");
  process.exit(1);
}

const sql = neon(process.env.DATABASE_URL);
const db = drizzle(sql);

// ============================================================================
// SEED DATA - Add new rigs here
// ============================================================================

const seedRigs = [
  {
    slug: "igor",
    name: "Igor",
    tagline: "Incremental AI worker that chips away at large projects",
    description:
      "A GitHub Action that automatically makes incremental progress on large projects by working through tracking issues with task checklists. Create a tracking issue with a checklist, and Igor picks up the next unchecked task each day -- reading context, implementing the change, and opening a PR.",
    category: "ci-cd",
    repository: {
      owner: "marshellis",
      name: "ai-foundry",
      branch: "main",
      path: "rigs/igor",
    },
    submittedBy: "marshellis",
    submittedByAvatar: "https://avatars.githubusercontent.com/u/marshellis",
  },
  {
    slug: "openclaw-droplet",
    name: "OpenClaw on DigitalOcean",
    tagline: "Deploy your personal AI assistant with WhatsApp, Telegram, and Gmail",
    description:
      "A complete setup for OpenClaw on a DigitalOcean droplet. Includes remote installation, swap optimization, and guided setup for WhatsApp (with dedicated number), Telegram bot, and Gmail Pub/Sub integration.",
    category: "automation",
    repository: {
      owner: "marshellis",
      name: "ai-foundry",
      branch: "main",
      path: "rigs/openclaw-droplet",
    },
    submittedBy: "marshellis",
    submittedByAvatar: "https://avatars.githubusercontent.com/u/marshellis",
  },
];

// ============================================================================
// SEED LOGIC
// ============================================================================

async function seed() {
  console.log("Starting rig seed...\n");

  for (const rig of seedRigs) {
    try {
      // Check if rig already exists
      const existing = await db
        .select()
        .from(rigs)
        .where(eq(rigs.slug, rig.slug))
        .limit(1);

      if (existing.length > 0) {
        // Update existing rig
        await db
          .update(rigs)
          .set({
            name: rig.name,
            tagline: rig.tagline,
            description: rig.description,
            category: rig.category,
            repository: rig.repository,
            updatedAt: new Date(),
          })
          .where(eq(rigs.slug, rig.slug));

        console.log(`  Updated: ${rig.name} (${rig.slug})`);
      } else {
        // Insert new rig
        await db.insert(rigs).values({
          slug: rig.slug,
          name: rig.name,
          tagline: rig.tagline,
          description: rig.description,
          category: rig.category,
          repository: rig.repository,
          submittedBy: rig.submittedBy,
          submittedByAvatar: rig.submittedByAvatar,
        });

        console.log(`  Inserted: ${rig.name} (${rig.slug})`);
      }
    } catch (error) {
      console.error(`  ERROR seeding ${rig.slug}:`, error);
    }
  }

  console.log("\nSeed complete!");
}

seed()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Seed failed:", error);
    process.exit(1);
  });
