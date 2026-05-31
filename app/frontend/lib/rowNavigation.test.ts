import { describe, expect, it, vi } from "vitest";
import { rowNavigationProps } from "./rowNavigation";

const mocks = vi.hoisted(() => ({
  prefetch: vi.fn<(...args: unknown[]) => unknown>(),
  visit: vi.fn<(...args: unknown[]) => unknown>(),
}));

vi.mock("@inertiajs/react", () => ({
  router: {
    prefetch: mocks.prefetch,
    visit: mocks.visit,
  },
}));

describe("rowNavigationProps", () => {
  it("prefetches row destinations on hover and focus", () => {
    const props = rowNavigationProps("/products/1");

    props.onMouseEnter();
    props.onFocus();

    expect(mocks.prefetch).toHaveBeenCalledTimes(2);
    expect(mocks.prefetch).toHaveBeenCalledWith("/products/1", { method: "get" });
  });
});
