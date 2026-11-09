import type { Sale, SalePaymentPlan, SaleSettlementStatus } from "@/types/serializers";

export type PaymentProgress = {
  progress: number;
  paid: string | null;
  price: string | null;
  debt: string | null;
  amounts_unknown?: boolean;
};

export type SalePaymentPlanRecord = SalePaymentPlan;

export type PaymentPlanPaymentRef = SalePaymentPlan["payments"][number];

export type PaymentPlanSaleRef = Omit<PaymentPlanPaymentRef, "sequence" | "is_current_sale">;

export type SettlementStatus = SaleSettlementStatus | null;

export type SalePaymentProgress = NonNullable<Sale["payment_progress"]>;

export type SalePaymentProgressSource = SalePaymentProgress["source"];
