import Link from "next/link";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import type { Rig } from "@/lib/rigs/types";

const statusColors: Record<string, string> = {
  ready: "bg-green-500/10 text-green-700 dark:text-green-400 border-green-500/20",
  beta: "bg-yellow-500/10 text-yellow-700 dark:text-yellow-400 border-yellow-500/20",
  "coming-soon":
    "bg-muted text-muted-foreground border-muted",
};

const difficultyLabels: Record<string, string> = {
  beginner: "Beginner",
  intermediate: "Intermediate",
  advanced: "Advanced",
};

interface RigCardProps {
  rig: Rig;
}

export function RigCard({ rig }: RigCardProps) {
  return (
    <Link href={`/rigs/${rig.slug}`} className="group block">
      <Card className="h-full transition-all duration-200 hover:shadow-lg hover:border-foreground/20 group-hover:-translate-y-0.5">
        <CardHeader>
          <div className="flex items-start justify-between gap-2">
            <CardTitle className="text-xl">{rig.name}</CardTitle>
            <Badge
              variant="outline"
              className={statusColors[rig.status] ?? ""}
            >
              {rig.status === "coming-soon" ? "Coming Soon" : rig.status}
            </Badge>
          </div>
          <CardDescription className="text-base">
            {rig.tagline}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground line-clamp-3">
            {rig.description}
          </p>
        </CardContent>
        <CardFooter className="flex flex-wrap gap-2">
          <Badge variant="secondary">{difficultyLabels[rig.difficulty]}</Badge>
          {rig.tags.slice(0, 3).map((tag) => (
            <Badge key={tag} variant="outline" className="text-xs">
              {tag}
            </Badge>
          ))}
        </CardFooter>
      </Card>
    </Link>
  );
}
