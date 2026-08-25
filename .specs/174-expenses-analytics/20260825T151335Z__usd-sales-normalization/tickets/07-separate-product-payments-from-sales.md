# 07. Separate product payments from sales

Spec: ../spec.md
Status: todo
Blocked by: none

## What to build

Keep follow-up payment orders inspectable on Product pages without presenting them as another merchandise sale or including them in merchandise sale counts and sold quantities.

## Acceptance criteria

- [ ] Rails decides whether each Product history row is a merchandise sale or follow-up payment using the existing payment-plan domain classification.
- [ ] Merchandise sale counts and sold quantities exclude follow-up payment-only rows.
- [ ] Follow-up payments remain linked and visible in a clearly labeled payment presentation.
- [ ] Payment rows identify their sequence or origin context when available.
- [ ] Deposit origin orders remain merchandise sales; only later plan charges become follow-up payments.
- [ ] Standalone sales and Shopify same-order payment terms retain existing merchandise behavior.

## Anchors

- `app/models/product/sales_history.rb:6-20` — current Product history and variant sold-count queries.
- `app/models/sale.rb:93-100` — payment-plan association and authoritative follow-up classification.
- `app/helpers/product_helper.rb:147-167` — current Product sale-item props omit payment context.
- `app/frontend/pages/Products/Show/SalesSection.tsx:13-81` — current table renders every row as a sale and uses array length as its count.
- `app/frontend/pages/Products/Show/SalesSection.test.tsx` — narrow Product history presentation seam.
- `spec/requests/products_spec.rb` — Rails-to-Inertia Product page contract.

## UI states

- No payments: preserve the existing sales table behavior.
- Payments present: show merchandise sales and follow-up payments with distinct labels/count semantics.
- A payment can link to its sale even when no warehouse/purchase item belongs to the payment row.

## Non-goals

- Do not hide or delete follow-up payment records.
- Do not classify a deposit origin as payment-only.
- Do not change payment-plan reconciliation.
- Do not perform currency conversion or product cash calculations.

## Coordination notes

- This ticket can run in parallel with currency tickets.

## TDD sequence

1. Start with a failing model/query example proving a Seal follow-up currently increases merchandise history or quantity.
2. Implement backend role derivation and query separation, then make request props pass.
3. Add failing component examples for the backend contract before changing the Product UI.
4. Run backend and frontend focused commands separately after each layer turns green.

## Test cases

- Ordinary Shopify, Woo, manual, native-payment-terms, and Seal-origin orders remain merchandise sales.
- A Seal follow-up whose plan origin is another Sale is a payment order.
- Deposit origin is never classified as payment-only.
- Merchandise counts and variant sold quantities exclude payment orders.
- Payment orders remain present in a payment group with path, sequence, and origin context.
- A payment without warehouse or purchase-item linkage still renders and links correctly.
- Product request props carry the backend-owned role.
- Product page with no payment orders preserves the existing sales presentation.
- Product page with both roles shows distinct groups and correct counts.
- Merchandise-only empty and payment-only empty states render no misleading table or count.
- Multiple payment orders for one merchandise sale do not duplicate product quantity or cost.

## Focused verification

- `mise exec -- bin/rspec spec/models/product_sales_history_spec.rb spec/helpers/product_helper_spec.rb spec/requests/products_spec.rb --format progress --color` — proves backend classification, counts, quantities, and props.
- `mise exec -- pnpm exec vitest run app/frontend/pages/Products/Show/SalesSection.test.tsx app/frontend/pages/Products/Show.test.tsx` — proves visible sale/payment separation and empty states.
- `mise exec -- pnpm exec tsc --noEmit` — proves the changed Product page contract is type-safe.
