# 05. Delete the legacy USD backfill

Spec: ../spec.md
Status: done
Blocked by: 04-synchronize-and-audit-shopify-history

## What to build

After normal Shopify synchronization is proven complete, delete the parallel manual USD repair path and the obsolete Shopify conversion code that the order-level EUR conversion replaced.

## Acceptance criteria

- [x] Ticket 04's audit exists and reports completed pagination, complete Shopify currency and settlement data, reproducible samples, and an idempotent repeat run.
- [x] Delete `Sale::UsdBackfill`, `lib/tasks/backfill_sales_to_usd.rake`, and `spec/models/sale/usd_backfill_spec.rb`.
- [x] Remove the `SHOPIFY_HISTORICAL_CURRENCY` requirement with the legacy rake task.
- [x] No production code, rake task, current documentation, or scheduled command references the removed backfill.
- [x] Do not add a replacement backfill, compatibility shim, deprecated entry point, direct-money repair command, or manual SQL procedure.
- [x] Shopify order selection and parsing contain no obsolete per-field currency selection, nested `shopMoney.currencyCode` dependency, or Shopify call to the generic conversion methods replaced by Ticket 02.
- [x] Keep generic `ExchangeRate` and `SalePaymentPlan` conversion behavior still used by Seal or WooCommerce.
- [x] The normal bulk and single-order Shopify synchronization paths remain green after deletion.
- [x] WooCommerce synchronization remains green without retaining the one-time backfill.
- [x] Seal parsing, projections, monetary forecast, attribution, jobs, and storage remain unchanged.

## Verification route

This ticket deletes obsolete code after its replacement has already passed automated and operational verification. Existing provider tests and a live-reference search own the proof; no new replacement behavior or test-first case is needed.

## Anchors

- `app/models/sale/usd_backfill.rb:3-115` — legacy direct-money writer to delete.
- `lib/tasks/backfill_sales_to_usd.rake:3-15` — manual operational entry point to delete.
- `spec/models/sale/usd_backfill_spec.rb:5-205` — obsolete coverage removed with the legacy writer.
- `app/models/sale/shopify/parser.rb:88-160` — obsolete schedule-currency selection replaced by the order conversion.
- `app/models/sale/shopify/parser.rb:260-264` — obsolete field-by-field generic conversion replaced by the order conversion.
- `app/services/shopify/graphql/order_query.rb:31-77` — nested `shopMoney.currencyCode` fields no longer needed.

## Non-goals

No data backfill, direct data update, WooCommerce redesign, Seal change, payment-plan column removal, forecast removal, or migration of providerless sales.

## Focused verification

- `mise exec -- bin/rspec spec/models/exchange_rate_spec.rb spec/services/shopify/graphql/order_query_spec.rb spec/models/sale/shopify/parser_spec.rb spec/models/sale/shopify/importer_spec.rb spec/jobs/shopify/pull_sales_job_spec.rb spec/jobs/shopify/pull_sale_job_spec.rb spec/jobs/woo/pull_sales_job_spec.rb spec/models/sale_payment_plan/seal/parser_spec.rb` — proves the surviving rate and provider paths after deletion.
- `mise exec -- bundle exec rubocop app/models/exchange_rate.rb app/models/sale/shopify/parser.rb app/models/sale/shopify/importer.rb app/services/shopify/graphql/order_query.rb app/jobs/shopify/pull_sales_job.rb app/jobs/shopify/pull_sale_job.rb app/jobs/woo/pull_sales_job.rb spec/models/exchange_rate_spec.rb spec/models/sale/shopify/parser_spec.rb spec/models/sale/shopify/importer_spec.rb spec/jobs/shopify/pull_sales_job_spec.rb spec/jobs/shopify/pull_sale_job_spec.rb spec/jobs/woo/pull_sales_job_spec.rb` — checks the remaining Ruby code.
- `rg -n "Sale::UsdBackfill|backfill_sales_to_usd|SHOPIFY_HISTORICAL_CURRENCY|payment_plan_currency|schedule_currency" app lib spec config docs` — must find no live legacy reference.
- `git diff --check` — checks deletion and cleanup whitespace.
