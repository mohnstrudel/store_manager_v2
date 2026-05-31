import { beforeEach, describe, expect, it, vi } from "vitest";
import AppLayout from "@/layouts/AppLayout";
import { enableInertiaNavigationBridge } from "./inertia";

type CreateInertiaAppOptions = {
  layout: () => typeof AppLayout;
};

const mocks = vi.hoisted(() => ({
  createInertiaApp: vi.fn<(options: CreateInertiaAppOptions) => unknown>(),
  visit: vi.fn<(...args: unknown[]) => unknown>(),
}));

vi.mock("@inertiajs/react", () => ({
  createInertiaApp: mocks.createInertiaApp,
  router: {
    visit: mocks.visit,
  },
}));

vi.mock("@/lib/resolvePage", () => ({
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

  it("leaves React subtree links for Inertia Link to handle", () => {
    enableInertiaNavigationBridge();
    document.body.innerHTML = '<div id="app"><a href="/products">Products</a></div>';

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

function clickEvent() {
  return new MouseEvent("click", {
    bubbles: true,
    button: 0,
    cancelable: true,
  });
}
