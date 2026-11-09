import type { ExpenseRateFormRecord, ExpenseRateRecord } from "../types";

export function makeExpenseRate(overrides: Partial<ExpenseRateRecord> = {}): ExpenseRateRecord {
  return {
    id: 1,
    name: "Payroll",
    rate_percent: 15,
    ...overrides,
  };
}

export function makeExpenseRateForm(
  overrides: Partial<ExpenseRateFormRecord> = {},
): ExpenseRateFormRecord {
  return {
    name: "Payroll",
    rate_percent: 15,
    ...overrides,
  };
}
