import "@/styles/application.css";
import "nprogress/nprogress.css";
import { createInertiaApp, router } from "@inertiajs/react";
import NProgress from "nprogress";
import { createElement } from "react";
import { createRoot } from "react-dom/client";
import AppLayout from "@/layouts/AppLayout";
import { resolvePage } from "@/lib/resolvePage";

NProgress.configure({ showSpinner: false });

const appElement = document.getElementById("app");

const initialPage = appElement?.dataset.page ? JSON.parse(appElement.dataset.page) : undefined;
let inertiaNavigationBridgeEnabled = false;
let autocorrectDisablerEnabled = false;

enableProgressBar();
enableAutocorrectDisabler();
enableInertiaNavigationBridge();

void createInertiaApp({
  defaults: {
    visitOptions: (_href, options) => ({ ...options, viewTransition: true }),
  },
  layout: () => AppLayout,
  page: initialPage,
  resolve: resolvePage,
  setup({ el, App, props }) {
    createRoot(el).render(createElement(App, props));
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

export function enableProgressBar() {
  let timeout: ReturnType<typeof setTimeout> | null = null;

  router.on("start", () => {
    timeout = setTimeout(() => NProgress.start(), 250);
  });

  router.on("progress", (event) => {
    if (NProgress.isStarted() && event.detail.progress?.percentage) {
      NProgress.set((event.detail.progress.percentage / 100) * 0.9);
    }
  });

  router.on("finish", (event) => {
    if (timeout) clearTimeout(timeout);
    if (!NProgress.isStarted()) return;

    if (event.detail.visit.completed) {
      NProgress.done();
    } else if (event.detail.visit.interrupted) {
      NProgress.set(0);
    } else if (event.detail.visit.cancelled) {
      NProgress.done();
      NProgress.remove();
    }
  });
}

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

      const link =
        event.target instanceof Element ? event.target.closest<HTMLAnchorElement>("a[href]") : null;
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
