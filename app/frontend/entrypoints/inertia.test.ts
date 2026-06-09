import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import AppLayout from "@/layouts/AppLayout";
import {
  disableAutocorrect,
  enableAutocorrectDisabler,
  enableInertiaNavigationBridge,
} from "./inertia";

type CreateInertiaAppOptions = {
  layout: () => typeof AppLayout;
};

const mocks = vi.hoisted(() => ({
  createInertiaApp: vi.fn<(options: CreateInertiaAppOptions) => unknown>(),
  on: vi.fn<(event: string, callback: () => void) => () => void>(),
  visit: vi.fn<(...args: unknown[]) => unknown>(),
}));

vi.mock("@inertiajs/react", () => ({
  createInertiaApp: mocks.createInertiaApp,
  router: {
    on: mocks.on,
    visit: mocks.visit,
  },
}));

vi.mock("@/utils/resolvePage", () => ({
  resolvePage: vi.fn<(...args: unknown[]) => unknown>(),
}));

describe("Inertia navigation bridge", () => {
  beforeEach(() => {
    document.body.innerHTML = "";
    mocks.visit.mockClear();
  });

  it("uses AppLayout as the default persistent layout", () => {
    expect(mocks.createInertiaApp).toHaveBeenCalled();

    const options = mocks.createInertiaApp.mock.calls[0][0];
    expect(options.layout()).toBe(AppLayout);
  });

  it("visits same-origin layout links through Inertia with view transitions", () => {
    enableInertiaNavigationBridge();
    document.body.innerHTML = '<a href="/products?q=foo#top">Products</a>';

    const event = clickEvent();
    document.querySelector("a")!.dispatchEvent(event);

    expect(mocks.visit).toHaveBeenCalledWith("/products?q=foo#top", {
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

    expect(mocks.visit).toHaveBeenCalledWith("/products", {
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

    expect(mocks.visit).not.toHaveBeenCalled();
  });

  it("does not intercept opted-out links", () => {
    enableInertiaNavigationBridge();
    document.body.innerHTML = '<a data-inertia="false" href="/products">Products</a>';

    document.querySelector("a")!.dispatchEvent(clickEvent());

    expect(mocks.visit).not.toHaveBeenCalled();
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

    const navigateHandler = findNavigateHandler();
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

function findNavigateHandler() {
  return mocks.on.mock.calls.find(([event]) => event === "navigate")?.[1];
}
