# 18. Rename money labels to match the glossary

Spec: ../spec.md
Status: done
Blocked by: 11, 12, 14, 15, 16, 17

## What to build

The app names the same amount several ways and uses one name for several amounts. The worst case
sits inside a single table: one column shows a price somebody typed into a form, the next shows
what was actually spent, and both are headed with almost the same words. Elsewhere one word labels
money owed to a supplier, a count of missing units, and a count of products — in tables a reader
looks at side by side.

Now that the glossary defines the canonical terms, make the interface use them. This ticket
changes wording only: no figure, formula, query or layout changes.

Run it last. Every earlier ticket in this wave adds labels, and those labels should be renamed
once, here, rather than each ticket guessing.

## Acceptance criteria

- [x] No word in the interface labels two different quantities on the same screen or on screens a reader compares.
- [x] A hand-entered reference price and actual money spent are named so that neither can be mistaken for the other.
- [x] Money owed to a supplier, a shortfall in units, and a count of affected products each have their own name.
- [x] Money collected is called the same thing everywhere, including where it is currently a column heading and a caption on the same page.
- [x] Every tooltip describes what its figure actually is on the page it appears on.
- [x] Money is displayed with a currency unit consistently, or without one consistently — not both.
- [x] Every renamed label matches its glossary entry exactly.
- [x] Nothing changes except wording: no arithmetic, no query, no layout, no visibility rule.

## Collisions to resolve first

One word currently meaning two things:

| Where | Now | Becomes | Why |
|---|---|---|---|
| `Products/Show/ProductVariants.tsx:28` | `Purchase Cost` | **List Cost** | a hand-entered catalog price, sitting next to actual spend |
| `Products/components/Form/VariantFields.tsx:147` | `Purchase Cost` | **List Cost** | the form field that writes it |
| `Products/Show/ProductVariants.tsx:32` | `Total Purchase Cost` | **Total Landed Cost** | actual spend, so it must not echo the label above |
| `Dashboard/Debts.tsx:69` | `Debt` over `debt.debt` | **Unit Shortfall** | the value is `sold_qty − purchased_qty`, a unit count, not money |
| `Dashboard/Index.tsx:120` | `Amount` over `debt.debt` | **Unit Shortfall** | same unit count, third name |
| `Dashboard/Index.tsx:114` | `Sales Debt` with `sale_debts_count` | **Products Short** | the value is a count of products, not an amount |
| `Dashboard/Debts.tsx:96` | `Cost` over `purchase.item_price` | **Unit Price** | a per-unit price under a bare "Cost" |
| `Sales/Index/Table.tsx:28`, `Sales/Show/Items.tsx:56` | `Paid` | **Received** | same field as the caption saying "received" on the same page |

Note on the suppliers table (`Dashboard/Index.tsx:152-167`): `Total Cost` (`:157`), `Paid` (`:159`)
and `Debt` (`:160`) are internally consistent — cost minus paid equals debt — so `Debt` there is
genuinely supplier debt and keeps its meaning. Rename the section title `Suppliers Debt` (`:152`)
to **Supplier Debt** for grammar, and leave the three column headings alone apart from aligning
`Total Cost` with the glossary's purchase wording. Do **not** rename `Total Cost` to anything
containing "debt": it is what was bought, not what is owed.

## Synonyms to converge

- Sale page `Merchandise` (`Sales/Show/ProfitabilitySummary.tsx`) → **Merchandise cost**, matching
  its prop and the glossary.
- ExpenseRates feature speaks four dialects: `OpEx Rates` in the page title and navigation,
  `Expense Rates` in the table heading (`ExpenseRates/components/Table.tsx:18` and `:35`) and the
  empty state, `OpEx rate` in flash messages, `Rate (% of revenue)` in the form. Settle on **OpEx
  Rates** and the glossary's phrasing throughout.
- `app/frontend/components/profitability/metricLabels.ts:15` — the `netProfit` hint reads *"Revenue
  minus COGS and estimated OpEx"*. True on the product page; false on the sale page, which
  subtracts merchandise and direct expenses separately. Split it into two accurate hints, and add
  hints for every term tickets 11 and 15 introduce.
- `Sales/Index/Table.tsx:101` prepends a literal `$` to a value from `format_money`, which emits no
  unit (`app/helpers/formatting_helper.rb:26-38`), while plan money goes through
  `format_plan_money` (`app/helpers/sale_helper.rb:229-231`) and carries a real currency code.
  Drop the hardcoded `$` and settle the unit question once for the whole app.

## Non-goals

- No behaviour change of any kind. If a rename appears to require a formula or query change, the
  rename is wrong — stop and record it rather than changing the number.
- Do not rename backend methods, columns or prop keys; this ticket is user-visible text.
- Do not touch `Purchase#debt` or the dashboard debt query.

## Focused verification

This must return nothing:

```bash
rg -n "Purchase Cost|Sales Debt|Suppliers Debt" app/frontend
```

```bash
mise exec -- pnpm exec vitest run app/frontend/pages/Products/Show/ProductVariants.test.tsx app/frontend/pages/Products/components/Form/VariantFields.test.tsx app/frontend/pages/Dashboard/Index.test.tsx app/frontend/pages/Dashboard/Debts.test.tsx app/frontend/pages/Sales/Index.test.tsx app/frontend/pages/Sales/Show/Items.test.tsx app/frontend/pages/ExpenseRates/Index.test.tsx app/frontend/pages/ExpenseRates/components/Form.test.tsx app/frontend/pages/ExpenseRates/components/Table.test.tsx app/frontend/components/profitability/MetricLabel.test.tsx
```
