# One Row per Economics Card

Supersedes `../20260806T111046Z__sale-profit-single-line/spec.md`, which collapsed only the Sale card. That iteration's decisions stand except where restated below.

## Problem

Reviewing the Sale card's new single line against the Product page surfaced five defects, four of them on the Product card:

- **Three floors.** The Product profit card stacks a profit equation, a second row for Received/Outstanding, and a grey strip carrying `65% margin`. One row is wanted.
- **Labels over nothing.** `MERCHANDISE` renders as a heading with no number. Every money field passes through `format_money` (`app/helpers/formatting_helper.rb:26`), which returns `nil` for blank **and for zero**. A product whose `direct_expenses` equals its `purchase_cost` has a `merchandise_cost` of zero, so the value is nil while the label still renders.
- **The OpEx rate is baked into the label** (`OpEx, 35%`). `financialMetricHints.opEx` already states that OpEx is estimated from the active rates.
- **The arrow between a booked figure and its projection** duplicates what the group gap already says.
- The grey strip is unwanted on every card.

## Goal and approach

All three cards — Sale profit, Product profit, Product invested — become one row of labelled terms sharing one markup shape: no operators, no arrows, no strip, and no term without a number. Cash figures that lived in the strip or the second floor become ordinary terms, grouped together. The two strip captions that carry correctness meaning move into the tooltip of the figure they qualify; the rest of the strip is dropped.

```
PRODUCT PROFIT CARD — one row, groups divided by a short rule
REVENUE *  MERCHANDISE *  OPEX *  │  NET PROFIT *  IN HAND *  │  RECEIVED *
555        201            194     │  160           180        │  575
        (a zero DIRECT, OUTSTANDING or REFUNDED renders nothing at all)

SALE PROFIT CARD — no Received; it only ever repeats Revenue here
REVENUE *  PROJECTED *  │  COGS *  │  OPEX *  PROJECTED *  │  NET PROFIT *  PROJECTED *
377        1 210        │  514     │  132     424          │  −269          273

PRODUCT INVESTED CARD
INVESTED *   UNSOLD STOCK *
201          —
```

No backend changes.

## Approved decisions

- **Approved — a term renders only when its value is non-blank.** One rule across all three cards, replacing the ad-hoc per-term guards. Because `format_money` blanks zeros, this subsumes the `expense_rate_percent !== 0` guard exactly: a zero rate produces blank `business_expenses`, so the OpEx term drops on its own. A group renders only when at least one of its terms does.
- **Approved — the OpEx label is bare.** `OpEx`, not `OpEx, {n}%`. `expense_rate_percent` becomes unused in both components.
- **Approved — no operators on the Product card either.** Keeping `−` / `=` there while the Sale card has none would leave the two inconsistent, and blank-skipping would strand operators (`721 − − 252` when merchandise is zero). `EquationOperator` and `.economics_snapshot__operator` are deleted.
- **Approved — no arrow between paired figures.** The grouped gap — wide between groups, tight within — carries the pairing alone. Reverses the previous iteration's arrow decision.
- **Approved — Outstanding and Refunded are ordinary terms**, grouped together as one trailing cash group so related figures still sit together. Reverses the previous iteration's "cash strip is untouched".
- **Approved — the Sale card does not state Received; the Product card does.** Measured before deciding: across 400 sales, the displayed Revenue and Received are identical in 399 (the exception has Received blank, nothing collected), because an order is billed and collected as one amount and Outstanding already names any gap. Across 300 products they differ in 295 — a product aggregates order value and cash across many sales, so 555 vs 575 and 721 vs 901 are real. Rejected: relabelling Revenue as "Received" on either card, which would print the full order value under a label claiming collected cash.
- **Approved — a semi-transparent rule divides the groups.** Roughly 70 % of a term's height, bottom-aligned, so it separates sections without squaring off the card. Rendered by `EconomicsRow` between groups rather than by a `:not(:last-child)` selector, since the component already knows the group order.
- **Approved — the in-group gap widens** (`gap-4 lg:gap-6`) now that the rule, not spacing alone, carries the section boundary. The between-group gap tightens to `gap-5 lg:gap-7` accordingly; the rule plus the remaining gap difference still keeps a pair reading as a pair.
- **Approved — the two dead `.economics_snapshot__value[data-tone]` rules are removed.** The value span never carried `data-tone`; the `Amount` inside it does, via `.amount[data-tone]`.
- **Approved — the two caveat captions move into tooltips**, appended to the hint of the number they qualify. The Sale `Revenue` tip gains the plan-scope caption when `scope === "plan"`, keeping both variants including "…including charges not yet raised" when a projection exists. The Product `Invested` tip gains "Purchases not received into a warehouse are not counted."
- **Approved — dropped outright:** `65% margin` and `N purchased, N sold, N remaining`. Neither qualifies a figure on its card.
- **Approved — `MetricHint` is inlined back into `MetricLabel` and deleted.** It was extracted in the previous iteration to give a bare figure its own tip. Labelling every figure removed that need, leaving `MetricLabel` as its only consumer — an extraction with no second caller.
- **Approved — one markup shape for all three cards, extracted.** All three cards now render the identical row, so the markup moves into `components/profitability/EconomicsRow` and each card supplies data: an array of groups, each an array of `EconomicsTerm`. Three consumers is proven reuse, not anticipated reuse. `EconomicsRow` owns blank-skipping, empty-group dropping, and the `result` tone; the cards own which figures they state and in what order.
- **Approved — a `refunded` hint is added to `financialMetricHints`.** Refunded was strip prose before and had no hint entry, though the glossary has carried a `refunded` entry all along. Adding one entry for a newly-labelled metric is not a change to an existing hint.
- **Approved — every term is addressed in tests by `data-testid="metric-<anchor>"`.** Anchors are unique within a card and mean the same metric across cards, and several terms share the label `Projected`, so label text cannot address them.
- **Approved — `--grouped` folds into the base equation class.** Every card now uses groups, so the modifier has no non-grouped counterpart.

## Contracts

### Domain Contract

- **Owner and boundary:** `Product::Profitability#profitability` owns `counted_sales_total`, derived from the same `items` the equation aggregates — the same placement and reasoning as the neighbouring `has_sale_items`, so the frontend never re-derives either. `product_profitability_props` passes it through unchanged.
- **State:** Derived at read time from `profitability_sale_items`; nothing is persisted or cached.
- **Invariants:** It counts distinct `sale_id`s, so an order carrying several lines of one product counts once. It is 0 for a product that has never sold, which is consistent with `has_sale_items` being false.
- **Tests:** `spec/models/product/profitability_spec.rb` owns the count, including the multi-line-single-order case and the never-sold case; `spec/helpers/product_helper_spec.rb` owns the prop passthrough.

No other Rails change: `Sale::Profitability`, `SalePaymentPlan#profitability` and `sale_profitability_props` keep their current payloads.

### Frontend Contract

- **Owner and boundary:** `components/profitability/EconomicsRow` owns the row: its public contract is `groups: EconomicsTerm[][]`, and it decides what renders from blankness alone. `Sales/Show/ProfitabilitySummary` and `Products/Show/ProductEconomicsDashboard` own which figures their card states, in what order, and how each hint is composed; neither owns markup. `MetricLabel` owns a label and its tip. Rails remains the authority for every figure.
- **State:** Inertia props are the only authoritative source. Tip open state belongs to `TipMark`. Whether a term renders, whether a group renders, the composed COGS / Revenue / Invested hint text, and the profit tone are deterministic values derived from the record.
- **Invariants:** React performs no money arithmetic — every displayed figure is a backend string, and a blank string means zero or absent, decided by `format_money`. No label renders without a value beneath it. No operator or arrow glyph renders in any card. Every figure carries its own label and its own glossary-linked tip. A divider appears only between two groups that both render, never leading or trailing.
- **Commands and transitions:** Both cards are read-only and have no write flow. Their transitions are render-time branches on blankness: a blank value drops its term, an all-blank group drops itself, and the card-level guards (`profitability === null`, blank `expected_revenue`, `hasRecordedCosts` false, `has_sale_items` false, blank `invested_total`) still decide whether a card renders at all.
- **Inspection and recovery:** Every term's tip links to its glossary entry. The two caveats that used to be visible captions stay reachable from the tip of the figure they qualify, so the payment-plan scope and the unreceived-purchase exclusion are never silently lost.
- **Tests:** Component tests at the rendered-label-and-figure seam. Terms are addressed by their `metric-<anchor>` test id, since several share the label `Projected`. An operator is detected as an element whose *entire* text is a glyph — a negative amount reads `−953`, so a plain substring check would confuse the two.

## Approved decisions — hint scope

Reviewing the tips raised the question they could not answer: is a figure a total, a per-sale average, or a median? Every money figure in the app is a **total** — a sum, never an average. The only per-unit metric, `variantTheoreticalProfit`, already says "Per unit:". But no hint said so, and one hint text served three different scopes: `revenue` was reused verbatim on the Sale card (one order), the sale-items table (one line), and the Product card (every sale of the product), while reading "The full value of these orders" — plural on a single-order card. `directExpenses` served four surfaces the same way.

- **Approved — definitions are scope-neutral; the scope is a closing sentence.** Each entry in `financialMetricHints` reads correctly at any scope, and each call site appends a note naming what was added up. Chosen over forking a hint per surface, which would have contradicted "use one consistent term for each business concept" and tripled the constants. Base texts lost their scope-bearing words: "these orders" → "billed", "from the customer" → dropped.
- **Approved — the Product card names the count.** `Product::Profitability` returns `counted_sales_total`, the number of **distinct sales** the figures were summed over — not sale items, because one order can carry several lines of the same product and a reader counts orders. Hints read "Totalled across all 12 sales of this product.", or "the single sale" at one. This is the one Rails change in this iteration.
- **Approved — the invested card claims no sale count.** Invested and Unsold stock come from purchased units, not from sales; attributing them to a sale count would name the wrong thing.
- **Approved — the plan scope note drops "including charges not yet raised".** The old caption said it, but it was never true of the terms it sat under: Revenue and COGS count what has been billed and spent. Appending it to every term made that plainly wrong on COGS and Net Profit. It is true only of the Projected terms, and `projectedTotal`, `projectedOpEx` and `projectedNetProfit` each already state it in their own hint.
- **Approved — scope notes:** `For this order.` / `For this line of the order.` / `For this purchase.` / `For this purchase item.` / `For this sale item.` / `Totalled across every order in this payment plan.` / `Totalled across all N sales of this product.`

## Boundaries and non-goals

- Rails changes are limited to `counted_sales_total`. Dead props are recorded under Follow-up rather than removed here.
- Do not rename `Direct expenses` on the Purchase show, PurchaseItem show, SaleItem show, or Sale index pages.
- Do not change glossary terms, definitions, examples, or anchors.
- Do not change existing `financialMetricHints` entries; the conditional caveats are composed at the call site. Adding the missing `refunded` entry is in scope.
- Do not restyle the cards' border, background, or radius.

## Testing decisions

- `ProfitabilitySummary.test.tsx` and `ProductEconomicsDashboard.test.tsx` are both substantially rewritten: the money-row, strip, and arrow structures they assert on no longer exist.
- New coverage on both dashboards: a zero-valued term renders neither label nor value; `OpEx` carries no percentage; no `−`, `=` or `→` glyph renders anywhere in a card; each caveat appears in its tip and nowhere else.
- `MetricLabel.test.tsx` is again the untouched guard on the inlining.
- Stale tests, from card changes the user made by hand — these are out-of-date assertions, not regressions:
  - `Sales/Show/PaymentSummary.tsx` is intentionally unrendered. Delete it, delete `PaymentSummary.test.tsx`, and delete the three `Show.test.tsx` assertions expecting `getByRole("region", { name: "Payment" })`. Keep "shows the profit summary as a card of its own", narrowed to the profit card.
  - `Sales/Show/Details.test.tsx` asserts the plan's payment list sits inside the totals `dl.card`; it now lives in `PlanProgressCard` in the right-hand column. Retarget the containment assertion; the link, href and current-sale assertions still hold.
- The 46 RSpec failures are environmental, not code: the test database holds leftover rows from an aborted `rails runner` against `RAILS_ENV=test` on 2026-08-04 — two products with `slug = NULL`, plus a sale, sale_item, purchase, customer, franchise and supplier. `use_transactional_fixtures` is on, so specs do not leak; these predate the run. 19 failures are `product_path(nil)` 500s from the null slug, 21 are global-count assertions off by exactly the leaked rows, 4 are `.first` picking the leaked sale, 2 are an FK violation on `Sale.delete_all`. None touch profitability. Resolved by `bin/rails db:test:prepare`.

## Open proposals

- **Proposal — dead props:** `margin_percent`, `purchased_units_total`, `sold_units_total`, `remaining_units_total` and `expense_rate_percent` become unused in the frontend but are still serialized by `product_profitability_props` (`app/helpers/product_helper.rb:201`) and `sale_profitability_props` (`app/helpers/sale_helper.rb:147`). Removing them would turn a frontend-only change into a backend one with request-spec churn. Not approved for this iteration.
- **Proposal — `product_path(product.slug)`:** `app/helpers/dashboard_helper.rb:28` and `:57` are the only two call sites passing the slug instead of the record, so a null-slug row 500s the dashboard instead of falling back to an id URL. Not approved for this iteration.
- **Proposal — `Sale.delete_all`:** `spec/controllers/sales_controller_spec.rb` skips `dependent:` handling and breaks on any pre-existing sale with items. Not approved for this iteration.
