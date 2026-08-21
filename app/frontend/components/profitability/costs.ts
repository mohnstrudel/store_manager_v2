import { isBlank } from "@/components/Field";

export function hasRecordedCosts(summary: {
  business_expenses: string | null;
  item_price_total: string | null;
  purchase_expenses: string | null;
}): boolean {
  return (
    !isBlank(summary.item_price_total) ||
    !isBlank(summary.purchase_expenses) ||
    !isBlank(summary.business_expenses)
  );
}
