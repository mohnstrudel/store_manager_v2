# 02. Collapse the sale profit summary into one line

Spec: ../spec.md
Status: done
Blocked by: 01

## What to build

The profit summary card on the Sale show page states its economics as one row of four groups instead of two stacked equations. No `−` or `=` operators appear. A group whose figure reads differently once every scheduled charge is raised shows both, arrow between them, each under its own label — the right-hand one labelled `Projected`. The cost group shows one figure, because it is the same number on both bases.

The merchandise and direct-expense split that used to occupy two columns moves into the cost column's hover tip, where it names the live figures.

The cash strip below — received, outstanding, refunded, and the payment-plan scope caption — is unchanged.

## Acceptance criteria

- [x] The card renders one equation row of four groups: `Revenue`, `COGS`, `OpEx, {n}%`, `Net Profit`.
- [x] No `−` or `=` operator glyph renders anywhere in the card.
- [x] `Merchandise cost` and `Direct expenses` no longer appear as labels.
- [x] With a projection present, `Revenue`, `OpEx`, and `Net Profit` each show two figures joined by an arrow; `COGS` shows exactly one figure and no arrow.
- [x] Every figure has a label of its own; the projected ones read `Projected`. No tip mark is attached to a number — all marks sit in the label row.
- [x] Each `Projected` label's tip resolves to its own glossary anchor (`projectedTotal`, `projectedOpEx`, `projectedNetProfit`).
- [x] With `projected_final_profit` null, every group shows one figure, and no arrow or `Projected` label renders.
- [x] The COGS tip states the merchandise and direct-expense figures when `direct_expenses` is present, and omits that sentence when it is null.
- [x] Each term is individually addressable via `data-testid="sale-profitability-<anchor>"`.
- [x] Both net-profit figures keep their tone: negative in red, non-negative in green, on both the label and the value.
- [x] The gap between groups visibly exceeds the gap inside a group, so a pair reads as a pair.
- [x] The card renders nothing when profitability is null or when no costs were recorded.
- [x] The cash strip and its scope caption are byte-identical in behavior to before.

## Anchors

- `app/frontend/pages/Sales/Show/ProfitabilitySummary.tsx:37-120` — `ProfitEquation` and `ProjectedProfitEquation`, the two rows to merge.
- `app/frontend/pages/Sales/Show/ProfitabilitySummary.tsx:172-178` — `EquationOperator`, deleted from this file. `ProductEconomicsDashboard` keeps its own copy; do not touch that one.
- `app/frontend/pages/Sales/Show/ProfitabilitySummary.tsx:180-225` — `CashStrip`, `buildCashStripItems`, `scopeCaption`. Unchanged.
- `app/frontend/pages/Sales/Show/ProfitabilitySummary.tsx:145-170` — `NetProfitTerm` and its `data-tone` label treatment; the tone behavior survives into the merged result column.
- `app/frontend/components/profitability/MetricHint.tsx` — created by ticket 01; the projected figure's tip.
- `app/frontend/components/profitability/metricLabels.ts:1-32` — `financialMetricHints`. Read the `cogs`, `revenue`, `opEx`, `netProfit`, `projectedTotal`, `projectedOpEx`, `projectedNetProfit` entries; add nothing.
- `app/frontend/styles/application/profitability.css:25-68` — `.economics_snapshot__equation`, the `--projected` / `--secondary` shared rule at lines 33-36, `__term`, `__value`, `__operator`.
- `app/frontend/pages/Sales/Show.test.tsx:131-138` — `"shows the profit summary as a card of its own, outside the payment card"` asserts `Direct expenses` inside the summary. Retarget to a surviving label.
- `app/frontend/components/PlanProgressBar.tsx:23` — the existing `sr-only` idiom to follow.

## Worked example

From `SalePaymentPlan`: a 30 % deposit on a 1 020 deal, remaining charges not yet raised, 15 % OpEx rate. Both bases reconcile against the same `purchase_cost` of 700, computed by hand:

| Column | Booked | Projected |
|---|---|---|
| Revenue | 300 | 1 020 |
| COGS | 700 | — (same figure) |
| OpEx, 15% | 45 | 153 |
| Net Profit | −445 | 167 |

- Booked: `300 − 700 − 45 = −445`
- Projected: `1 020 − 700 − 153 = 167`

The projected OpEx is 15 % of the projected revenue (`1 020 × 0.15 = 153`), **not** the booked 45. Reusing 45 would report 175 instead of 167 — the existing test at `ProfitabilitySummary.test.tsx:127-136` pins exactly this, and that guard must survive the rewrite.

With `direct_expenses` of 5 and `merchandise_cost` of 695, COGS still reads 700 and the tip adds a sentence naming 695 and 5.

## UI states

- **No projection** (`projected_final_profit === null` — a lone sale, or a plan with no contract value): four single labelled figures, no arrows, no `Projected` terms.
- **Zero OpEx rate** (`expense_rate_percent === 0`): the OpEx group does not render. Existing guard, preserved.
- **Blank purchase cost**: the COGS group does not render. `hasRecordedCosts` passes on business expenses alone, so this is reachable; the old code rendered a blank-valued term here.
- **Nothing to claim**: null profitability, blank `expected_revenue`, or `hasRecordedCosts` false → the component returns null. Existing guards at `ProfitabilitySummary.tsx:19-20`, preserved.
- **Accessibility**: the arrow is `aria-hidden`. Every figure is named by a visible label, so nothing depends on the glyph.
- **Overflow**: the row keeps `overflow-x-auto` from `.economics_snapshot__equation` so the groups scroll inside the card rather than wrap or push the page wide. Verified at 375 px: the row scrolls, the document does not.

## Non-goals

- Do not change `Sale::Profitability`, `SalePaymentPlan#profitability`, or any Rails file.
- Do not remove `merchandise_cost` or `direct_expenses` from `SaleProfitabilityRecord`; the tip consumes them.
- Do not add a static COGS-breakdown entry to `financialMetricHints`; the hint interpolates record figures, so compose it at the call site.
- Do not delete `.economics_snapshot__operator` or `.economics_snapshot__equation--secondary` — `ProductEconomicsDashboard` uses both.
- Do not touch `ProductEconomicsDashboard` or the glossary; ticket 03 owns those.
- Do not restyle or reorder the cash strip.
- Do not perform money arithmetic in React; every figure is a backend string.

## Coordination notes

- Needs `MetricHint` from ticket 01. Runs in parallel with ticket 03 — no shared files.
- `profitability.css` is shared with the Product dashboard. Only the `--projected` selector is removed from the rule at lines 33-36; `--secondary` stays on that rule.

## Focused verification

- `mise exec -- pnpm exec vitest run app/frontend/pages/Sales` — proves the merged line, both reconciliations, every UI state above, and the retargeted `Sales/Show.test.tsx` assertion.
- `mise exec -- pnpm exec vitest run app/frontend/pages/Products/Show/ProductEconomicsDashboard.test.tsx` — proves the shared CSS edit and the deleted local `EquationOperator` left the Product dashboard intact.
- `mise exec -- pnpm exec tsc --noEmit && mise exec -- pnpm exec oxlint app/frontend && mise exec -- pnpm exec oxfmt --check app/frontend` — types, lint, formatting.
