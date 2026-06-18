import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import Show from "./Show";
import { makeNewPayment, makePayment, makePurchaseItem, makePurchaseShow, makeShippingCompanyOption, makeWarehouseOption } from "./test/factories";

import type { NewPaymentRecord, PaymentRecord, PurchaseItemRecord, PurchaseShowRecord, ShippingCompanyOption, WarehouseOption } from "./types";


vi.mock("./Show/PurchaseItems", () => ({
  default: ({
    movePath,
    purchaseItems,
    shippingCompanies,
    warehouses,
  }: {
    movePath: string;
    purchaseItems: PurchaseItemRecord[];
    shippingCompanies: ShippingCompanyOption[];
    warehouses: WarehouseOption[];
  }) => (
    <section data-testid="purchase-items">
      Items: {purchaseItems.length}, warehouses: {warehouses.length}, shipping_companies:{" "}
      {shippingCompanies.length}, move: {movePath}
    </section>
  ),
}));

vi.mock("./Show/Details", () => ({
  default: ({ purchase }: { purchase: PurchaseShowRecord }) => (
    <section data-testid="purchase-details">Details for {purchase.product_title}</section>
  ),
}));

vi.mock("./Show/Payments", () => ({
  default: ({
    newPayment,
    payments,
  }: {
    newPayment: NewPaymentRecord;
    payments: PaymentRecord[];
  }) => (
    <section data-testid="payments">
      Payments: {payments.length}, new: {newPayment.value}
    </section>
  ),
}));

describe("Purchases/Show", () => {
  it("renders the purchase header, edit action, and page sections", () => {
        render(<Show new_payment={makeNewPayment()} payments={[makePayment()]} purchase={makePurchaseShow()} purchase_items={[makePurchaseItem()]} shipping_companies={[makeShippingCompanyOption({ id: 1, name: "Fast Ship" })]} warehouse_move_path={"/purchase_items/move"} warehouses={[makeWarehouseOption()]}/>);

    expect(screen.getByRole("heading", { name: /Purchase 55/ })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/purchases/55/edit",
    );
    expect(screen.getByTestId("purchase-items")).toHaveTextContent(
      "Items: 1, warehouses: 1, shipping_companies: 1, move: /purchase_items/move",
    );
    expect(screen.getByTestId("purchase-details")).toHaveTextContent("Details for Pikachu Figure");
    expect(screen.getByTestId("payments")).toHaveTextContent("Payments: 1, new: 10.00");
  });

  it("destroys the purchase after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
        render(<Show new_payment={makeNewPayment()} payments={[makePayment()]} purchase={makePurchaseShow()} purchase_items={[makePurchaseItem()]} shipping_companies={[makeShippingCompanyOption({ id: 1, name: "Fast Ship" })]} warehouse_move_path={"/purchase_items/move"} warehouses={[makeWarehouseOption()]}/>);

    await user.click(screen.getByRole("button", { name: "Destroy this purchase" }));

    expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
    expect(router.delete).toHaveBeenCalledWith("/purchases/55");
  });
});


