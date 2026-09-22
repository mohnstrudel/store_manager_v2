export type PaymentProgress = {
  progress: number;
  paid: string | null;
  price: string | null;
  debt: string | null;
  amounts_unknown?: boolean;
};

export type PaymentPlanSaleRef = {
  path: string;
  identifier: string;
};

export type PaymentPlanPaymentRef = PaymentPlanSaleRef & {
  sequence: number;
  is_current_sale: boolean;
};

export type SalePaymentPlanRecord = {
  id: number;
  kind: "deposit" | "installments" | "payment_terms";
  expected_parts: number;
  collected_parts: number;
  sale_part_number: number | null;
  is_origin_sale: boolean;
  deposit_percent: number | null;
  projected_total: string | null;
  projected_collected: string | null;
  origin_sale: PaymentPlanSaleRef | null;
  payments: PaymentPlanPaymentRef[];
};

export type SettlementStatus = "paid" | "not_fully_paid" | "unknown" | null;

export type SalePaymentProgressSource =
  | "plan_deposit"
  | "plan_schedule"
  | "amount"
  | "woo_deposit"
  | "woo_unavailable"
  | null;

export type SalePaymentProgress = {
  source: SalePaymentProgressSource;
  percent: number | null;
  paid: string | null;
  total: string | null;
  remaining: string | null;
  completed_parts: number | null;
  expected_parts: number | null;
  sale_part_number: number | null;
  plan_id: number | null;
};
