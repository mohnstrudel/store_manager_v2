import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import Payments from "../Show/Payments";
import type { NewPaymentRecord, PaymentRecord, PurchaseShowRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Purchases/components/Payments", () => {
  it("removes a payment after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);

    render(
      <Payments
        newPayment={makeNewPayment()}
        payments={[makePayment()]}
        purchase={makePurchase()}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Remove" }));

    expect(window.confirm).toHaveBeenCalledWith("Remove this payment?");
    expect(router.delete).toHaveBeenCalledWith("/payments/1");
  });
});

function makePurchase(): PurchaseShowRecord {
  return {
    amount: 2,
    cost_total: "210.00",
    date: "20 May 2026",
    debt: "160.00",
    destroy_path: "/purchases/55",
    edit_path: "/purchases/55/edit",
    id: 55,
    item_price: "100.00",
    order_reference: "PO-55",
    paid: "50.00",
    path: "/purchases/55",
    payment_progress: {
      debt: "160.00",
      paid: "50.00",
      price: "210.00",
      progress: 25,
    },
    product_image_url: null,
    product_path: "/products/1",
    product_thumb_url: null,
    product_title: "Pikachu Figure",
    shipping_total: "10.00",
    supplier_path: "/suppliers/1",
    supplier_title: "Acme Imports",
    variant_title: "Default",
  };
}

function makePayment(): PaymentRecord {
  return {
    destroy_path: "/payments/1",
    errors: [],
    id: 1,
    payment_date: "20 May 2026",
    update_path: "/payments/1",
    value: "10.00",
  };
}

function makeNewPayment(): NewPaymentRecord {
  return {
    create_path: "/payments",
    errors: [],
    payment_date: "20 May 2026",
    value: "10.00",
  };
}
