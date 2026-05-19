import { createElement, type ComponentType, type ReactNode } from "react";
import AppLayout from "@/layouts/AppLayout";

type PageModule = {
  default: ComponentType;
};

type ComponentWithLayout = ComponentType & {
  layout?: (page: ReactNode) => ReactNode;
};

export function resolvePage(name: string) {
  const pages = import.meta.glob<PageModule>(["../pages/**/*.tsx", "!../pages/**/*.test.tsx"], {
    eager: true,
  });
  const page = pages[`../pages/${name}.tsx`];

  if (!page) {
    throw new Error(`Inertia page not found: ${name}`);
  }

  const component = page.default as ComponentWithLayout;
  if (!component.layout) {
    component.layout = (children: ReactNode) => createElement(AppLayout, null, children);
  }
  return component;
}
