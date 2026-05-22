import { useEffect, useMemo } from "react";
import { usePage, Link } from "@inertiajs/react";
import type { PageProps } from "@/types/inertia";

const MAX_BREADCRUMBS = 4;
const STORAGE_KEY = "breadcrumb_trail";

type Breadcrumb = {
  name: string;
  url: string;
};

export default function Breadcrumbs() {
  const page = usePage<PageProps>();
  const currentUrl = normalizeUrl(page.url);
  const breadcrumb = page.props.breadcrumb;

  const trail = useMemo(() => createTrail(currentUrl, breadcrumb), [currentUrl, breadcrumb]);

  useEffect(() => {
    saveTrail(trail);
  }, [trail]);

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
        <span className="breadcrumb-separator" aria-hidden="true">
          ↦
        </span>
      ) : null}
      <li
        className={isLast ? "breadcrumb-current" : undefined}
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

function buildTrail(previousTrail: Breadcrumb[], breadcrumb: string, currentUrl: string) {
  let trail = previousTrail.filter((item) => item.url !== currentUrl);

  trail.push({ name: breadcrumb, url: currentUrl });
  trail = trail.slice(-MAX_BREADCRUMBS);

  return trail;
}

function createTrail(currentUrl: string, breadcrumb: string | null) {
  if (!breadcrumb) return [];

  return buildTrail(readTrail(), breadcrumb, currentUrl);
}

function normalizeUrl(url: string) {
  return url.split("?")[0].split("#")[0];
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

function readTrail() {
  if (typeof window === "undefined") return [];

  try {
    const stored = window.sessionStorage.getItem(STORAGE_KEY);
    if (!stored) return [];

    return JSON.parse(stored) as Breadcrumb[];
  } catch {
    return [];
  }
}

function saveTrail(trail: Breadcrumb[]) {
  if (typeof window === "undefined") return;

  window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(trail));
}
