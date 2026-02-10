import {
  pgTable,
  serial,
  text,
  timestamp,
  jsonb,
} from "drizzle-orm/pg-core";

export const rigs = pgTable("rigs", {
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

export type Rig = typeof rigs.$inferSelect;
export type NewRig = typeof rigs.$inferInsert;
