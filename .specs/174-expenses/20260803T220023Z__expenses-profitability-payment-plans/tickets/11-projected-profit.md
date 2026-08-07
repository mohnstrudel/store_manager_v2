# 11. Report projected profit alongside booked profit

Spec: ../spec.md
Status: done
Blocked by: 10

## What to build

When a customer pays a deposit, the sale page reports a large loss. Revenue counts only the money
charged so far, while cost of goods counts the entire deal — so a 30 % deposit is measured against
100 % of the purchase cost. The number is arithmetically correct and commercially meaningless.

Now that a plan knows what the whole deal is worth, state profit on two bases: what the booked
charges actually produce, and what the deal will produce once every charge is raised. Show both.
Never blend them into a single figure, and never let the projected basis silently replace the
booked one — a reader must always be able to tell which number is money and which is forecast.

## Acceptance criteria

- [x] A sale in a payment plan with a known contract value shows two profit statements: one from charges already raised, one from the full contract.
- [x] A 30 % deposit reports a negative booked profit and a positive projected profit at the same time, and neither figure is presented as the other.
- [x] Each statement's own terms reconcile exactly to the profit it states.
- [x] Operating expenses in the projected statement are calculated on the projected revenue, not carried over from the booked one.
- [x] A plan with no contract value renders exactly what it renders today — one statement, unchanged.
- [x] A sale that belongs to no plan, or to more than one, renders one statement and carries no projected values at all.
- [x] The caption naming the plan-wide scope also says the projection covers charges not yet raised.

## Anchors

- `app/models/sale_payment_plan.rb:131-141` — `#profitability`. Sums `PROFITABILITY_COMPONENTS`
  (`:26-37`) across `#related_sales` (`:180-182`), then recomputes the two profit figures from the
  totals so profit is not double-summed. The new keys follow that same shape.
- `app/models/sale/profitability.rb:39-49` — `#profitability_summary`. Merges `scope: :plan` when
  `payment_plans_for_display` has exactly one plan, else `scope: :sale`. The `:sale` branch
  (`#profitability`, `:9-30`) must carry the projected keys as `nil`.
- `app/helpers/sale_helper.rb:154-180` — `#sale_profitability_props`. Every money value goes through
  `format_money`, which returns `nil` for zero and for blank — so the frontend type is
  `string | null` for each.
- `app/frontend/pages/Sales/types.ts:105-109` — `SaleProfitabilityRecord`.
- `app/frontend/pages/Sales/Show/ProfitabilitySummary.tsx` — the existing equation is built at
  `:40-123` from `EquationTerm` / `EquationOperator` / `NetProfitTerm`; the scope caption is the
  first item of `buildCashStripItems` (`:144-164`).
- `app/frontend/components/profitability/metricLabels.ts` — hints live here; the new terms need
  their own.

## Contract

Three keys, added by `SalePaymentPlan#profitability` and present **only** when `projected_total`
is present:

```
projected_revenue           = projected_total
projected_business_expenses = (projected_total × expense_fraction).round(2)
projected_final_profit      = projected_total − purchase_cost − projected_business_expenses
```

`purchase_cost` is the already-summed plan figure — the whole deal's cost of goods is already
attached to the originating order, so it needs no projection.

## Worked example for the tests

A 30 % deposit on a 1 020 deal, with the remaining charges not yet raised, at a 15 % OpEx rate:

| Term | Booked | Projected |
|---|---|---|
| Revenue | 300.00 | 1020.00 |
| Purchase cost | 700.00 | 700.00 |
| OpEx @ 15 % | 45.00 | 153.00 |
| **Profit** | **−445.00** | **167.00** |

Booked OpEx is `300 × 0.15`; projected OpEx is `1020 × 0.15`. Reusing the booked 45.00 in the
projected row would report 175.00 and overstate the profit by 108.00 — that error is the reason
for the separate calculation, and a test should pin it.

## Non-goals

- Do not change the booked equation's terms, order, or arithmetic.
- Do not change `payment_plans_for_display`, `#related_sales`, or the plan-vs-sale scope rule.
- Do not render a projected figure for a sale outside a plan, even when one could be guessed.

## Focused verification

```bash
mise exec -- bin/rspec spec/models/sale_payment_plan_spec.rb spec/models/sale/profitability_spec.rb spec/helpers/sale_helper_spec.rb
```

```bash
mise exec -- pnpm exec vitest run app/frontend/pages/Sales/Show/ProfitabilitySummary.test.tsx
```
