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
