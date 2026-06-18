import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createInertiaApp, router } from "@inertiajs/react";
import AppLayout from "@/layouts/AppLayout";
import {
  disableAutocorrect,
  enableAutocorrectDisabler,
  enableInertiaNavigationBridge,
} from "./inertia";

vi.mock("@/utils/resolvePage", () => ({
  resolvePage: vi.fn<(...args: unknown[]) => unknown>(),
}));

// Captured at module scope: createInertiaApp and router.on("navigate") run at
// import time of "./inertia", before mockReset clears call history for test 1.
const createInertiaAppOptions = vi.mocked(createInertiaApp).mock.calls[0]?.[0] as
  | { layout: () => typeof AppLayout }
  | undefined;
const navigateHandler = vi
  .mocked(router.on)
  .mock.calls.find(([event]) => event === "navigate")?.[1] as (() => void) | undefined;

describe("Inertia navigation bridge", () => {
  beforeEach(() => {
    document.body.innerHTML = "";
  });

  it("uses AppLayout as the default persistent layout", () => {
    expect(createInertiaAppOptions).toBeDefined();
    expect(createInertiaAppOptions?.layout()).toBe(AppLayout);
  });

  it("visits same-origin layout links through Inertia with view transitions", () => {
    enableInertiaNavigationBridge();
    document.body.innerHTML = '<a href="/products?q=foo#top">Products</a>';

    const event = clickEvent();
    document.querySelector("a")!.dispatchEvent(event);

    expect(router.visit).toHaveBeenCalledWith("/products?q=foo#top", {
      method: "get",
      viewTransition: true,
    });
    expect(event.defaultPrevented).toBe(true);
  });

  it("intercepts plain <a> links inside the React subtree", () => {
    enableInertiaNavigationBridge();
    document.body.innerHTML = '<div id="app"><a href="/products">Products</a></div>';

    const event = clickEvent();
    document.querySelector("a")!.dispatchEvent(event);

    expect(router.visit).toHaveBeenCalledWith("/products", {
      method: "get",
      viewTransition: true,
    });
    expect(event.defaultPrevented).toBe(true);
  });

  it("does not intercept links already handled by React (event.defaultPrevented)", () => {
    enableInertiaNavigationBridge();
    document.body.innerHTML = '<div id="app"><a href="/products">Products</a></div>';

    // Simulate Inertia <Link> calling event.preventDefault() in its onClick
    document.querySelector("a")!.addEventListener("click", (e) => e.preventDefault());
    document.querySelector("a")!.dispatchEvent(clickEvent());

    expect(router.visit).not.toHaveBeenCalled();
  });

  it("does not intercept opted-out links", () => {
    enableInertiaNavigationBridge();
    document.body.innerHTML = '<a data-inertia="false" href="/products">Products</a>';

    document.querySelector("a")!.dispatchEvent(clickEvent());

    expect(router.visit).not.toHaveBeenCalled();
  });
});

describe("autocorrect disabler", () => {
  beforeEach(() => {
    document.body.innerHTML = "";
    vi.useFakeTimers();
    vi.spyOn(window, "requestAnimationFrame").mockImplementation((callback) => {
      return window.setTimeout(callback, 0);
    });
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it("disables browser text helpers for inputs and textareas", () => {
    document.body.innerHTML = "<input><textarea></textarea><select></select>";

    disableAutocorrect();

    expectTextHelpersDisabled(document.querySelector("input"));
    expectTextHelpersDisabled(document.querySelector("textarea"));
    expect(document.querySelector("select")).not.toHaveAttribute("autocomplete");
  });

  it("reruns after Inertia navigations", () => {
    enableAutocorrectDisabler();

    document.body.innerHTML = "<input>";
    navigateHandler?.();
    vi.runOnlyPendingTimers();

    expect(document.querySelector("input")).toHaveAttribute("autocomplete", "off");
  });
});

function clickEvent() {
  return new MouseEvent("click", {
    bubbles: true,
    button: 0,
    cancelable: true,
  });
}

function expectTextHelpersDisabled(element: Element | null) {
  expect(element).toHaveAttribute("autocomplete", "off");
  expect(element).toHaveAttribute("autocorrect", "off");
  expect(element).toHaveAttribute("autocapitalize", "off");
  expect(element).toHaveAttribute("spellcheck", "false");
}
