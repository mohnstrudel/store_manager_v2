import { describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import { rowNavigationProps } from "./rowNavigation";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("rowNavigationProps", () => {
  it("prefetches row destinations on hover and focus", () => {
    const props = rowNavigationProps("/products/1");

    props.onMouseEnter();
    props.onFocus();

    expect(router.prefetch).toHaveBeenCalledTimes(2);
    expect(router.prefetch).toHaveBeenCalledWith("/products/1", {
      method: "get",
    });
  });
});
