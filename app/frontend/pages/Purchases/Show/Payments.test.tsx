import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import Payments from "./Payments";
import type { NewPaymentRecord, PaymentRecord, PurchaseShowRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

afterEach(() => {
  vi.restoreAllMocks();
});

describe("Purchases/Show/Payments", () => {
  it("shows the empty state when there are no payments", () => {
    render(<Payments newPayment={makeNewPayment()} payments={[]} purchase={makePurchase()} />);

    expect(screen.getByText("No payments yet.")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Add payment" })).toBeInTheDocument();
  });

  it("creates a payment from the new payment row", async () => {
    const user = userEvent.setup();

    render(<Payments newPayment={makeNewPayment()} payments={[]} purchase={makePurchase()} />);

    await user.clear(screen.getByLabelText("Amount"));
    await user.type(screen.getByLabelText("Amount"), "12");
    await user.click(screen.getByRole("button", { name: "Add payment" }));

    expect(router.post).toHaveBeenCalledWith("/purchases/55/payments", {
      payment: {
        payment_date: "2026-05-21",
        value: "12",
      },
      return_to: "/purchases/55",
    });
  });

  it("updates an existing payment row", async () => {
    const user = userEvent.setup();

    render(
      <Payments
        newPayment={makeNewPayment()}
        payments={[makePayment()]}
        purchase={makePurchase()}
      />,
    );

    fireEvent.change(screen.getAllByLabelText("Date")[0], {
      target: { value: "2026-05-22" },
    });
    await user.clear(screen.getAllByLabelText("Amount")[0]);
    await user.type(screen.getAllByLabelText("Amount")[0], "15");
    await user.click(screen.getByRole("button", { name: "Update" }));

    expect(router.patch).toHaveBeenCalledWith("/purchases/55/payments/1", {
      payment: {
        payment_date: "2026-05-22",
        value: "15",
      },
      return_to: "/purchases/55",
    });
  });

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
    expect(router.delete).toHaveBeenCalledWith("/purchases/55/payments/1");
  });

  it("renders validation errors for both the existing and new payment rows", () => {
    render(
      <Payments
        newPayment={makeNewPayment({ errors: ["Could not add payment"] })}
        payments={[makePayment({ errors: ["Could not save payment"] })]}
        purchase={makePurchase()}
      />,
    );

    expect(screen.getByText("Could not save payment")).toBeInTheDocument();
    expect(screen.getByText("Could not add payment")).toBeInTheDocument();
  });
});

function makePurchase(overrides: Partial<PurchaseShowRecord> = {}): PurchaseShowRecord {
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
    ...overrides,
  };
}

function makePayment(overrides: Partial<PaymentRecord> = {}): PaymentRecord {
  return {
    destroy_path: "/purchases/55/payments/1",
    errors: [],
    id: 1,
    payment_date: "2026-05-20",
    update_path: "/purchases/55/payments/1",
    value: "10.00",
    ...overrides,
  };
}

function makeNewPayment(overrides: Partial<NewPaymentRecord> = {}): NewPaymentRecord {
  return {
    create_path: "/purchases/55/payments",
    errors: [],
    payment_date: "2026-05-21",
    value: "10.00",
    ...overrides,
  };
}
