import { Link } from "@inertiajs/react";
import { ChevronRightIcon } from "lucide-react";

import { useBreadcrumbTrail } from "./useBreadcrumbTrail";

type Breadcrumb = {
  name: string;
  url: string;
};

export default function Breadcrumbs() {
  const trail = useBreadcrumbTrail();

  if (trail.length === 0) return null;

  return (
    <nav className="hidden min-h-5 mb-4 lg:block" aria-label="Breadcrumb">
      <ol className="breadcrumbs">
        {trail.map((item, index) => (
          <BreadcrumbItem
            key={`${item.url}-${item.name}`}
            item={item}
            index={index}
            total={trail.length}
          />
        ))}
      </ol>
    </nav>
  );
}

function BreadcrumbItem({
  index,
  item,
  total,
}: {
  index: number;
  item: Breadcrumb;
  total: number;
}) {
  const isLast = index === total - 1;

  return (
    <>
      {index > 0 ? (
        <span className="breadcrumb_separator" aria-hidden="true">
          <ChevronRightIcon />
        </span>
      ) : null}
      <li
        className={isLast ? "breadcrumb_current" : undefined}
        style={breadcrumbOpacityStyle(index, total)}
      >
        {isLast ? (
          <span>{item.name}</span>
        ) : (
          <Link href={item.url} prefetch>
            <span>{item.name}</span>
          </Link>
        )}
      </li>
    </>
  );
}

function breadcrumbOpacityStyle(index: number, total: number) {
  if (index === total - 1) return undefined;

  const positionFromEnd = total - 1 - index;
  const opacity = Math.max(0.4, 1 - positionFromEnd * 0.2);

  return { opacity };
}
