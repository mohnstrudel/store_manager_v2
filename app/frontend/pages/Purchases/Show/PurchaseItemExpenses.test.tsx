import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it } from "vitest";
import { nextFormErrors } from "@/test/mocks/inertia";
import PurchaseItemExpenses from "./PurchaseItemExpenses";
import { makeNewPurchaseItemExpense, makePurchaseItemExpense } from "../test/factories";

describe("Purchases/Show/PurchaseItemExpenses", () => {
  it("creates a named expense", async () => {
    const user = userEvent.setup();
    render(
      <PurchaseItemExpenses
        expenses={[]}
        newExpense={makeNewPurchaseItemExpense()}
        purchasePath="/purchases/55"
      />,
    );

    await user.type(screen.getByLabelText("New expense description"), "Extra tax");
    await user.type(screen.getByLabelText("New expense amount"), "10.00");
    await user.click(screen.getByRole("button", { name: "Add expense" }));

    expect(router.post).toHaveBeenCalledWith(
      "/purchase_items/10/expenses",
      {
        purchase_expense: { description: "Extra tax", amount: "10" },
        return_to: "/purchases/55",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
    expect(screen.getByLabelText("New expense description")).toHaveValue("");
    expect(screen.getByLabelText("New expense amount")).not.toHaveAttribute("max");
  });

  it("keeps an invalid expense in the row that submitted it", async () => {
    const user = userEvent.setup();
    nextFormErrors.mockReturnValueOnce({ description: "can't be blank" });
    render(
      <PurchaseItemExpenses
        expenses={[makePurchaseItemExpense()]}
        newExpense={makeNewPurchaseItemExpense()}
        purchasePath="/purchases/55"
      />,
    );

    await user.clear(screen.getByLabelText("Description"));
    await user.click(screen.getByRole("button", { name: "Update" }));

    expect(screen.getByText("can't be blank")).toBeInTheDocument();
    expect(screen.getByLabelText("Description")).toHaveValue("");
    expect(screen.getByLabelText("Description").closest("tr")?.nextElementSibling).toBe(
      screen.getByText("can't be blank").closest("tr"),
    );
    expect(router.patch).toHaveBeenCalledWith(
      "/purchase_items/10/expenses/1",
      expect.anything(),
      expect.objectContaining({ preserveScroll: true }),
    );
  });

  it("shows existing amounts without forced zeroes and accepts any numeric step", () => {
    render(
      <PurchaseItemExpenses
        expenses={[makePurchaseItemExpense()]}
        newExpense={makeNewPurchaseItemExpense()}
        purchasePath="/purchases/55"
      />,
    );

    const amount = screen.getByLabelText("Amount");
    expect(amount).toHaveValue(10);
    expect(amount).not.toHaveAttribute("max");
    expect(amount).toHaveAttribute("step", "any");
  });

  it("keeps the new amount field narrow without limiting numeric entry", () => {
    render(
      <PurchaseItemExpenses
        expenses={[]}
        newExpense={makeNewPurchaseItemExpense()}
        purchasePath="/purchases/55"
      />,
    );

    const amount = screen.getByLabelText("New expense amount");
    expect(amount).not.toHaveAttribute("max");
    expect(amount).toHaveAttribute("step", "any");
  });

  it("uses the payment table's left-aligned input and actions layout", () => {
    render(
      <PurchaseItemExpenses
        expenses={[makePurchaseItemExpense()]}
        newExpense={makeNewPurchaseItemExpense()}
        purchasePath="/purchases/55"
      />,
    );

    const descriptionCell = screen.getByLabelText("New expense description").closest("td");
    const amountCell = screen.getByLabelText("New expense amount").closest("td");
    const actionsCell = screen.getByRole("button", { name: "Add expense" }).closest("td");

    expect(descriptionCell).toHaveClass("w-[30rem]");
    expect(amountCell).toHaveClass("w-60");
    expect(amountCell?.nextElementSibling).toBe(actionsCell);
    expect(actionsCell).not.toHaveClass("w-px");
  });
});
