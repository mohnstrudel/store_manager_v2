import type { SalePaymentPlanRecord } from "@/types/payment";
import type { PaginationMeta } from "@/types/pagination";
import type { ProfitabilitySummaryRecord } from "@/types/profitability";

type HasId = { id: number };

export function makePagination(overrides: Partial<PaginationMeta> = {}): PaginationMeta {
  return {
    current_page: 1,
    total_pages: 1,
    total_count: 1,
    limit: 50,
    ...overrides,
  };
}

export function makeProfitabilitySummary(
  overrides: Partial<ProfitabilitySummaryRecord> = {},
): ProfitabilitySummaryRecord {
  return {
    expense_rate_percent: 10,
    expected_revenue: "300",
    received_revenue: "100",
    outstanding_revenue: "200",
    refunded_revenue: "0",
    purchase_cost: "120",
    business_expenses: "30",
    realized_profit: "-50",
    expected_final_profit: "150",
    ...overrides,
  };
}

export function makeSalePaymentPlan(
  overrides: Partial<SalePaymentPlanRecord> = {},
): SalePaymentPlanRecord {
  return {
    id: 1,
    provider: "seal",
    kind: "installments",
    status: "active",
    expected_parts: 8,
    collected_parts: 3,
    sale_part_number: null,
    is_origin_sale: true,
    deposit_percent: null,
    projected_total: null,
    projected_remainder: null,
    projected_collected: null,
    next_due_at: null,
    origin_sale: null,
    payments: [],
    ...overrides,
  };
}

// Like FactoryBot's create_list: builds `count` records from `factory`, auto-incrementing
// `id` so each record has a unique key. Override other fields via the third argument.
export function makeList<T extends HasId>(
  factory: (overrides?: Partial<T>) => T,
  count: number,
  // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
  overrides: Omit<Partial<T>, "id"> = {} as Omit<Partial<T>, "id">,
): T[] {
  return Array.from({ length: count }, (_, i) =>
    // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
    factory({ ...overrides, id: i + 1 } as Partial<T>),
  );
}
