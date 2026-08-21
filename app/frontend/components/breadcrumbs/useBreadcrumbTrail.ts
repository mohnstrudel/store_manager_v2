import { usePage } from "@inertiajs/react";
import { useEffect, useState } from "react";

import type { PageProps } from "@/types/inertia";

const MAX_BREADCRUMBS = 4;
const STORAGE_KEY = "breadcrumb_trail";

type Breadcrumb = {
  name: string;
  url: string;
};

export function useBreadcrumbTrail() {
  const page = usePage<PageProps>();
  const currentUrl = normalizeUrl(page.url);
  const breadcrumb = page.props.breadcrumb;

  // Initial state matches SSR output: just the current page (no sessionStorage on server).
  const [trail, setTrail] = useState<Breadcrumb[]>(() =>
    breadcrumb ? [{ name: breadcrumb, url: currentUrl }] : [],
  );

  useEffect(
    function syncTrail() {
      if (!breadcrumb) {
        setTrail([]);
        return;
      }
      const fullTrail = buildTrail(readTrail(), breadcrumb, currentUrl);
      setTrail(fullTrail);
      saveTrail(fullTrail);
    },
    [currentUrl, breadcrumb],
  );

  return trail;
}

function buildTrail(previousTrail: Breadcrumb[], breadcrumb: string, currentUrl: string) {
  let trail = previousTrail.filter((item) => item.url !== currentUrl);

  trail.push({ name: breadcrumb, url: currentUrl });
  trail = trail.slice(-MAX_BREADCRUMBS);

  return trail;
}

function normalizeUrl(url: string) {
  return url.split("?")[0].split("#")[0];
}

function readTrail() {
  if (typeof window === "undefined") return [];

  try {
    const stored = window.sessionStorage.getItem(STORAGE_KEY);
    if (!stored) return [];

    const parsed: unknown = JSON.parse(stored);
    return isBreadcrumbTrail(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function saveTrail(trail: Breadcrumb[]) {
  if (typeof window === "undefined") return;

  window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(trail));
}

function isBreadcrumbTrail(value: unknown): value is Breadcrumb[] {
  return Array.isArray(value) && value.every(isBreadcrumb);
}

function isBreadcrumb(value: unknown): value is Breadcrumb {
  return (
    typeof value === "object" &&
    value !== null &&
    "name" in value &&
    "url" in value &&
    typeof (value as { name?: unknown }).name === "string" &&
    typeof (value as { url?: unknown }).url === "string"
  );
}
