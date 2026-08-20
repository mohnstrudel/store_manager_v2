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
  if (isBlank(profitability.expected_revenue) || !hasRecordedCosts(profitability)) return null;

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

// A figure that reads differently once every scheduled charge is raised
// travels with its booked counterpart. COGS has no counterpart:
// `Sale::Profitability` charges the same purchase cost against the booked
// revenue and the projected total alike, so a second one would restate it.
function profitGroups(profitability: SaleProfitabilityRecord): EconomicsTerm[][] {
  return [
    [
      {
        anchor: "revenue",
        hint: revenueHint(profitability),
        label: "Revenue",
        value: profitability.expected_revenue,
      },
      {
        anchor: "projectedTotal",
        hint: withScope(financialMetricHints.projectedTotal, saleScope(profitability)),
        label: "Projected",
        value: profitability.projected_revenue,
      },
    ],
    [
      {
        anchor: "cogs",
        hint: cogsHint(profitability),
        label: "COGS",
        value: profitability.purchase_cost,
      },
    ],
    [
      {
        anchor: "opEx",
        hint: withScope(financialMetricHints.opEx, saleScope(profitability)),
        label: "OpEx",
        value: profitability.business_expenses,
      },
      {
        anchor: "projectedOpEx",
        hint: withScope(financialMetricHints.projectedOpEx, saleScope(profitability)),
        label: "Projected",
        value: profitability.projected_business_expenses,
      },
    ],
    [
      {
        anchor: "netProfit",
        hint: withScope(financialMetricHints.netProfit, saleScope(profitability)),
        label: "Net Profit",
        result: true,
        value: profitability.expected_final_profit,
      },
      {
        anchor: "projectedNetProfit",
        hint: withScope(financialMetricHints.projectedNetProfit, saleScope(profitability)),
        label: "Projected",
        result: true,
        value: profitability.projected_final_profit,
      },
    ],
    [
      {
        anchor: "outstanding",
        hint: withScope(financialMetricHints.outstanding, saleScope(profitability)),
        label: "Outstanding",
        value: profitability.outstanding_revenue,
      },
      {
        anchor: "refunded",
        hint: withScope(financialMetricHints.refunded, saleScope(profitability)),
        label: "Refunded",
        value: profitability.refunded_revenue,
      },
    ],
  ];
}

// How wide these figures reach used to be a caption under the card. It is the
// scope note for every term here: a lone sale totals itself, a plan totals
// every sale in it, and the reader cannot tell which from the figures alone.
//
// It says nothing about charges not yet raised, which the old caption did.
// That was never true of the terms it sat under — Revenue and COGS count what
// has been billed and spent. It is true only of the Projected terms, and each
// of their own hints already says so.
function saleScope(profitability: SaleProfitabilityRecord): string {
  if (profitability.scope !== "plan") return metricScopeNotes.sale;

  return "Across every sale in this payment plan.";
}

function revenueHint(profitability: SaleProfitabilityRecord): string {
  return withScope(financialMetricHints.revenue, saleScope(profitability));
}

// The merchandise and direct-expense split has no term of its own: it only
// ever restated COGS, so it is stated where a reader asks what COGS is made
// of. The figures are interpolated, so the hint is composed here rather than
// kept as a static entry in `financialMetricHints`.
function cogsHint(profitability: SaleProfitabilityRecord): string {
  const scoped = withScope(financialMetricHints.cogs, saleScope(profitability));

  if (isBlank(profitability.direct_expenses)) return scoped;

  return `${scoped} Here: ${profitability.merchandise_cost} in Item price and Shipping, plus ${profitability.direct_expenses} in Direct expenses.`;
}
