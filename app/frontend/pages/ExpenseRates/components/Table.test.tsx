import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { makeExpenseRate } from "../test/factories";
import type { ExpenseRateRecord } from "../types";
import Table from "./Table";

describe("ExpenseRates/components/Table", () => {
  it("renders expense rate rows with an edit link", () => {
    renderTable();

    expect(screen.getByRole("cell", { name: "Payroll" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "15%" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/expense_rates/1/edit",
    );
  });

  it("shows an explanatory empty state with a call to action when there are no rates", () => {
    renderTable({ expenseRates: [] });

    expect(screen.queryByRole("grid")).not.toBeInTheDocument();
    expect(screen.getByText(/recurring operating costs/i)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add your first OpEx rate/ })).toHaveAttribute(
      "href",
      "/expense_rates/new",
    );
  });

  it("navigates to the edit page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderTable();
    const row = screen.getByRole("cell", { name: "Payroll" }).closest("tr");

    expect(row).not.toBeNull();
    await user.click(row!);

    expect(router.visit).toHaveBeenCalledWith("/expense_rates/1/edit");
  });

  it("deletes the rate after confirmation", async () => {
    vi.spyOn(window, "confirm").mockReturnValue(true);
    const user = userEvent.setup();
    renderTable();

    await user.click(screen.getByRole("button", { name: /Delete/ }));

    expect(router.delete).toHaveBeenCalledWith("/expense_rates/1");
  });

  it("does not delete when the confirmation is declined", async () => {
    vi.spyOn(window, "confirm").mockReturnValue(false);
    const user = userEvent.setup();
    renderTable();

    await user.click(screen.getByRole("button", { name: /Delete/ }));

    expect(router.delete).not.toHaveBeenCalled();
  });
});

function renderTable({
  expenseRates = [makeExpenseRate()],
}: { expenseRates?: ExpenseRateRecord[] } = {}) {
  return render(<Table expenseRates={expenseRates} />);
}
