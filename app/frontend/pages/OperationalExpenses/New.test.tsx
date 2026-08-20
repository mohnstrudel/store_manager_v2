import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";

import New from "./New";
import { makeExpenseRateOption, makeOperationalExpense } from "./test/factories";

const emptyOperationalExpense = () =>
  makeOperationalExpense({ id: null, category: "", amount: "", note: "", expense_rate_id: null });

describe("OperationalExpenses/New", () => {
  it("renders the form", () => {
    render(
      <New
        expenseRates={[makeExpenseRateOption()]}
        operationalExpense={emptyOperationalExpense()}
      />,
    );

    expect(screen.getByRole("heading", { name: "New OpEx Entry" })).toBeInTheDocument();
    expect(screen.getByLabelText("Date")).toBeInTheDocument();
    expect(screen.getByLabelText("Category")).toBeInTheDocument();
    expect(screen.getByLabelText("Amount")).toBeInTheDocument();
    expect(screen.getByLabelText("OpEx rate (optional)")).toBeInTheDocument();
    expect(screen.getByLabelText("Note")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create OpEx Entry" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { amount: "can't be blank" } });

    render(
      <New
        expenseRates={[makeExpenseRateOption()]}
        operationalExpense={emptyOperationalExpense()}
      />,
    );

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});
