import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Index from "./Index";
import { makeComparisonRow, makeExpenseRate } from "./test/factories";

describe("ExpenseRates/Index", () => {
  it("renders the heading, add link, and table row", () => {
    render(<Index comparison={[makeComparisonRow()]} expenseRates={[makeExpenseRate()]} />);

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

  it("shows the estimated vs. actual OpEx comparison below the rates table", () => {
    render(<Index comparison={[makeComparisonRow()]} expenseRates={[makeExpenseRate()]} />);

    const table = screen.getByRole("cell", { name: "Payroll" }).closest("table");
    const comparisonHeading = screen.getByRole("heading", { name: "Estimated vs. Actual OpEx" });

    expect(comparisonHeading).toBeInTheDocument();
    expect(
      table!.compareDocumentPosition(comparisonHeading) & Node.DOCUMENT_POSITION_FOLLOWING,
    ).toBeTruthy();
  });
});
