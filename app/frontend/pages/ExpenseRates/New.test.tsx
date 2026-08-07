import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import New from "./New";
import { makeExpenseRate } from "./test/factories";

const emptyExpenseRate = () => makeExpenseRate({ id: null, name: "", rate_percent: 0 });

describe("ExpenseRates/New", () => {
  it("renders the form", () => {
    render(<New expenseRate={emptyExpenseRate()} />);

    expect(screen.getByRole("heading", { name: "New OpEx Rate" })).toBeInTheDocument();
    expect(screen.getByLabelText("Name")).toBeInTheDocument();
    expect(screen.getByLabelText("OpEx rate (% of revenue)")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create OpEx Rate" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { rate_percent: "can't be blank" } });

    render(<New expenseRate={emptyExpenseRate()} />);

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});
