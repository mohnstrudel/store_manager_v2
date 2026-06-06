import { createInertiaApp, router } from "@inertiajs/react";
import { createElement } from "react";
import { hydrateRoot } from "react-dom/client";
import AppLayout from "@/layouts/AppLayout";
import { resolvePage } from "@/lib/resolvePage";

const appElement = document.getElementById("app");

const initialPage = appElement?.dataset.page ? JSON.parse(appElement.dataset.page) : undefined;
let inertiaNavigationBridgeEnabled = false;
let autocorrectDisablerEnabled = false;

enableAutocorrectDisabler();
enableInertiaNavigationBridge();

void createInertiaApp({
  defaults: {
    visitOptions: (_href, options) => ({ ...options, viewTransition: true }),
  },
  progress: { showSpinner: false, delay: 200 },
  layout: () => AppLayout,
  page: initialPage,
  resolve: resolvePage,
  setup({ el, App, props }) {
    hydrateRoot(el, createElement(App, props));
    disableAutocorrectAfterRender(el);
  },
});

export function disableAutocorrect(root: ParentNode = document) {
  root.querySelectorAll("input, textarea").forEach((element) => {
    element.setAttribute("autocomplete", "off");
    element.setAttribute("autocorrect", "off");
    element.setAttribute("autocapitalize", "off");
    element.setAttribute("spellcheck", "false");
  });
}

export function enableAutocorrectDisabler() {
  if (autocorrectDisablerEnabled) return;

  autocorrectDisablerEnabled = true;
  router.on("navigate", () => disableAutocorrectAfterRender());
}

function disableAutocorrectAfterRender(root: ParentNode = document) {
  requestAnimationFrame(() => disableAutocorrect(root));
}

export function enableInertiaNavigationBridge() {
  if (inertiaNavigationBridgeEnabled) return;

  inertiaNavigationBridgeEnabled = true;

  // Bubbling phase runs after React's synthetic event handlers, so Inertia <Link>
  // components that call event.preventDefault() are already handled and skipped
  // via the defaultPrevented guard. Plain <a href> tags inside the app (which have
  // no React onClick) reach this handler and get routed through Inertia instead of
  // triggering a full page reload.
  document.addEventListener("click", (event) => {
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

    const link =
      event.target instanceof Element ? event.target.closest<HTMLAnchorElement>("a[href]") : null;
    if (!link || link.target || link.hasAttribute("download") || link.dataset.inertia === "false")
      return;

    const url = new URL(link.href, window.location.href);
    if (url.origin !== window.location.origin) return;

    event.preventDefault();
    router.visit(`${url.pathname}${url.search}${url.hash}`, {
      method: "get",
      viewTransition: true,
    });
  });
}
