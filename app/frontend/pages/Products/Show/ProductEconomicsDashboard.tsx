import { isBlank } from "@/components/Field";
import { hasRecordedCosts } from "@/components/profitability/costs";
import EconomicsRow, { type EconomicsTerm } from "@/components/profitability/EconomicsRow";
import {
  financialMetricHints,
  salesScopeNote,
  withScope,
} from "@/components/profitability/metricLabels";
import { type ProfitabilityRecord } from "../types";

type ProductEconomicsDashboardProps = {
  profitability: ProfitabilityRecord;
};

// Economics snapshot above the product tabs: what the product cost to stock,
// and — once it has sold — the P&L in a row of its own. The P&L needs both
// revenue and recorded costs to say anything; without them it would claim a
// profit that merely repeats revenue. The invested total does not, which is
// what a purchased-but-unsold product has to show. Whether the product "has
// sales" for this is decided once on the backend (`has_sale_items`) rather
// than re-derived here.
export default function ProductEconomicsDashboard({
  profitability,
}: ProductEconomicsDashboardProps) {
  const showProfitRow =
    profitability.has_sale_items &&
    !isBlank(profitability.expected_revenue) &&
    hasRecordedCosts(profitability);
  const showInvestedTotal = !isBlank(profitability.invested_total);

  if (!showProfitRow && !showInvestedTotal) return null;

  return (
    <section
      aria-label="Product economics"
      className="economics_dashboard"
      data-testid="economics-dashboard"
    >
      {showProfitRow && (
        <article
          aria-label="Profit summary"
          className="economics_snapshot_card"
          data-testid="profitability-snapshot-card"
        >
          <EconomicsRow groups={profitGroups(profitability)} />
        </article>
      )}
      {showInvestedTotal && (
        <article
          aria-label="Purchase investment"
          className="economics_snapshot_card"
          data-testid="invested-total-card"
        >
          <EconomicsRow groups={investedGroups(profitability)} />
        </article>
      )}
    </section>
  );
}

// Every figure here is summed over the product's sales, so once there is more
// than one, every hint closes by naming how many were counted. The invested
// card does not: its figures come from purchased units, not from sales.
function profitGroups(profitability: ProfitabilityRecord): EconomicsTerm[][] {
  const acrossSales = salesScopeNote(profitability.counted_sales_total);

  return [
    [
      {
        anchor: "revenue",
        hint: withScope(financialMetricHints.revenue, acrossSales),
        label: "Revenue",
        value: profitability.expected_revenue,
      },
      {
        anchor: "merchandise",
        hint: withScope(financialMetricHints.merchandise, acrossSales),
        label: "Merchandise",
        value: profitability.merchandise_cost,
      },
      {
        anchor: "directExpenses",
        hint: withScope(financialMetricHints.directExpenses, acrossSales),
        label: "Direct",
        value: profitability.direct_expenses,
      },
      {
        anchor: "opEx",
        hint: withScope(financialMetricHints.opEx, acrossSales),
        label: "OpEx",
        value: profitability.business_expenses,
      },
    ],
    [
      {
        anchor: "netProfit",
        hint: withScope(financialMetricHints.netProfit, acrossSales),
        label: "Net Profit",
        result: true,
        value: profitability.expected_final_profit,
      },
      {
        anchor: "profitInHand",
        hint: withScope(financialMetricHints.profitInHand, acrossSales),
        label: "In hand",
        result: true,
        value: profitability.realized_profit,
      },
    ],
    [
      {
        anchor: "received",
        hint: withScope(financialMetricHints.received, acrossSales),
        label: "Received",
        value: profitability.received_revenue,
      },
      {
        anchor: "outstanding",
        hint: withScope(financialMetricHints.outstanding, acrossSales),
        label: "Outstanding",
        value: profitability.outstanding_revenue,
      },
      {
        anchor: "refunded",
        hint: withScope(financialMetricHints.refunded, acrossSales),
        label: "Refunded",
        value: profitability.refunded_revenue,
      },
    ],
  ];
}

function investedGroups(profitability: ProfitabilityRecord): EconomicsTerm[][] {
  return [
    [
      {
        anchor: "invested",
        hint: investedHint(),
        label: "Invested",
        value: profitability.invested_total,
      },
      {
        anchor: "unsoldStockValue",
        hint: financialMetricHints.unsoldStockValue,
        label: "Unsold",
        value: profitability.remaining_inventory_cost,
      },
    ],
  ];
}

// Purchases never received into a warehouse have no purchase items, so no
// unit of them can be priced. The caveat qualifies the invested figure, so it
// is stated there rather than left to be guessed.
function investedHint(): string {
  return `${financialMetricHints.invested} Purchases not received into a warehouse are not counted.`;
}
