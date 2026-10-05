import type { ComponentType } from "react";

type PageModule = {
  default: ComponentType;
};

const pages = import.meta.glob<PageModule>(["../pages/**/*.tsx", "!../pages/**/*.test.tsx"]);

export async function resolvePage(name: string) {
  const pageLoader = pages[`../pages/${name}.tsx`];

  if (!pageLoader) {
    throw new Error(`Inertia page not found: ${name}`);
  }

  const page = await pageLoader();

  if (!page) {
    throw new Error(`Inertia page not found: ${name}`);
  }

  return page.default;
}
