import { describe, expect, it } from "vitest";
import DashboardIndex from "../pages/Dashboard/Index";
import SizesIndex from "../pages/Sizes/Index";
import { resolvePage } from "./resolvePage";

describe("Inertia page resolution", () => {
  it("returns the page component default export", async () => {
    await expect(resolvePage("Dashboard/Index")).resolves.toBe(DashboardIndex);
    await expect(resolvePage("Sizes/Index")).resolves.toBe(SizesIndex);
  });

  it("raises a clear error for missing pages", async () => {
    await expect(resolvePage("Missing/Index")).rejects.toThrow(
      "Inertia page not found: Missing/Index",
    );
  });
});
