import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makePurchase } from "../test/factories";
import type { PurchaseRecord } from "../types";
import PurchasesSection from "./PurchasesSection";

describe("Products/Show/PurchasesSection", () => {
  it("renders nothing without purchases", () => {
    const { container } = renderPurchasesSection([]);

    expect(container).toBeEmptyDOMElement();
  });

  it("totals purchase amounts in the header", () => {
    renderPurchasesSection([
      makePurchase({ id: 1, amount: 2 }),
      makePurchase({ id: 2, amount: 3 }),
    ]);

    expect(screen.getByRole("heading", { name: /5/ })).toBeInTheDocument();
  });

  it("renders supplier, reference, price, amount, and time ago for each purchase", () => {
    renderPurchasesSection();

    expect(screen.getByRole("cell", { name: "GoodSmile" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "GS-1001" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "12.50" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "2 days ago" })).toBeInTheDocument();
  });

  it("joins warehouse names with commas", () => {
    renderPurchasesSection([
      makePurchase({
        warehouses: [
          { id: 1, name: "Tokyo" },
          { id: 2, name: "Osaka" },
        ],
      }),
    ]);

    expect(screen.getByRole("cell", { name: "Tokyo, Osaka" })).toBeInTheDocument();
  });

  it("visits the purchase when the row is clicked", async () => {
    const user = userEvent.setup();
    renderPurchasesSection();

    await user.click(screen.getByRole("row", { name: /GoodSmile/ }));

    expect(router.visit).toHaveBeenCalledWith("/purchases/1");
  });
});

function renderPurchasesSection(purchases: PurchaseRecord[] = [makePurchase()]) {
  return render(<PurchasesSection purchases={purchases} />);
}
