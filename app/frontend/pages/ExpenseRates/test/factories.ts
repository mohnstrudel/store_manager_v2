import type { ExpenseRateRecord } from "../types";

export function makeExpenseRate(overrides: Partial<ExpenseRateRecord> = {}): ExpenseRateRecord {
  return {
    id: 1,
    name: "Payroll",
    rate_percent: 15,
    ...overrides,
  };
}
