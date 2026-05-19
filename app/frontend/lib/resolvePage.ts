import type { ComponentType } from "react";

type PageModule = {
  default: ComponentType;
};

export function resolvePage(name: string) {
  const pages = import.meta.glob<PageModule>(["../pages/**/*.tsx", "!../pages/**/*.test.tsx"], {
    eager: true,
  });
  const page = pages[`../pages/${name}.tsx`];

  if (!page) {
    throw new Error(`Inertia page not found: ${name}`);
  }

  return page.default;
}
