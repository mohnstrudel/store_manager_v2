import { createInertiaApp } from "@inertiajs/react";
import { createElement } from "react";
import { createRoot } from "react-dom/client";
import { resolvePage } from "@/lib/resolvePage";

const appElement = document.getElementById("app");
const initialPage = appElement?.dataset.page ? JSON.parse(appElement.dataset.page) : undefined;

createInertiaApp({
  page: initialPage,
  resolve: resolvePage,
  setup({ el, App, props }) {
    createRoot(el).render(createElement(App, props));
  },
});
