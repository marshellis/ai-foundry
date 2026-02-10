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

const categoryLabels: Record<string, string> = {
  "ci-cd": "CI/CD",
  coding: "Coding",
  personal: "Personal",
  automation: "Automation",
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
            <Badge variant="secondary">
              {categoryLabels[rig.category] ?? rig.category}
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
        <CardFooter className="flex items-center gap-2 text-xs text-muted-foreground">
          {rig.submittedByAvatar && (
            <img
              src={rig.submittedByAvatar}
              alt={rig.submittedBy}
              className="h-5 w-5 rounded-full"
            />
          )}
          <span>by {rig.submittedBy}</span>
        </CardFooter>
      </Card>
    </Link>
  );
}
