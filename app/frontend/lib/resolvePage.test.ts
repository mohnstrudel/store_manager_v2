import { describe, expect, it } from "vitest";
import HelloIndex from "../pages/Hello/Index";
import SizesIndex from "../pages/Sizes/Index";
import { resolvePage } from "./resolvePage";

describe("Inertia page resolution", () => {
  it("returns the page component default export", () => {
    expect(resolvePage("Hello/Index")).toBe(HelloIndex);
    expect(resolvePage("Sizes/Index")).toBe(SizesIndex);
  });

  it("raises a clear error for missing pages", () => {
    expect(() => resolvePage("Missing/Index")).toThrow("Inertia page not found: Missing/Index");
  });
});
