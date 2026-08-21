import { isBlank } from "@/components/Field";
import { hasRecordedCosts } from "@/components/profitability/costs";
import EconomicsRow, { type EconomicsTerm } from "@/components/profitability/EconomicsRow";
import {
  financialMetricHints,
  metricScopeNotes,
  withScope,
} from "@/components/profitability/metricLabels";

import type { SaleProfitabilityRecord } from "../types";

type ProfitabilitySummaryProps = {
  profitability: SaleProfitabilityRecord | null;
};

export default function ProfitabilitySummary({ profitability }: ProfitabilitySummaryProps) {
  if (profitability === null) return null;
  if (isBlank(profitability.gross_revenue) || !hasRecordedCosts(profitability)) return null;

  return (
    <article
      aria-label="Profit summary"
      className="economics_snapshot_card"
      data-testid="sale-profitability-card"
    >
      <EconomicsRow groups={profitGroups(profitability)} hoverWholeLabels />
    </article>
  );
}

function profitGroups(profitability: SaleProfitabilityRecord): EconomicsTerm[][] {
  return [
    [
      {
        anchor: "grossRevenue",
        hint: withScope(financialMetricHints.grossRevenue, saleScope(profitability)),
        label: "Gross Revenue",
        value: profitability.gross_revenue,
      },
    ],
    [
      {
        anchor: "purchaseCost",
        hint: withScope(financialMetricHints.purchaseCost, saleScope(profitability)),
        label: "Pur. Cost",
        value: profitability.item_price_total,
      },
    ],
    [
      {
        anchor: "netProfit",
        hint: netProfitHint(profitability),
        label: "Net Profit",
        result: true,
        value: profitability.net_profit,
      },
    ],
    [
      {
        anchor: "purchaseExpenses",
        hint: purchaseExpensesHint(profitability),
        label: "Pur. Expenses",
        value: profitability.purchase_expenses,
      },
    ],
    [
      {
        anchor: "cashPositionToday",
        hint: cashPositionHint(profitability),
        label: "Cash today",
        result: true,
        value: profitability.cash_position,
      },
    ],
  ];
}

// How wide these figures reach: a lone sale totals itself, a plan totals every
// sale in it, and the reader cannot tell which from the figures alone.
function saleScope(profitability: SaleProfitabilityRecord): string {
  if (profitability.scope !== "plan") return metricScopeNotes.sale;

  return "Across every sale in this payment plan.";
}

// The shipping and direct-expense split has no term of its own, so it is
// stated where a reader asks what Purchase Expenses is made of. The figures
// are interpolated, so the hint is composed here.
function purchaseExpensesHint(profitability: SaleProfitabilityRecord): string {
  const scoped = withScope(financialMetricHints.purchaseExpenses, saleScope(profitability));

  if (isBlank(profitability.direct_expenses)) return scoped;

  const shipping = profitability.purchase_shipping_cost ?? "0";

  return `${scoped} Here: ${shipping} in Shipping, plus ${profitability.direct_expenses} in Direct expenses.`;
}

// OpEx has no term of its own, so this is the only place it appears: the hover
// names every figure the profit was netted from, OpEx included.
function netProfitHint(profitability: SaleProfitabilityRecord): string {
  const scoped = withScope(financialMetricHints.netProfit, saleScope(profitability));
  const grossRevenue = profitability.gross_revenue ?? "0";
  const purchaseCost = profitability.item_price_total ?? "0";
  const purchaseExpenses = profitability.purchase_expenses ?? "0";
  const estimatedOpEx = profitability.business_expenses ?? "0";

  return `${scoped}\n\nGross Revenue: ${grossRevenue}.\nPurchase Cost: ${purchaseCost}.\nPurchase Expenses: ${purchaseExpenses}.\nEstimated OpEx: ${estimatedOpEx}.`;
}

// The two halves are interpolated so the hover always names the figures behind
// today's number.
function cashPositionHint(profitability: SaleProfitabilityRecord): string {
  const scoped = withScope(financialMetricHints.cashPositionToday, saleScope(profitability));
  const collected = profitability.collected_revenue ?? "0";
  const purchasePaid = profitability.purchase_paid ?? "0";

  return `${scoped}\n\nCollected and kept: ${collected}.\nPaid to suppliers: ${purchasePaid}.`;
}
