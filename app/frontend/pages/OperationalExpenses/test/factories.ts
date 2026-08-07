import type { ExpenseRateOption, OperationalExpenseRecord } from "../types";

export function makeOperationalExpense(
  overrides: Partial<OperationalExpenseRecord> = {},
): OperationalExpenseRecord {
  return {
    amount: "125.50",
    category: "Packaging",
    expense_rate_id: 1,
    id: 1,
    incurred_on: "2026-07-13",
    note: "Damaged shipment",
    ...overrides,
  };
}

export function makeExpenseRateOption(
  overrides: Partial<ExpenseRateOption> = {},
): ExpenseRateOption {
  return { id: 1, name: "Packaging", rate_percent: 5, ...overrides };
}
