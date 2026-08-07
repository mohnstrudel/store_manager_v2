# 15. Separate money in hand from money still coming on the product card

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

The product card was asked to answer three questions: how much has gone into this product, how
much has it sold for so far, and how much is still to come. It answers the first, and buries the
other two as small print under the profit equation — the headline revenue figure blends collected
and uncollected money into one number.

Promote the split. Show what has been collected and what is still owed as figures in their own
right, add the profit on money actually received beside the profit on the full order value, and
show the cash still tied up in unsold stock next to the amount invested.

Two related repairs belong here. The product equation folds ad-hoc purchase expenses invisibly
into cost of goods — the same defect already fixed on the sale page — so split them out and let
both pages read alike. And several serialized values are read by nothing at all; remove them
rather than leave a payload that implies a feature.

## Acceptance criteria

- [x] The card states money collected and money still owed as distinct figures, not as small print.
- [x] The card states profit on money received alongside profit on the full order value, and the two are distinguishable.
- [x] The card states the cost still tied up in unsold stock, next to the total invested.
- [x] The card states how many units were purchased, sold, and remain.
- [x] Ad-hoc purchase expenses appear as their own term rather than hidden inside cost of goods, and the product equation reconciles exactly, deducting them once.
- [x] The product and sale equations use the same terms in the same order for the same concepts.
- [x] Each figure is omitted cleanly when the server has nothing to report, without leaving a stray label or a bare zero.
- [x] Values that no component reads are gone from the server response and the types.
- [x] Whether the product counts as having sales is decided by one source, not two that can disagree.

## Anchors

- `app/models/product/profitability.rb:18-50` — `#profitability` returns `item_cost_total`,
  `shipping_cost_total`, `extra_expenses_total`, `purchase_cost` (their sum), `business_expenses`,
  `realized_profit`, `expected_final_profit`, `margin_percent`, `status`. `#inventory_economics`
  (`:52-63`) returns `purchased_units`, `sold_units`, `remaining_units`, `invested_total`,
  `remaining_inventory_cost`.
- `app/models/sale/profitability.rb:20-25` — the pattern to copy: `direct_expenses` is reported
  beside `purchase_cost`, and `merchandise_cost` is derived as `purchase_cost - direct_expenses`
  so the four terms sum to the profit without charging the expenses twice.
- `app/helpers/product_helper.rb:205-234` — `#product_profitability_props`, 21 keys.
- `app/helpers/sale_helper.rb:154-180` — `#sale_profitability_props`; it also emits
  `received_percent` and `refunded_percent`, which live on the shared type and must go in the same
  edit.
- `app/frontend/types/profitability.ts` — `ProfitabilitySummaryRecord`, shared by Products and
  Sales. `app/frontend/pages/Products/types.ts:116-129` — `ProfitabilityRecord` extends it.
- `app/frontend/pages/Products/Show/ProductEconomicsDashboard.tsx` — equation at `:68-104`,
  invested card at `:48-66`, cash strip at `:148-188`.
- `app/frontend/pages/Products/Show.tsx:49` — `salesCount = active_sales.length +
  completed_sales.length`, built from the `for_history` scope, and passed as `hasSales` at `:72`.
  The backend equation aggregates `profitability_sale_items`
  (`app/models/product/profitability.rb:11-16`) over `Sale.active_status_names +
  Sale.completed_status_names` — a different query. These can disagree; the gate must read the
  backend figure.
- `app/frontend/components/profitability/metricLabels.ts` — hints; each new term needs one.
- `app/frontend/pages/Products/test/factories.ts:114-126` — `makeProfitability`.

## Renames and removals

| Key | Action |
|---|---|
| `extra_expenses_total` | rename to `direct_expenses`, render as its own term |
| `realized_profit` | render — profit on money received |
| `remaining_inventory_cost` | render — cost tied up in unsold stock |
| `purchased_units_total`, `sold_units_total`, `remaining_units_total` | render as a counts line |
| `received_revenue`, `outstanding_revenue` | promote out of the strip into figures of their own |
| `item_cost_total`, `shipping_cost_total` | remove from props and types |
| `received_percent`, `refunded_percent` | remove from the **shared** type, so from both helpers |

Labels come from the glossary in ticket 17; ticket 18 enforces them. Use the canonical wording
here rather than inventing an interim label.

## Non-goals

- Do not change how `invested_total` is computed — it deliberately sums every purchased unit
  rather than adding sold-unit cost to unsold-stock cost, because a unit on a cancelled sale would
  fall through both halves.
- Do not change the admin-only gate on product profitability.
- Do not touch the variants table; ticket 16 owns it.

## Focused verification

```bash
mise exec -- bin/rspec spec/models/product/profitability_spec.rb spec/helpers/product_helper_spec.rb spec/helpers/sale_helper_spec.rb
```

```bash
mise exec -- pnpm exec vitest run app/frontend/pages/Products/Show/ProductEconomicsDashboard.test.tsx app/frontend/pages/Sales/Show/ProfitabilitySummary.test.tsx
```
