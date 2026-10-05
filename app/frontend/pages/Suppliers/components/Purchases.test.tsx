import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makeSupplierPurchase } from "../test/factories";
import type { PurchaseRecord } from "../types";
import Purchases from "./Purchases";

describe("Suppliers/components/Purchases", () => {
  it("renders linked purchases", () => {
    renderPurchases();

    expect(screen.getByRole("heading", { name: "Purchases" })).toBeInTheDocument();
    expect(screen.getByText("Pokemon - Pikachu")).toBeInTheDocument();
  });

  it("navigates to the purchase page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderPurchases();
    const purchaseRow = screen.getByText("Pokemon - Pikachu").closest("tr");

    expect(purchaseRow).not.toBeNull();
    await user.click(purchaseRow!);

    expect(router.visit).toHaveBeenCalledWith("/purchases/1");
  });

  it("hides the section when there are no purchases", () => {
    renderPurchases({ purchases: [] });

    expect(screen.queryByRole("heading", { name: "Purchases" })).not.toBeInTheDocument();
  });
});

function renderPurchases({
  purchases = [makeSupplierPurchase()],
}: {
  purchases?: PurchaseRecord[];
} = {}) {
  return render(<Purchases purchases={purchases} />);
}
