import { createInertiaApp, router } from "@inertiajs/react";
import { createElement } from "react";
import { createRoot } from "react-dom/client";
import AppLayout from "@/layouts/AppLayout";
import { resolvePage } from "@/lib/resolvePage";

const appElement = document.getElementById("app");

const initialPage = appElement?.dataset.page ? JSON.parse(appElement.dataset.page) : undefined;
let inertiaNavigationBridgeEnabled = false;

enableInertiaNavigationBridge();

createInertiaApp({
  defaults: {
    visitOptions: (_href, options) => ({ ...options, viewTransition: true }),
  },
  layout: () => AppLayout,
  page: initialPage,
  resolve: resolvePage,
  setup({ el, App, props }) {
    createRoot(el).render(createElement(App, props));
  },
});

export function enableInertiaNavigationBridge() {
  if (inertiaNavigationBridgeEnabled) return;

  inertiaNavigationBridgeEnabled = true;

  document.addEventListener(
    "click",
    (event) => {
      if (
        event.defaultPrevented ||
        event.button !== 0 ||
        event.metaKey ||
        event.ctrlKey ||
        event.shiftKey ||
        event.altKey
      ) {
        return;
      }

      const link = (event.target as Element | null)?.closest<HTMLAnchorElement>("a[href]");
      if (!link || link.target || link.hasAttribute("download") || link.dataset.inertia === "false")
        return;
      if (link.closest("#app")) return;

      const url = new URL(link.href, window.location.href);
      if (url.origin !== window.location.origin) return;

      event.preventDefault();
      router.visit(`${url.pathname}${url.search}${url.hash}`, {
        method: "get",
        viewTransition: true,
      });
    },
    { capture: true },
  );
}
