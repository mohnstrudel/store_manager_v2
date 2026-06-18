import { describe, expect, it } from "vitest";

import { useFlash } from "./useFlash";

describe("useFlash", () => {
  it("returns a safe empty flash payload when none is shared", () => {
    expect(useFlash()).toEqual({ notice: null, alert: null });
  });
});
