import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Index from "./Index";
import { makeExpenseRate } from "./test/factories";

describe("ExpenseRates/Index", () => {
  it("renders the heading, add link, and table row", () => {
    render(<Index expenseRates={[makeExpenseRate()]} />);

    expect(screen.getByRole("heading", { level: 1, name: "OpEx Rates" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/expense_rates/new",
    );
    expect(screen.getByRole("cell", { name: "Payroll" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/expense_rates/1/edit",
    );
  });
});
