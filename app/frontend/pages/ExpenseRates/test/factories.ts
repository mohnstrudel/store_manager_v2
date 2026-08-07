import type { ComparisonRow, ExpenseRateRecord } from "../types";

export function makeExpenseRate(overrides: Partial<ExpenseRateRecord> = {}): ExpenseRateRecord {
  return {
    id: 1,
    name: "Payroll",
    rate_percent: 15,
    ...overrides,
  };
}

export function makeComparisonRow(overrides: Partial<ComparisonRow> = {}): ComparisonRow {
  return {
    actual_total: "125.50",
    assumed_total: "100.00",
    by_rate: [{ actual: "125.50", assumed: "100.00", label: "Packaging" }],
    comparison: { amount: "25.50", relation: "over" },
    month: "July 2026",
    revenue: "2,000.00",
    ...overrides,
  };
}
