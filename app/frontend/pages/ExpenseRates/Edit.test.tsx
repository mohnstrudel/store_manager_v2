import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Edit from "./Edit";
import { makeExpenseRate } from "./test/factories";

describe("ExpenseRates/Edit", () => {
  it("renders the edit heading and populated form", () => {
    render(<Edit expenseRate={makeExpenseRate()} />);

    expect(screen.getByRole("heading", { name: "Edit OpEx Rate" })).toBeInTheDocument();
    expect(screen.getByLabelText("Name")).toHaveValue("Payroll");
    expect(screen.getByLabelText("OpEx rate (% of revenue)")).toHaveValue(15);
    expect(screen.getByRole("button", { name: "Update OpEx Rate" })).toBeInTheDocument();
  });
});
