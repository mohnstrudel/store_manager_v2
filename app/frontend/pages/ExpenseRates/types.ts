export type ExpenseRateRecord = {
  id: number | null;
  name: string;
  rate_percent: number;
};

export type ComparisonRow = {
  month: string;
  revenue: string;
  assumed_total: string;
  actual_total: string;
  comparison: { amount: string; relation: "under" | "over" | "equal" };
  by_rate: Array<{ label: string; assumed: string; actual: string }>;
};
