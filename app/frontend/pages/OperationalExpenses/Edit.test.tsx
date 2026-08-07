import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Edit from "./Edit";
import { makeExpenseRateOption, makeOperationalExpense } from "./test/factories";

describe("OperationalExpenses/Edit", () => {
  it("renders the edit heading and populated form", () => {
    render(
      <Edit
        expenseRates={[makeExpenseRateOption()]}
        operationalExpense={makeOperationalExpense()}
      />,
    );

    expect(screen.getByRole("heading", { name: "Edit OpEx Entry" })).toBeInTheDocument();
    expect(screen.getByLabelText("Date")).toHaveValue("2026-07-13");
    expect(screen.getByLabelText("Category")).toHaveValue("Packaging");
    expect(screen.getByLabelText("Amount")).toHaveValue(125.5);
    expect(screen.getByLabelText("Note")).toHaveValue("Damaged shipment");
    expect(screen.getByRole("button", { name: "Update OpEx Entry" })).toBeInTheDocument();
  });
});
