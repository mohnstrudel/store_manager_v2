import { isBlank } from "@/components/Field";
import { type ProfitabilitySummaryRecord } from "@/types/profitability";

export function hasRecordedCosts(
  summary: Pick<ProfitabilitySummaryRecord, "business_expenses" | "purchase_cost">,
): boolean {
  return !isBlank(summary.purchase_cost) || !isBlank(summary.business_expenses);
}
