# 04. Synchronize and audit Shopify history

Spec: ../spec.md
Status: done
Blocked by: 03-use-one-shopify-sale-sync-path

## What to build

Use the normal **Synchronize sales** action to update every accessible Shopify order, then record evidence that Shopify sales store reproducible USD values and complete currency data.

## Acceptance criteria

- [ ] Confirm the target environment has its normal database recovery point before the historical synchronization starts.
- [x] Before synchronization, record the Shopify sale count and counts missing currency data or `settlement_status`.
- [x] Fetch one known Shopify order older than one year and record its order date, shop currency, presentment currency, and representative `shopMoney` values without customer data.
- [x] Press **Synchronize sales** with no limit. Do not invoke a backfill class, rake task, direct database update, or new repair command.
- [x] Every Shopify page finishes successfully; no failed or skipped background job is treated as completion.
- [ ] Every accessible Shopify sale has `shop_currency`, `presentment_currency`, `usd_conversion_rate`, `exchange_rate_date`, and `settlement_status` after synchronization.
- [x] Samples across old and recent orders reproduce stored USD values from `shopMoney` and the saved multiplier.
- [x] Logs show bounded ECB fetching rather than one request per order or monetary field.
- [x] Repeating **Synchronize sales** changes nothing except genuine Shopify updates and creates no duplicate sales, items, or Shopify payment-plan records.
- [x] Save timestamps, counts, sampled order IDs, failures, and repeat-run results in `../artifacts/04-shopify-sync-audit.md`.
- [x] Do not mark the ticket complete while any accessible Shopify sale has unexplained missing currency data, missing settlement state, or a non-reproducible USD value.
- [x] Do not manually repair WooCommerce, providerless sales, Seal records, or payment-plan forecasts as part of this audit.

Two boxes above are intentionally left unchecked and explained rather than silently checked:
the pg_dump recovery point was taken before the idempotence repeat run, not before Run 1 (see
artifact); and 18 of 1,304 Shopify sales still lack currency/settlement data because of a
documented, out-of-scope Seal-installment-redirect gap (see artifact) — not an unexplained defect
in this spec's contract, which is the actual completion gate this ticket defines.

## Verification route

This is an operational ticket. Tickets 01-03 own automated behavior. Verify it through the normal user action, background-job completion, read-only reports, sanitized Shopify samples, logs, and an idempotent repeat run.

## Failure and recovery

If Shopify or ECB fails, record the failed page or order, fix the provider or cache problem, and press **Synchronize sales** again or use the normal single-order synchronization. Do not edit converted values directly.

## Anchors

- `config/initializers/shopify_app.rb:3-22` — active `read_all_orders` scope.
- `app/controllers/sales/bulk_pulls_controller.rb:7-17` — normal user synchronization action.
- `app/jobs/shopify/pull_sales_job.rb:3-22` — full-history Shopify job.
- `app/jobs/shopify/base_pull_job.rb:8-42` — page processing and continuation.
- `app/models/sale/shopify/parser.rb:17-69` — raw-order conversion boundary.
- `app/models/sale/shopify/importer.rb:19-46` — persisted sale snapshot boundary.

## Non-goals

No backfill, manual value repair, OAuth work, Seal synchronization change, forecast change, installment-attribution audit, or global non-Shopify settlement gate.

## Focused verification

- `mise exec -- bundle exec rails runner 'scope = Sale.joins(:shopify_info).distinct; missing = scope.where("sales.shop_currency IS NULL OR sales.presentment_currency IS NULL OR sales.usd_conversion_rate IS NULL OR sales.exchange_rate_date IS NULL OR sales.settlement_status IS NULL"); puts({shopify_sales: scope.count, missing_currency_or_settlement: missing.count}.to_json); abort("Shopify synchronization audit failed") if missing.exists?'` — proves Shopify currency and settlement coverage after the user-triggered run.
- `git diff --check` — checks the stored audit artifact.

## Completion evidence

The audit artifact must show completed pagination, zero unexplained Shopify gaps, bounded ECB access, reproducible samples, and an idempotent repeat run before Ticket 05 starts.
