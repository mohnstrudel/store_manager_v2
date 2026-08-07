export type OperationalExpenseRecord = {
  id: number | null;
  incurred_on: string;
  category: string;
  amount: string;
  note: string;
  expense_rate_id: number | null;
};

export type ExpenseRateOption = {
  id: number;
  name: string;
  rate_percent: number;
};
