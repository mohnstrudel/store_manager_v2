# 14. Show the final price where the price is

Spec: ../spec.md
Status: done
Blocked by: 10

## What to build

A deposit order shows a total of 300 when the deal is worth 1 020. The contract value is known and
is displayed — in the page header and again in the payment card, worded differently in each — but
never beside the number it corrects. A reader looking at the total has no reason to scroll for the
figure that changes its meaning.

Put the contract value directly after the total. And show it for instalment plans too: today only
deposits print it in the compact marker, so a customer paying in four or eight charges sees a
position in the plan and never a final price.

## Acceptance criteria

- [x] The sale details show the contract value immediately after the order total.
- [x] The field is omitted when there is no contract value, and when two plans on the same order give different ones.
- [x] The compact plan marker prints the contract value for instalment plans and payment-terms plans, not only for deposits.
- [x] The contract value therefore appears on the sales list, the sale page header, and the customer's sales table, with no change to those three files.
- [x] The order total keeps its own meaning and value; it is not replaced or recomputed.

## Anchors

- `app/frontend/pages/Sales/Show/Details.tsx:40` — `<Field className="fit font-mono" label="Total"
  value={sale.total} />`. The new field goes immediately after it, before `Discount` (`:41`).
  `sale.payment_plans` is already on the record and carries `projected_total` per plan.
- `app/frontend/components/PaymentPlanMarker.tsx:47-60` — `planLabel`. The deposit branch
  (`:48-53`) builds `projection` and appends it; the two branches below (`:55-59`) do not. Give
  them the same treatment.
- `app/frontend/pages/Sales/Index/Table.tsx:62`, `app/frontend/pages/Sales/Show.tsx:19-27`,
  `app/frontend/pages/Customers/components/Sales.tsx:69` — the three marker call sites. They should
  need no edit; the change lands through the shared component.
- `app/helpers/sale_helper.rb:229-231` — `#format_plan_money(value, currency)` wraps `format_money`
  with a currency unit, so plan money renders as `1 020 EUR` while `sale.total` renders unitless.
  The mismatch is real and is ticket 18's to settle; do not change it here.

## Worked example for the tests

A 30 % deposit on a 1 020 deal: details show `Total 300` followed by `Projected total 1 020 EUR`.
A four-part instalment plan with two collected: the marker reads
`Payment plan · 2 of 4 collected · Projected total 1 020 EUR`.

## Non-goals

- Do not change `sale.total`, `payment_pie_total`, or the payment progress bar's price basis.
- Do not add the field to the sales list table — the marker already carries it there.
- Do not reconcile the currency-unit inconsistency; ticket 18 owns it.

## Verification

All gates from `AGENTS.md`, each through `mise exec --`:

```bash
mise exec -- bin/rspec --format progress --color
```

```bash
mise exec -- pnpm exec vitest run
```

```bash
mise exec -- pnpm exec tsc --noEmit && mise exec -- pnpm exec oxlint app/frontend && mise exec -- pnpm exec oxfmt --check app/frontend
```
