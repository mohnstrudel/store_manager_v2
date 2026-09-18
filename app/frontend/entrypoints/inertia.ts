import { createInertiaApp, router } from "@inertiajs/react";

import AppLayout from "@/layouts/AppLayout";
import { resolvePage } from "@/utils/resolvePage";

const appElement = document.getElementById("app");

const initialPage = appElement?.dataset.page ? JSON.parse(appElement.dataset.page) : undefined;
let inertiaNavigationBridgeEnabled = false;
let autocorrectDisablerEnabled = false;

enableAutocorrectDisabler();
enableInertiaNavigationBridge();
loadFonts();

void createInertiaApp({
  defaults: {
    visitOptions: (_href, options) => ({ ...options, viewTransition: true }),
  },
  progress: { showSpinner: false, delay: 200 },
  layout: () => AppLayout,
  page: initialPage,
  resolve: resolvePage,
});

export function enableAutocorrectDisabler() {
  if (autocorrectDisablerEnabled) return;

  autocorrectDisablerEnabled = true;
  router.on("navigate", () => disableAutocorrectAfterRender());
}

export function enableInertiaNavigationBridge() {
  if (inertiaNavigationBridgeEnabled) return;

  inertiaNavigationBridgeEnabled = true;

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

function loadFonts() {
  const link = document.createElement("link");
  link.rel = "stylesheet";
  link.href = "/fonts.css";
  document.head.appendChild(link);
}

function disableAutocorrectAfterRender(root: ParentNode = document) {
  requestAnimationFrame(() => disableAutocorrect(root));
}

export function disableAutocorrect(root: ParentNode = document) {
  root.querySelectorAll("input, textarea").forEach((element) => {
    element.setAttribute("autocomplete", "off");
    element.setAttribute("autocorrect", "off");
    element.setAttribute("autocapitalize", "off");
    element.setAttribute("spellcheck", "false");
  });
}
