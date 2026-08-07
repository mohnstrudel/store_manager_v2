export type ProfitabilitySummaryRecord = {
  expense_rate_percent: number;
  expected_revenue: string | null;
  received_revenue: string | null;
  outstanding_revenue: string | null;
  refunded_revenue: string | null;
  purchase_cost: string | null;
  business_expenses: string | null;
  realized_profit: string | null;
  expected_final_profit: string | null;
};
