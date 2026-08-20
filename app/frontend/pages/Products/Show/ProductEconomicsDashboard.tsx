import { isBlank } from "@/components/Field";
import EconomicsRow, { type EconomicsTerm } from "@/components/profitability/EconomicsRow";
import { financialMetricHints } from "@/components/profitability/metricLabels";

import { type ProfitabilityRecord } from "../types";

type ProductEconomicsDashboardProps = {
  profitability: ProfitabilityRecord;
};

// Economics snapshot above the product tabs: every figure is driven by
// purchased units and money that has actually moved, not by what has sold —
// a purchased-but-unsold product still has a real cost, a potential sale
// value, and a cash position, so the card shows for any product with
// purchases or recorded cash activity.
export default function ProductEconomicsDashboard({
  profitability,
}: ProductEconomicsDashboardProps) {
  const showEconomics =
    !isBlank(profitability.expected_total_cost) || !isBlank(profitability.cash_position);

  if (!showEconomics) return null;

  return (
    <section
      aria-label="Product economics"
      className="economics_dashboard"
      data-testid="economics-dashboard"
    >
      <article
        aria-label="Profit summary"
        className="economics_snapshot_card"
        data-testid="profitability-snapshot-card"
      >
        <EconomicsRow groups={economicsGroups(profitability)} hoverWholeLabels />
      </article>
    </section>
  );
}

function economicsGroups(profitability: ProfitabilityRecord): EconomicsTerm[][] {
  return [
    [
      {
        anchor: "potentialSales",
        hint: financialMetricHints.potentialSales,
        label: "Potential Sales",
        value: profitability.potential_sales,
      },
      {
        anchor: "expectedTotalCost",
        hint: expectedTotalCostHint(),
        label: "Exp. Total Cost",
        value: profitability.expected_total_cost,
      },
    ],
    [
      {
        anchor: "expectedNetProfit",
        hint: expectedNetProfitHint(profitability),
        label: "Exp. Net Profit",
        result: true,
        value: profitability.expected_net_profit,
      },
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

// Purchases never received into a warehouse have no purchase items, so no
// unit of them can be priced. The caveat qualifies the figure, so it is
// stated there rather than left to be guessed.
function expectedTotalCostHint(): string {
  return `${financialMetricHints.expectedTotalCost} Purchases not received into a warehouse are not counted.`;
}

// The three parts are interpolated here rather than kept as a static hint
// entry, so the hover always names the figures the total was netted from.
function expectedNetProfitHint(profitability: ProfitabilityRecord): string {
  const potentialSales = profitability.potential_sales ?? "0";
  const expectedTotalCost = profitability.expected_total_cost ?? "0";
  const estimatedOpEx = profitability.business_expenses ?? "0";

  return `${financialMetricHints.expectedNetProfit}\n\nPotential sales: ${potentialSales}.\nExpected total cost: ${expectedTotalCost}.\nEstimated OpEx: ${estimatedOpEx}.`;
}

// The two halves are interpolated here rather than kept as a static hint
// entry, so the hover always names the figures behind today's number.
function cashPositionHint(profitability: ProfitabilityRecord): string {
  const customerPaid = profitability.received_revenue ?? "0";
  const purchasePaid = profitability.purchase_paid ?? "0";

  return `${financialMetricHints.cashPositionToday}\n\nCustomer paid: ${customerPaid}.\nPurchase paid: ${purchasePaid}.`;
}
