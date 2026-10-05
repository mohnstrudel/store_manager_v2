import { router } from "@inertiajs/react";
import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import { nextFormErrors } from "@/test/mocks/inertia";

import { makeNewPayment, makePayment, makePurchaseShow } from "../test/factories";
import Payments from "./Payments";

afterEach(() => {
  vi.restoreAllMocks();
});

describe("Purchases/Show/Payments", () => {
  it("shows the empty state when there are no payments", () => {
    render(<Payments newPayment={makeNewPayment()} payments={[]} purchase={makePurchaseShow()} />);

    expect(screen.getByText("No payments yet.")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Add payment" })).toBeInTheDocument();
  });

  it("creates a payment from the new payment row", async () => {
    const user = userEvent.setup();

    render(<Payments newPayment={makeNewPayment()} payments={[]} purchase={makePurchaseShow()} />);

    await user.clear(screen.getByLabelText("Amount"));
    await user.type(screen.getByLabelText("Amount"), "12");
    await user.click(screen.getByRole("button", { name: "Add payment" }));

    expect(router.post).toHaveBeenCalledWith(
      "/purchases/55/payments",
      {
        payment: {
          payment_date: "2026-05-21",
          value: "12",
        },
        return_to: "/purchases/55",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
    expect(screen.getByLabelText("Amount")).toHaveValue(10);
  });

  it("updates an existing payment row", async () => {
    const user = userEvent.setup();

    render(
      <Payments
        newPayment={makeNewPayment()}
        payments={[makePayment()]}
        purchase={makePurchaseShow()}
      />,
    );

    fireEvent.change(screen.getAllByLabelText("Date")[0], {
      target: { value: "2026-05-22" },
    });
    await user.clear(screen.getAllByLabelText("Amount")[0]);
    await user.type(screen.getAllByLabelText("Amount")[0], "15");
    await user.click(screen.getByRole("button", { name: "Update" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/purchases/55/payments/1",
      {
        payment: {
          payment_date: "2026-05-22",
          value: "15",
        },
        return_to: "/purchases/55",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
    expect(screen.getAllByLabelText("Amount")[0]).toHaveValue(15);
  });

  it("uses the direct-expense action colors and add icon", () => {
    render(
      <Payments
        newPayment={makeNewPayment()}
        payments={[makePayment()]}
        purchase={makePurchaseShow()}
      />,
    );

    expect(screen.getByRole("button", { name: "Update" })).toHaveClass("btn_lightamber");
    expect(screen.getByRole("button", { name: "Remove" })).toHaveClass("btn_red");
    expect(screen.getByRole("button", { name: "Add payment" })).toHaveClass("btn_lightblue");
    expect(screen.getByRole("button", { name: "Add payment" }).querySelector("svg")).not.toBeNull();
  });

  it("removes a payment after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);

    render(
      <Payments
        newPayment={makeNewPayment()}
        payments={[makePayment()]}
        purchase={makePurchaseShow()}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Remove" }));

    expect(window.confirm).toHaveBeenCalledWith("Remove this payment?");
    expect(router.delete).toHaveBeenCalledWith("/purchases/55/payments/1");
  });

  it("keeps a failed payment update in its submitted row", async () => {
    const user = userEvent.setup();
    nextFormErrors.mockReturnValueOnce({ value: "can't be blank" });

    render(
      <Payments
        newPayment={makeNewPayment()}
        payments={[makePayment()]}
        purchase={makePurchaseShow()}
      />,
    );

    await user.clear(screen.getAllByLabelText("Amount")[0]);
    await user.click(screen.getByRole("button", { name: "Update" }));

    expect(screen.getByText("can't be blank")).toBeInTheDocument();
    expect(screen.getAllByLabelText("Amount")[0]).toHaveValue(null);
    expect(screen.getByText("can't be blank").closest("tr")?.nextElementSibling).toHaveAttribute(
      "data-payment-id",
      "1",
    );
  });
});
