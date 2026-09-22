import { isBlank } from "@/components/Field";
import EconomicsRow, { type EconomicsTerm } from "@/components/profitability/EconomicsRow";
import {
  financialMetricHints,
  metricScopeNotes,
  withScope,
} from "@/components/profitability/metricLabels";

import { type ProfitabilityRecord } from "../types";

type ProductEconomicsDashboardProps = {
  profitability: ProfitabilityRecord;
};

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

function expectedTotalCostHint(): string {
  return `${financialMetricHints.expectedTotalCost} Purchases not received into a warehouse are not counted.`;
}

function expectedNetProfitHint(profitability: ProfitabilityRecord): string {
  const potentialSales = profitability.potential_sales ?? "0";
  const expectedTotalCost = profitability.expected_total_cost ?? "0";
  const estimatedOpEx = profitability.business_expenses ?? "0";

  return `${financialMetricHints.expectedNetProfit}\n\nPotential sales: ${potentialSales}.\nExpected total cost: ${expectedTotalCost}.\nEstimated OpEx: ${estimatedOpEx}.`;
}

function cashPositionHint(profitability: ProfitabilityRecord): string {
  const scoped = withScope(financialMetricHints.cashPositionToday, metricScopeNotes.product);
  const collectedAndKept = profitability.collected_revenue ?? "0";
  const paidToSuppliers = profitability.purchase_paid ?? "0";

  return `${scoped}\n\nCollected and kept: ${collectedAndKept}.\nPaid to suppliers: ${paidToSuppliers}.`;
}
