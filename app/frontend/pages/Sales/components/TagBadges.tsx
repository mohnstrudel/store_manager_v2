import type { ReactNode } from "react";

import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";

type TagBadgesProps = {
  tags: SalesTagRecord[];
};

export default function TagBadges({ tags }: TagBadgesProps) {
  return (
    <ul className="sales_tags">
      {tags.map((tag) => (
        <li key={tag.id}>
          <TagBadge color={tag.color}>{tag.name}</TagBadge>
        </li>
      ))}
    </ul>
  );
}

type TagBadgeProps = {
  children: ReactNode;
  color: SalesTagColor;
};

export function TagBadge({ children, color }: TagBadgeProps) {
  return (
    <span className="sales_tag" data-color={color}>
      {children}
    </span>
  );
}
