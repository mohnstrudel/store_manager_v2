import { describe, expect, it } from "vitest";

import { browserTitle } from "./useDocumentTitle";

describe("browserTitle", () => {
  it("prefixes the shared breadcrumb with the deployment tag", () => {
    expect(browserTitle("Products/Show", "Pikachu", "staging")).toBe("[STG] Pikachu — Store Mate");
  });

  it("gives pages without a breadcrumb a readable title", () => {
    expect(browserTitle("PurchaseItems/Edit", null, "production")).toBe(
      "[PRD] Edit Purchase Item — Store Mate",
    );
  });

  it("uses the task-oriented authentication titles", () => {
    expect(browserTitle("Sessions/New", "New Session", "development")).toBe(
      "[DEV] Sign in — Store Mate",
    );
  });
});
