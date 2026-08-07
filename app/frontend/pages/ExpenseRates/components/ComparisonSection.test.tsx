import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import ComparisonSection from "./ComparisonSection";
import { makeComparisonRow } from "../test/factories";

describe("ExpenseRates/components/ComparisonSection", () => {
  it("shows the canonical labels, monthly Revenue hint, and unmatched actuals", () => {
    render(
      <ComparisonSection
        comparison={[
          makeComparisonRow({
            by_rate: [
              { actual: "30.00", assumed: "100.00", label: "Packaging" },
              { actual: "-5.00", assumed: "0.00", label: "Unmatched · Rebate" },
            ],
          }),
        ]}
      />,
    );

    expect(screen.getByText("July 2026")).toBeInTheDocument();
    expect(screen.getByText("Unmatched · Rebate")).toBeInTheDocument();
    expect(screen.getByText("Estimated vs. Actual OpEx")).toBeInTheDocument();
    expect(screen.getAllByLabelText("More information")).toHaveLength(4);
  });

  it("explains what the comparison is when there is no data yet", () => {
    render(<ComparisonSection comparison={[]} />);

    expect(screen.getByText("Estimated vs. Actual OpEx")).toBeInTheDocument();
    expect(screen.getByText(/month-by-month comparison/i)).toBeInTheDocument();
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
  });

  it("omits the rate breakdown toggle when a month has no rate data", () => {
    render(<ComparisonSection comparison={[makeComparisonRow({ by_rate: [] })]} />);

    expect(screen.queryByText("OpEx rate breakdown")).not.toBeInTheDocument();
  });

  it("describes OpEx above and below the estimate in plain language", () => {
    render(
      <ComparisonSection
        comparison={[
          makeComparisonRow({ comparison: { amount: "25.50", relation: "over" } }),
          makeComparisonRow({
            comparison: { amount: "10.00", relation: "under" },
            month: "June 2026",
          }),
        ]}
      />,
    );

    expect(screen.getByRole("cell", { name: "25.50 over estimate" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "10.00 under estimate" })).toBeInTheDocument();
  });

  it("calls out an exact estimate without a numeric difference", () => {
    render(
      <ComparisonSection
        comparison={[makeComparisonRow({ comparison: { amount: "0.00", relation: "equal" } })]}
      />,
    );

    expect(screen.getByRole("cell", { name: "On estimate" })).toBeInTheDocument();
  });
});
