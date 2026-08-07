# Collapse the Sale Profit Summary into One Line

## Problem

The profit summary card on the Sale show page renders two stacked equation rows. The booked row reads `Revenue − Merchandise cost − Direct expenses − OpEx = Net Profit`; the projected row reads `Projected total − COGS − OpEx = Projected Net Profit`.

Two costs follow from that shape:

- The `−` and `=` operators occupy horizontal space to restate arithmetic the labels already imply.
- The cost column prints the same number twice. `merchandise_cost` and `purchase_cost` differ only by `direct_expenses`, and `Sale::Profitability` computes both profits against `purchase_cost`, so the two rows repeat one cost figure alongside parallel Revenue-ish, OpEx-ish, and Profit-ish terms.

Several labels are also longer than the dense metric columns warrant — `Merchandise cost`, `Projected Net Profit`, `Profit in hand`, `Unsold stock value`.

## Goal and approach

Render one row of four groups with no operators. A group pairs a booked figure with its projected counterpart, arrow between them, each under its own label; the cost group carries a single figure because it is identical on both bases. Move the merchandise and direct-expense breakdown into the cost column's existing hover tip. Shorten the remaining long labels on the Product economics dashboard so both cards speak one vocabulary, and reconcile the shortened labels with the glossary through the `interfaceLabel` field that already exists for that purpose.

```
REVENUE *   PROJECTED *   COGS *   OPEX, 30% *   PROJECTED *   NET PROFIT *   PROJECTED *
326     →   403           279      98        →   121           −51       →   2
```

Backend profitability payloads are unchanged. `merchandise_cost` and `direct_expenses` stay on `SaleProfitabilityRecord`; only their presentation moves.

## Approved decisions

- **Approved — arithmetic basis:** `purchase_cost` (COGS) is the single cost figure for both bases. `Sale::Profitability` already derives `expected_final_profit` and `projected_final_profit` from `purchase_cost`, and defines `merchandise_cost = purchase_cost − direct_expenses`, so `Revenue − COGS − OpEx = Net Profit` holds exactly on both rows. Merging the cost column loses no precision.
- **Approved — pairing format:** A booked figure and its projected counterpart sit side by side with an arrow between them. The arrow was chosen over a `Booked / Projected` prefix pair and over a muted `(403 projected)` suffix.
- **Approved — every figure carries its own label:** A projected figure is labelled `Projected` in the label row and keeps its own hover tip and glossary link. Two figures that mean different things are never left under one label, and no tip mark is ever attached to a number — marks belong in the label row. Rejected: one label whose tip explains both sides, which would have made the projected term's glossary entry unreachable and left the right-hand figure unnamed.
- **Approved — the projected label is bare:** `Projected`, not `Projected total` / `Projected OpEx` / `Projected Net Profit`. It sits under its own figure and beside the term it projects, so the repeated noun adds length without adding meaning. Its glossary anchor still resolves to the full term.
- **Approved — no arrow without a projection:** When `projected_final_profit` is null (a lone Sale, or a plan carrying no contract value) every term renders alone.
- **Approved — COGS is never paired:** The cost figure is identical on both bases, so it appears once, with no `Projected` counterpart. This is the structural expression of the no-duplicates requirement.
- **Approved — grouping is explicit, not inherited:** A booked figure, its arrow, and its projected figure form one group. The card is only as wide as its contents, so `justify-between` has no slack to spend; the gap between groups is set explicitly and must exceed the gap inside a group, or `1 210` and `514` read as one pair.
- **Approved — breakdown moves to the tip:** The COGS hover tip appends the live merchandise and direct-expense figures to `financialMetricHints.cogs` when `direct_expenses` is present. This is the only remaining appearance of `merchandise_cost` and `direct_expenses` on the Sale page. Chosen over dropping the breakdown entirely and over pairing merchandise against COGS.
- **Approved — hint composition happens at the call site:** The COGS hint interpolates record figures, so it is built where the record is in hand rather than added as a static entry to `financialMetricHints`.
- **Approved — cash strip is untouched:** Received, outstanding, refunded, and the scope caption stay in their own strip below the line. Chosen over folding them into the single row.
- **Approved — current behavior:** Two `.economics_snapshot__equation` rows separated by the `--projected` divider, eight labelled terms, seven operators, and a `sale-profitability-projected-row` test id.
- **Approved — proposed behavior:** One `.economics_snapshot__equation` row holding four groups, up to seven labelled terms, no operators, no projected-row test id, and a `sale-profitability-<anchor>` test id per term.
- **Approved — Sale strip labels are already short enough:** `Revenue`, `COGS`, `OpEx, {n}%`, and `Net Profit` stay verbatim. The merge itself removes the two long labels that prompted the request.
- **Approved — Product dashboard label shortening:** `Merchandise cost` → `Merchandise`, `Direct expenses` → `Direct`, `Profit in hand` → `In hand`, `Unsold stock value` → `Unsold stock`. Anchors, hints, and values are unchanged.
- **Approved — shortening is a property of the economics-snapshot cards:** `Direct expenses` also labels detail rows on the Purchase show, PurchaseItem show, SaleItem show, and Sale index pages. Those are prose-width detail labels with room to spare and are left alone.
- **Approved — glossary reconciliation:** Each shortened label's glossary entry gains `interfaceLabel`, the field already carried by `GlossaryEntry` and used today by the `debt` entry. Terms, definitions, and examples are unchanged.
- **Approved — `MetricHint` exists but this page does not use it:** The tip body was extracted from `MetricLabel` into `MetricHint` for a bare figure's tip. Labelling every projected figure removed the need for it here; `MetricLabel` still composes it, and its props and rendered output are unchanged.

## Contracts

### Domain Contract

Not applicable — no model, controller, job, route, or persistence changes. `Sale::Profitability` and `SalePaymentPlan#profitability` keep their current payloads, and the Sale show props are already sufficient.

### Frontend Contract

- **Owner and boundary:** `Sales/Show/ProfitabilitySummary` owns the Sale profit line and consumes one `SaleProfitabilityRecord | null` prop. `Products/Show/ProductEconomicsDashboard` owns the Product economics cards. `components/profitability/MetricHint` owns the hover-tip body and its glossary link; `MetricLabel` owns a label plus that tip and depends on `MetricHint`, not the reverse. Rails remains the authority for every figure and for the OpEx rate.
- **State:** Inertia props are the only authoritative source. Tip open state belongs to `TipMark`. Whether a group is paired, whether the COGS group renders, whether the OpEx group renders, the composed COGS hint text, and the profit tone are all deterministic values derived from the record.
- **Invariants:** React performs no money arithmetic — every displayed figure is a backend string. A paired group renders exactly two labelled figures and one arrow, or one labelled figure and none. Every figure has a label; no figure carries a tip mark of its own. COGS renders at most once per card. `Revenue − COGS − OpEx` reconciles to `Net Profit` and `Projected total − COGS − Projected OpEx` reconciles to `Projected Net Profit`, both enforced by the backend and pinned by tests rather than recomputed in the component.
- **Commands and transitions:** The card is read-only; it has no write flow. Its transitions are render-time branches: null profitability and cost-free records render nothing; a null `projected_final_profit` drops every arrow and every `Projected` term; a zero `expense_rate_percent` drops the OpEx group; a blank `purchase_cost` drops the COGS group; a blank `direct_expenses` drops the breakdown sentence from the COGS tip.
- **Inspection and recovery:** Every term keeps its hover tip and glossary link, so any figure's definition stays one hover away, and a `Projected` label points at its own glossary entry rather than being folded into the booked term's explanation. The arrow is `aria-hidden`; the labels carry the meaning, so the pairing survives without it.
- **Tests:** Component tests own this work at the narrowest user-visible seam — the rendered labels and figures, not the props behind them. Both reconciliations stay pinned as arithmetic read back off the DOM. `MetricLabel.test.tsx` is the unchanged guard proving the `MetricHint` extraction altered no output.

## Boundaries and non-goals

- Do not change `Sale::Profitability`, `SalePaymentPlan#profitability`, `Product::Profitability`, controllers, routes, or serializers.
- Do not remove `merchandise_cost` or `direct_expenses` from `SaleProfitabilityRecord`; the COGS tip consumes them.
- Do not rename `Direct expenses` on the Purchase show, PurchaseItem show, SaleItem show, or Sale index pages.
- Do not change glossary terms, definitions, or examples; only add `interfaceLabel`.
- Do not remove `.economics_snapshot__operator` or `.economics_snapshot__equation--secondary` — the Product dashboard still uses both.
- Do not restyle the cash strip, the Product invested-total card, or the Product money row.

## Testing decisions

- **`Sales/Show/ProfitabilitySummary.test.tsx`** is rewritten. The `sale-profitability-projected-row` test id disappears, so the `describe("the projected row")` block and the `projectedRow()` / `termAmountWithin()` helpers are reworked. Three terms share the label `Projected`, so terms are addressed by their `sale-profitability-<anchor>` test id rather than by label text.
- New coverage: COGS renders once with no `Projected` counterpart when a projection exists; no arrows and no `Projected` terms render when `projected_final_profit` is null; each `Projected` label carries its own tip resolving to its own glossary anchor; the COGS tip names the merchandise and direct-expense split when `direct_expenses` is set and omits that sentence when it is null; `Merchandise cost` and `Direct expenses` no longer appear as labels. The existing worked example (300 / 700 / 45 / 153 at 15 %) is adapted rather than replaced.
- Carried over unchanged: null profitability, no recorded costs, negative-profit tone on both label and value, cash strip contents, and scope caption wording.
- **`Sales/Show.test.tsx`** asserts `Direct expenses` inside the summary card to prove the card renders outside the payment card. Retarget that assertion to a label that survives, such as `COGS`.
- **`Products/Show/ProductEconomicsDashboard.test.tsx`** updates its label assertions to the shortened labels.
- **`components/profitability/MetricLabel.test.tsx`** is not modified. It must pass untouched.
- Focused verification is Vitest over the touched paths plus `tsc --noEmit`, `oxlint`, and `oxfmt --check`. The coordinating task runs the full RSpec and Vitest gate after every ticket lands.
- Visual confirmation: a Sale on a payment plan carrying a contract value, checked for horizontal fit at `lg`, `overflow-x-auto` degradation on mobile, and arrow contrast in dark mode.

## Open proposals

None.
