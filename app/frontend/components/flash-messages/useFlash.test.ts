import { describe, expect, it, vi } from "vitest";

vi.mock("@inertiajs/react", () => ({
  usePage: () => ({
    props: {},
  }),
}));

import { useFlash } from "./useFlash";

describe("useFlash", () => {
  it("returns a safe empty flash payload when none is shared", () => {
    expect(useFlash()).toEqual({ notice: null, alert: null });
  });
});
