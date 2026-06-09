import { Link } from "@inertiajs/react";
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
          ↦
        </span>
      ) : null}
      <li
        className={isLast ? "breadcrumb_current" : undefined}
        style={breadcrumbOpacityStyle(index, total)}
      >
        {isLast ? (
          <BreadcrumbLabel name={item.name} />
        ) : (
          <Link href={item.url} prefetch>
            <BreadcrumbLabel name={item.name} />
          </Link>
        )}
      </li>
    </>
  );
}

function BreadcrumbLabel({ name }: { name: string }) {
  const { icon, label } = splitBreadcrumbIcon(name);

  return (
    <>
      {icon ? (
        <i aria-hidden="true" className="icn mr-2">
          {icon}
        </i>
      ) : null}
      <span>{label}</span>
    </>
  );
}

function breadcrumbOpacityStyle(index: number, total: number) {
  if (index === total - 1) return undefined;

  const positionFromEnd = total - 1 - index;
  const opacity = Math.max(0.4, 1 - positionFromEnd * 0.2);

  return { opacity };
}

function splitBreadcrumbIcon(name: string) {
  const [firstCharacter, ...rest] = Array.from(name);
  if (!firstCharacter || !isEmoji(firstCharacter)) {
    return { icon: null, label: name };
  }

  return { icon: firstCharacter, label: rest.join("").trimStart() };
}

function isEmoji(character: string) {
  return /\p{Extended_Pictographic}/u.test(character);
}
