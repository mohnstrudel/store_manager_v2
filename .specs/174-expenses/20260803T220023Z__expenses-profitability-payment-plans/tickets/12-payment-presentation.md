# 12. Present a follow-up charge as a Payment, not a Sale

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

When a customer pays in instalments, every charge is stored as its own order. The app therefore
presents the second instalment as a complete sale: titled "Sale", with a products table, shipping
and billing panels it has no data for, and a profitability card that charges the whole deal's cost
of goods against one payment.

Make these pages read as what they are. Name them Payments, and give them only the facts they
actually hold. Anyone who wants the full picture goes to the original order, which is one click
away and already linked.

Omit by not sending the data, not by hiding it. A page that renders nothing while still receiving
the props is a page that claims not to know something it was told.

## Acceptance criteria

- [x] A charge that is part of a payment plan and is not the plan's originating order is titled "Payment", with the same identifier it shows today.
- [x] The same naming appears wherever a single order is named: the page header, the sales list, and the customer's sales table.
- [x] Whether a charge is a follow-up payment is decided in one place on the server; the frontend does not derive it a second time.
- [x] A payment page shows no profit summary, no products table, and no shipping or billing panel.
- [x] A payment page shows no discount and no shipping amount — it has neither.
- [x] A payment page still shows its status, customer, note, total, identifiers and dates, and still shows its payment card.
- [x] The omitted values are absent from the server's response, not merely unrendered, and a request spec proves it.
- [x] The originating order's page is unchanged in every respect.

## Anchors

- `app/frontend/components/PaymentPlanMarker.tsx:62-64` — `isLaterPayment(plan)` is
  `!plan.is_origin_sale && plan.sale_part_number != null`. This is the predicate to lift to the
  server; `isFollowUpPayment` (`:25-27`) is its any-plan form and has callers, so replace its body
  with the new prop rather than deleting the export blindly.
- `app/helpers/sale_helper.rb` — `#sale_base_props` (from `:233`) is shared by listing and showing
  props and is where the new flag belongs. `#sale_showing_props` (`:33-60`) builds
  `profitability:`, `sale_items:`, `shipping_address:`, `billing_address:`,
  `billing_differs_from_shipping:`, `discount_total:` and `shipping_total:` — these are the keys to
  withhold. `#sale_listing_props` (`:4-12`) needs the flag but keeps its own shape.
- `app/frontend/pages/Sales/Show.tsx:50-70` — `SaleTitle`, three branches (Shopify, Woo, bare id),
  each hardcoding the word `Sale`. Page composition is `:31-45`.
- `app/frontend/pages/Sales/Show/Details.tsx:24-98` — three cards: the `dl` at `:26-43` (keep,
  minus `Discount` `:41` and `Shipping` `:42`), the address card at `:45-87` (remove), and the
  identifiers card at `:89-98` (keep).
- `app/frontend/pages/Sales/Index/Table.tsx` and `app/frontend/pages/Customers/components/Sales.tsx`
  — the two lists that name a single order.
- `app/frontend/pages/Sales/types.ts` — `SaleShowRecord` and the listing record gain the flag; the
  withheld keys must admit their absence.

## Page composition after this ticket

| Block | Originating order | Follow-up payment |
|---|---|---|
| Profit summary | shown | **removed** |
| Payment card | shown | **shown** — the point of the page |
| Products table | shown | **removed** |
| Details: status, customer, email, customer shop id, note, total | shown | shown |
| Details: discount, shipping | shown | **removed** |
| Details: shipping and billing panels | shown | **removed** |
| Details: id, shop created, shop updated, order shop id | shown | shown |

## Non-goals

- Do not change the payment progress bar in this ticket — ticket 13 owns it.
- Do not change `PaymentPlanMarker`'s label text or the "Original sale" link, which correctly
  points at a genuine sale.
- Do not alter pagination, sorting or search on the sales list.
- Do not change what a Shopify `payment_terms` order shows: its schedules all belong to one order,
  so it has no follow-up charges and is not affected.

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
