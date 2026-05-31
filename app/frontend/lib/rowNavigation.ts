import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";

function openTab(path: string) {
  window.open(path, "_blank", "noopener,noreferrer");
}

function prefetch(path: string) {
  router.prefetch(path, { method: "get" });
}

export function stopRowNavigation(event: { stopPropagation(): void }) {
  event.stopPropagation();
}

export function rowNavigationProps(path: string) {
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
        router.visit(path);
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
        router.visit(path);
      }
    },
  };
}
