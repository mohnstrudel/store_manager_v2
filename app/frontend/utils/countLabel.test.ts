import { describe, expect, it } from "vitest";

import { countLabel } from "./countLabel";

describe("countLabel", () => {
  it.each([
    [0, "0 orders"],
    [1, "1 order"],
    [2, "2 orders"],
  ])("labels %i as %s", (count, label) => {
    expect(countLabel(count, "order")).toBe(label);
  });
});
