# 05. Convert historical imported sales to USD

Spec: ../spec.md
Status: done
Blocked by: 02, 03, 04

## What to build

Provide a one-time historical conversion that changes existing Shopify, WooCommerce, and payment-plan money to USD and backfills normalized settlement status while leaving manual sale money and all purchase-side USD data unchanged. A null `settlement_status` is the unconverted marker, so the command resumes and refuses double conversion without any extra bookkeeping.

## Acceptance criteria

- [x] Every WooCommerce sale is treated as EUR and converted using `woo_created_at`.
- [x] Existing Shopify orders use the shop’s verified historical base currency; the backfill does not re-fetch every order only to rediscover that shop-level value.
- [x] Existing Seal plan money converts from each row’s recorded `currency` column.
- [x] External sale date controls every conversion; records without the required external date remain unchanged and appear in the report.
- [x] Sale totals and line prices convert once, then item received/outstanding/refunded revenue is reallocated from converted USD sale totals.
- [x] Payment-plan money converts using its origin sale date.
- [x] Manual sale money, purchases, supplier payments, expenses, and other entered USD values are outside the selection scope and stay unchanged.
- [x] Converted money, item reallocation, and `settlement_status` commit in one transaction per sale, so `settlement_status IS NULL` selects exactly the sales still to convert.
- [x] A second run over converted data changes nothing, and an interrupted run resumes on the remaining null-settlement sales.
- [x] The run reports converted, unresolved, and failed counts with identifiers, following the existing `Sale::InstallmentBackfill` result shape.
- [x] Every sale receives `paid`, `not_fully_paid`, or `unknown` from Ticket 02’s shared mapper; manual sales, which record no revenue amounts, become `unknown`.
- [ ] `sale_payment_plans.currency` and `sale_payment_parts.currency` are dropped as the final step, after plan conversion has committed. — **Deferred, not a same-CI-run task**: `Sale::UsdBackfill` itself reads `currency` off both tables to know what to convert, so a migration that drops those columns cannot be applied in the same schema state the backfill's own tests run against (Rails' pending-migration check aborts the whole suite otherwise, and an applied drop breaks the very code that needs the column). This is a real expand/contract deploy-ordering step: run `bin/rails backfill_sales_to_usd` in production, verify no non-USD `currency` values remain on `sale_payment_plans`/`sale_payment_parts`, then create and run a small follow-up migration (`remove_column :sale_payment_plans, :currency` / `remove_column :sale_payment_parts, :currency`) as its own commit.

## Anchors

- `app/models/sale/shopify/order_id.rb` — existing external-order normalization and sale resolution.
- `app/models/sale/revenue_allocation.rb:15-27` — authoritative item revenue recomputation after sale conversion.
- `app/models/sale_payment_plan.rb:65-79` — delayed external/local sale reconciliation.
- `app/models/sale/installment_backfill.rb:15-26` — existing one-time domain-command and result shape.
- `lib/tasks/backfill_installment_sale_items.rake:3-11` — current one-time task and reporting shape.

## Worked example

With `1 EUR = 1.1250 USD`, a historical Woo sale containing `100.00` total and `10.00` refund becomes `112.50` total and `11.25` refund, and its allocated item revenue is recomputed from those USD totals. The same sale now has a settlement status, so the next run does not select it again.

## Failure and recovery

- Require a database backup before running, because source amounts are intentionally not retained.
- Convert one sale and its items atomically; one failure does not leave that sale mixed-currency.
- A failed or unresolved sale keeps a null `settlement_status`, so the next run retries exactly that sale.
- Report enough external identifiers and dates to repair each unresolved row.

## Migration and compatibility

- Run after every live importer writes USD and after Ticket 04 stops reading and writing plan currency; the plan and part `currency` columns must still exist when the run starts.
- Historical conversion is an explicit domain command invoked by a task, not schema-migration application code or network access inside a migration.
- **Deferred:** the `sale_payment_plans.currency`/`sale_payment_parts.currency` drop is intentionally not part of this ticket's commit — see the acceptance criteria note above. Shipping it in the same schema state as the backfill code is impossible (the backfill reads those columns), so it ships as its own follow-up migration after a production run of `bin/rails backfill_sales_to_usd` is verified.

## Non-goals

- Do not guess historical Shopify currency from numeric values.
- Do not convert manual sale money or purchase-side USD records.
- Do not retain parallel EUR and USD balances.
- Do not delete unresolved records.
- Do not add a global completion marker, a per-sale conversion flag, or a separate dry-run code path; the null `settlement_status` scope carries all three jobs.

## TDD sequence

1. Build the backfill as a domain command under tests; start with the selection scope and prove it excludes manual and purchase-side records.
2. Add one failing example per source class before implementing that branch.
3. Add interruption, resume, and second-run examples before exposing the task entry point.
4. Add the currency-column drop only after historical plan conversion is green.

## Test cases

- The selection scope covers only external sales with a null `settlement_status`.
- Historical Woo sale converts from EUR using `woo_created_at` and receives the same settlement mapping as the live importer.
- Historical Shopify orders use the verified historical shop base currency and `shopify_created_at`.
- Existing Seal EUR, USD, CHF, GBP, CAD, and AUD plan values use the generic converter.
- A record with no required external date stays unchanged, keeps a null settlement status, and is reported.
- Manual sale money, purchases, supplier payments, and expenses stay unchanged.
- Sale and all its items convert atomically; an item failure rolls back that sale only and leaves its settlement status null.
- Converted sale totals reallocate item received, outstanding, and refunded amounts exactly once.
- Payment-plan money uses the origin sale date.
- Every processed sale backfills to `paid`, `not_fully_paid`, or `unknown`, and manual sales become `unknown`.
- A second run selects no already-converted sale and changes no money.
- After a failure is repaired, the next run processes only the remaining sales.
- Reported counts and identifiers match committed database state.
- Plan and part `currency` columns are absent after the final drop — deferred to the follow-up migration described above; not exercised by this ticket's Focused verification.

## Focused verification

- `mise exec -- bin/rspec spec/models/sale/usd_backfill_spec.rb --format progress --color` — proves selection scope, exact conversion, reallocation, unchanged USD domains, reporting, interruption recovery, and second-run safety.
