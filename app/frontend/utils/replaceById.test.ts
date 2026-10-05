import { describe, expect, it } from "vitest";

import { replaceById } from "./replaceById";

describe("replaceById", () => {
  it("replaces the item matching the id", () => {
    const items = [
      { id: 1, name: "alpha" },
      { id: 2, name: "beta" },
    ];

    const result = replaceById(items, 1, { name: "updated" });

    expect(result[0]).toEqual({ id: 1, name: "updated" });
    expect(result[1]).toEqual({ id: 2, name: "beta" });
  });

  it("leaves unmatched items unchanged", () => {
    const items = [{ id: 1, name: "alpha" }];

    const result = replaceById(items, 99, { name: "nope" });

    expect(result).toEqual([{ id: 1, name: "alpha" }]);
  });

  it("returns a new array", () => {
    const items = [{ id: 1, name: "alpha" }];

    const result = replaceById(items, 1, { name: "updated" });

    expect(result).not.toBe(items);
  });
});
