# 01. Reuse the origin sale item's variant for redirected installment payments

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

When `Sale::Shopify::SaleItemImporter` redirects a Seal installment/partial-payment line item to a
real target product, the created sale item must receive the same variant as the customer's resolved
origin sale item for that product, instead of always leaving the variant unset.

## Acceptance criteria

- [x] A redirected installment sale item whose origin sale item carries a real (non-base) variant is
      created successfully with that same variant, instead of raising "Variant must be selected" or
      "Variant must belong to the selected Product".
- [x] A redirected installment sale item whose origin sale item is on a simple, base-variant-only
      product still receives that base variant (unchanged from current behavior).
- [x] When no origin sale item is resolved yet, variant resolution behavior is unchanged from today
      (unset variant, base-model auto-fallback if available, validation failure otherwise).

Implementation note: the failing test also exposed that `unresolvable_new_variant?` (added in the
prior Shopify USD-sync ticket) matched `parsed[:variant_store_id]`/`parsed[:product_store_id]` —
which belong to the Seal placeholder line item, not the redirected target — against `resolved_product`,
deferring the item before the redirect/origin-item logic ever ran. Fixed by returning `false` from
that guard whenever `redirected_installment_product?` is true.

## TDD cases

- `redirected installment payment to a multi-variant product with no active base variant` —
  `spec/models/sale/shopify/sale_item_importer_spec.rb`; write the failing example first: give the
  target product two active real variants and a deactivated base variant, seed an
  origin (non-installment) sale item on that product with one of the real variants, run `import!`
  on the redirected installment line item, and expect it to succeed with
  `result.variant == origin_sale_item.variant` instead of raising `Sale::Shopify::Importer::Error`.
- `redirected installment payment to a simple product` — same file; the existing "reassigns the sale
  item to the real product and links the origin sale item" example
  (`spec/models/sale/shopify/sale_item_importer_spec.rb:420-431`) must keep passing unmodified,
  proving the fix does not change behavior when a base-model fallback already exists.

## Anchors

- `app/models/sale/shopify/sale_item_importer.rb:134-146` — `imported_variant`; line 136
  (`return @imported_variant = nil if redirected_installment_product?`) is the line to change.
- `app/models/sale/shopify/sale_item_importer.rb:101-105` — `resolved_origin_sale_item`; already
  computes the sale item this ticket reads `.variant` from.
- `app/models/sale/installment_product_resolver.rb:30-39` — `origin_sale_item`; source of the
  origin sale item and its variant, unchanged by this ticket.
- `spec/models/sale/shopify/sale_item_importer_spec.rb:404-488` — existing installment-redirect test
  block to extend with the new multi-variant case.

## Non-goals

- No change to `Sale::InstallmentProductResolver`'s resolution heuristics.
- No change to Seal parsing, sync ordering, or `SalePaymentPlan`.
- No new fallback or synthetic variant for the case where no origin sale item exists yet.
- No direct-database backfill of previously-failed orders; the next normal Shopify synchronization
  picks them up.

## Focused verification

- `mise exec -- bin/rspec spec/models/sale/shopify/sale_item_importer_spec.rb spec/models/sale/shopify/importer_spec.rb spec/models/sale/installment_product_resolver_spec.rb` — proves the fix and confirms no regression in the surrounding importer/resolver behavior.
- `mise exec -- bundle exec rubocop app/models/sale/shopify/sale_item_importer.rb spec/models/sale/shopify/sale_item_importer_spec.rb` — checks affected Ruby code.
- `git diff --check` — checks patch whitespace.
