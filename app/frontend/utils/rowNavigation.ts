import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";

type VisitOptions = Parameters<typeof router.visit>[1];

export function stopRowNavigation(event: { stopPropagation(): void }) {
  event.stopPropagation();
}

export function rowNavigationProps(path: string, visitOptions?: VisitOptions) {
  return {
    tabIndex: 0 as const,
    onFocus() {
      prefetch(path);
    },
    onMouseEnter() {
      prefetch(path);
    },
    onClick(e: MouseEvent<HTMLTableRowElement>) {
      if (e.metaKey || e.ctrlKey) {
        openTab(path);
      } else {
        visit(path, visitOptions);
      }
    },
    onAuxClick(e: MouseEvent<HTMLTableRowElement>) {
      if (e.button === 1) openTab(path);
    },
    onKeyDown(e: KeyboardEvent<HTMLTableRowElement>) {
      if (e.key !== "Enter" && e.key !== " ") return;
      e.preventDefault();
      if (e.metaKey || e.ctrlKey) {
        openTab(path);
      } else {
        visit(path, visitOptions);
      }
    },
  };
}

function visit(path: string, visitOptions?: VisitOptions) {
  if (visitOptions) {
    router.visit(path, visitOptions);
  } else {
    router.visit(path);
  }
}

function openTab(path: string) {
  window.open(path, "_blank", "noopener,noreferrer");
}

function prefetch(path: string) {
  router.prefetch(path, { method: "get" });
}
