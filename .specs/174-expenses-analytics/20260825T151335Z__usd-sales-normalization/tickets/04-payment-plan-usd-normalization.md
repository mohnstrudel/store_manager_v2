# 04. Normalize payment plans to USD

Spec: ../spec.md
Status: done
Blocked by: 01, 02

## What to build

Persist Shopify and Seal payment-plan money in USD using each recorded source currency and the originating sale’s external creation date. Defer monetary plan reconciliation only when the real origin date is not yet available. Stop reading and writing the plan and part currency columns, but leave the columns in place for Ticket 05 to read.

## Acceptance criteria

- [x] Shopify payment-term projections and retained part amounts persist in USD.
- [x] Seal deposit/installment projections and retained part amounts convert from their recorded EUR, USD, CHF, GBP, CAD, or AUD currency through the generic converter.
- [x] Shopify plans use the origin sale’s `shopify_created_at`; Seal plans use the linked origin sale’s applicable external creation date.
- [x] A plan without a resolvable origin date does not persist a foreign amount as USD and can be reconciled after the origin sale arrives.
- [x] Reconciliation remains idempotent and preserves provider/sequence uniqueness and active-part lifecycle.
- [x] `sale_payment_plans.currency` and `sale_payment_parts.currency` are no longer read or written by parsers, importers, helpers, factories, or tests; the columns stay in the database until Ticket 05 has converted historical plan money.
- [x] `status`, `next_due_at`, and part `amount` remain.
- [x] Plan profitability, projected remainder, and UI-formatted projection values consume USD without currency-specific branches.

## Anchors

- `app/models/sale_payment_plan.rb:44-79` — plan and delayed-sale reconciliation lifecycle.
- `app/models/sale_payment_plan.rb:105-134` — projected remainder and plan profitability consumers.
- `app/models/sale_payment_plan/seal/parser.rb:13-28` — Seal plan attributes currently include source currency.
- `app/models/sale_payment_plan/seal/parser.rb:97-115` — Seal part amounts and currencies.
- `app/jobs/seal/sync_payment_plans_job.rb:7-20` — Seal reconciliation boundary.
- `app/models/sale/shopify/importer.rb:65-73` — Shopify plan reconciliation after sale persistence.
- `app/helpers/sale_helper.rb:166-180` — payment-plan props currently format stored currency.
- `db/schema.rb:326-364` — current plan/part currency columns and uniqueness indexes.

## Worked example

An origin sale dated 2026-08-21 has a projected plan total of `1,000.00 EUR`. With rate `1.1250`, the plan persists `1,125.00 USD`. Reconciliation before the origin date is known stores no unconverted projection; reconciliation after linking produces `1,125.00 USD`.

## Migration and compatibility

- Do not drop the currency columns here: Ticket 05 reads each legacy row’s recorded currency, and Ticket 05 drops the columns as its final step.
- Preserve existing provider IDs, external order IDs, local sale links, active states, and uniqueness constraints.
- Do not remove or reinterpret `status`, `next_due_at`, or `amount`.

## Non-goals

- Do not write plan source currency or source amounts in live reconciliation.
- Do not use synchronization date as a fallback.
- Do not drop the plan or part currency columns in this ticket.
- Do not perform the historical data conversion in this ticket.

## Coordination notes

- Shopify payment-plan parsing shares files with Ticket 02; this ticket starts after Ticket 02.
- Ticket 05 requires the final USD plan schema and behavior.

## TDD sequence

1. Add a failing plan/parser example for one provider using a linked origin date and literal rate.
2. Implement Shopify payment terms and Seal conversion as separate red-green slices.
3. Add the missing-origin-date failure before changing reconciliation lifecycle.
4. Add schema-removal expectations only after every reader and writer test is green.

## Test cases

- Shopify payment-term projected total and retained part amounts convert using the origin `shopify_created_at`.
- Seal deposit and installment money converts from each recorded source currency using the linked origin’s external date.
- A `$420` deposit against projected `$1,400` yields `30%` progress and never `1 of 1`.
- Unequal scheduled parts retain their true completed/expected count independently from amount percentage.
- Missing origin sale or external date defers monetary reconciliation and persists no foreign amount as USD.
- Reconciliation after the origin arrives converts once and links the existing plan/parts.
- Repeating reconciliation preserves the same USD amounts, provider IDs, sequences, links, and active states.
- Projected remainder and plan profitability use converted USD without source-currency branches.
- No parser, importer, helper, or factory writes plan or part currency; `status`, `next_due_at`, and `amount` remain.
- Sale helper props format projected, collected, and remaining values as application USD.

## Focused verification

- `mise exec -- bin/rspec spec/models/sale_payment_plan_spec.rb spec/models/sale_payment_plan/seal/parser_spec.rb spec/jobs/seal/sync_payment_plans_job_spec.rb spec/models/sale/shopify/parser_spec.rb spec/models/sale/shopify/importer_spec.rb spec/helpers/sale_helper_spec.rb --format progress --color` — proves date-owned conversion, deferred reconciliation, schema contract, idempotency, and USD economics props.
