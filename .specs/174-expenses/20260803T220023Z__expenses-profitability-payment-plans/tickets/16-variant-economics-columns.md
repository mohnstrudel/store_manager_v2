# 16. Fix the variants economics columns

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

The variants table gained two economics columns, and all three of their problems are the kind a
reader hits without ever knowing why the numbers look wrong.

A variant whose purchases add up to nothing hides both columns — including a profit figure that
was calculated fine — because the decision to show them keys off the wrong value, and money
formatting turns zero into nothing.

The two columns sit side by side, both right-aligned money, but one is a total across every unit
purchased and the other is a figure per single unit. The only thing saying so is a hover tooltip,
which a touch or keyboard user never sees.

And the column will never add up to the total invested shown at the top of the same page, because
a purchase booked against the product rather than a specific variant counts in one and not the
other. That is a defensible boundary — such a purchase genuinely has no variant to charge — but it
has to be stated, not left as an unexplained gap.

## Acceptance criteria

- [x] The economics columns appear whenever either of their two values exists, not only when the total does.
- [x] A variant with real purchases whose costs total zero still shows its calculated profit figure.
- [x] Which column is a total and which is per unit is legible from the column headings themselves, not only from a hover tooltip.
- [x] The explanatory hints reach touch and keyboard users the same way every other economics label in the app does.
- [x] The table states that purchases booked against the product rather than a variant are not counted in the column, so the reader knows why it does not match the invested total.

## Anchors

- `app/frontend/pages/Products/Show/ProductVariants.tsx:16` —
  `const showsEconomics = variants.some((variant) => variant.total_purchase_cost !== null)`. This
  is the faulty gate. The two headers are at `:30-39` with `title={TOTAL_PURCHASE_COST_HINT}` and
  `title={THEORETICAL_PROFIT_HINT}` (constants at `:9-12`); the cells are at `:67-76`.
- `app/helpers/formatting_helper.rb:26-38` — `format_money` returns `nil` for blank **and** for
  zero. This is why the gate misfires and why every money prop is `string | null`.
- `app/helpers/product_helper.rb:132-133` — `total_purchase_cost` and `theoretical_profit`;
  `#variant_theoretical_profit` (`:141-149`) needs only `units > 0` and a selling price, so it can
  produce a value where the cost total formats to `nil`.
- `app/models/product/sales_history.rb:34-46` — `#variant_purchase_cost_totals` filters
  `purchases: {variant_id: variants.select(:id)}`.
  `app/models/product/profitability.rb:67-72` — `#inventory_purchases` ORs in
  `Purchase.where(product_id: id, variant_id: nil)`. That difference is the gap to name.
- `app/frontend/components/profitability/MetricLabel.tsx` — the accessible hint component used by
  every other economics header (`Sales/Show/Items.tsx:63`,
  `Products/Show/ProductEconomicsDashboard.tsx:83`). Use it here too.
- `app/frontend/components/profitability/metricLabels.ts` — where the hint text belongs, rather
  than as local constants in the component.

## Worked example for the tests

A variant with two purchase items whose landed costs are both zero, a selling price of 200, and a
15 % OpEx rate: `total_purchase_cost` formats to `null`, `theoretical_profit` is
`200 − 0 − (200 × 0.15)` = **170.00**. Today both columns vanish; after this ticket both render.

## Non-goals

- Do not change `variant_purchase_cost_totals` to include product-level purchases — the exclusion
  is the approved boundary, and the fix is to state it.
- Do not change `#variant_theoretical_profit`'s formula or its per-unit basis.
- Do not rename the columns in this ticket; ticket 18 applies the glossary names.

## Focused verification

```bash
mise exec -- bin/rspec spec/helpers/product_helper_spec.rb
```

```bash
mise exec -- pnpm exec vitest run app/frontend/pages/Products/Show/ProductVariants.test.tsx app/frontend/components/profitability/MetricLabel.test.tsx
```
