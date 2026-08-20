import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { makeOperationalExpense } from "../test/factories";
import type { OperationalExpenseRecord } from "../types";
import Table from "./Table";

describe("OperationalExpenses/components/Table", () => {
  it("renders expense rows with an edit link", () => {
    renderTable();

    expect(screen.getByRole("cell", { name: "Packaging" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/operational_expenses/1/edit",
    );
  });

  it("shows an explanatory empty state with a call to action when there are no expenses", () => {
    renderTable({ expenses: [] });

    expect(screen.queryByRole("table")).not.toBeInTheDocument();
    expect(screen.getByText(/what you actually spent/i)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add your first OpEx entry/ })).toHaveAttribute(
      "href",
      "/operational_expenses/new",
    );
  });

  it("navigates to the edit page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderTable();
    const row = screen.getByRole("cell", { name: "Packaging" }).closest("tr");

    expect(row).not.toBeNull();
    await user.click(row!);

    expect(router.visit).toHaveBeenCalledWith("/operational_expenses/1/edit");
  });

  it("deletes the expense after confirmation", async () => {
    vi.spyOn(window, "confirm").mockReturnValue(true);
    const user = userEvent.setup();
    renderTable();

    await user.click(screen.getByRole("button", { name: /Delete/ }));

    expect(router.delete).toHaveBeenCalledWith("/operational_expenses/1");
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
  expenses = [makeOperationalExpense()],
}: { expenses?: OperationalExpenseRecord[] } = {}) {
  return render(<Table expenses={expenses} />);
}
