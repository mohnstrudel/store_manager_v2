import { createInertiaApp } from "@inertiajs/react";
import { createElement } from "react";
import { createRoot } from "react-dom/client";

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob("../pages/**/*.tsx", { eager: true });
    return pages[`../pages/${name}.tsx`] as any;
  },
  setup({ el, App, props }) {
    createRoot(el).render(createElement(App, props));
  },
});
