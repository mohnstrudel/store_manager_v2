import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import PurchaseItems from "./PurchaseItems";
import { makeShippingCompanyPurchaseItem } from "../test/factories";
import type { PurchaseItemRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("ShippingCompanies/components/PurchaseItems", () => {
  it("renders linked purchase items", () => {
    renderPurchaseItems();

    expect(screen.getByRole("heading", { name: "Purchase Items" })).toBeInTheDocument();
    expect(screen.getByText("Pokemon - Pikachu")).toBeInTheDocument();
    expect(screen.getByText("TRACK123")).toBeInTheDocument();
  });

  it("navigates to the purchase item page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderPurchaseItems();
    const row = screen.getByText("Pokemon - Pikachu").closest("tr");

    expect(row).not.toBeNull();
    await user.click(row!);

    expect(router.visit).toHaveBeenCalledWith("/purchase_items/1");
  });

  it("hides the section when there are no purchase items", () => {
    renderPurchaseItems({ purchaseItems: [] });

    expect(screen.queryByRole("heading", { name: "Purchase Items" })).not.toBeInTheDocument();
  });
});

function renderPurchaseItems({
  purchaseItems = [makeShippingCompanyPurchaseItem()],
}: {
  purchaseItems?: PurchaseItemRecord[];
} = {}) {
  return render(<PurchaseItems purchaseItems={purchaseItems} />);
}
