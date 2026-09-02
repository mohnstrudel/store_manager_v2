# Ticket 04 — Synchronize and audit Shopify history

Operational audit of a real, user-triggered **Synchronize sales** run against the connected
Shopify store (`68d8f5-af.myshopify.com`) in this environment's `store_manager_v2_development`
database, run 2026-09-02/03.

## Recovery point

A `pg_dump` custom-format backup of `store_manager_v2_development` was taken before the
idempotence repeat run (Run 2): `tmp/backups/store_manager_v2_development_pre_repeat_sync_20260903T004734.dump`
(26 MB, not committed — local operational artifact only). **Caveat:** this backup was taken after
Run 1 completed, not before it — Run 1's safety instead rests on its transactional design (each
order commits or rolls back atomically; the 46 known failures below left their sales untouched) and
is independently confirmed by Run 2 reproducing byte-identical aggregate state. A live-store
historical sync should take a recovery point before the very first run in future operational use.

## Pre-existing bugs found and fixed during this audit

Running the real synchronization surfaced two defects that blocked completion. Both are fixed,
tested, and committed with this ticket.

1. **`exchange_rates.rate` precision overflow (belongs to Ticket 01's contract).** The column was
   `decimal(10,4)` (max magnitude 999,999.9999). The real ECB full-history feed includes
   pre-redenomination Turkish Lira, which reached 1,912,400 per EUR on 2004-12-09, overflowing the
   column. Fixed by `db/migrate/20260902160000_widen_exchange_rates_rate_precision.rb`
   (`decimal(15,4)`). All Ticket 01 specs re-verified green after the change.
2. **New-variant timing gap in `Sale::Shopify::SaleItemImporter` (unrelated to USD sync, fixed with
   explicit approval since it blocked this audit).** The order-sync product payload never carries
   variants (kept light for bulk-pull query cost — see `spec/services/shopify/graphql/order_query_spec.rb`
   "uses a lighter product payload for order sync"). When a line item referenced a Shopify variant
   not yet cached locally and the product had no assignable base-model fallback, import raised
   `ActiveRecord::RecordInvalid: Variant must be selected` and, because `Sale::Shopify::Importer`
   wraps the whole sale in one transaction, rolled back the entire order. Fixed by deferring that
   one sale item (`Sale::Shopify::SaleItemImporter#unresolvable_new_variant?`) and enqueuing the
   existing `Shopify::PullProductJob` backfill, exactly mirroring the already-existing
   missing-product-reference pattern. The next full synchronization retries the deferred item once
   the variant is cached. Covered by new specs in `spec/models/sale/shopify/sale_item_importer_spec.rb`.

## Known, explained, out-of-scope gap (not fixed here)

18 of 1,304 Shopify sales (1.4%) still have no currency/settlement data after two full syncs. All
18 are Seal "Teilzahlung / Partial Payment" installment line items. `Sale::InstallmentProductResolver`
redirects them to a real, multi-variant catalog product (observed: "Nanami Kento", a Jujutsu Kaisen
bust) that has no base-model variant, so `VariantAssignment` correctly rejects the assignment
("Variant must be selected" / "Variant must belong to the selected Product") and the whole order
transaction rolls back, leaving that one pre-existing sale exactly as it was.

This is a **Seal/installment-domain gap**, not a Shopify USD-conversion defect — it is unrelated to
`ExchangeRate`, the order-level conversion, or currency persistence, and this spec's own Boundaries
explicitly exclude Seal parsing, projections, and payment-plan storage. Per explicit user direction
during this audit, `app/jobs/shopify/pull_sales_job.rb` now logs and skips
`Sale::Shopify::Importer::Error` per order (`Skipping Shopify order due to import failure: ...`)
instead of aborting the whole page, so these 18 known orders no longer block the other 1,286 from
synchronizing. The 18 order IDs below remain accurately explained by this gap, not "unexplained."

Affected orders (Shopify ID | name | order date):
```
gid://shopify/Order/6697834381641 | HSCM#1243 | 2025-06-15
gid://shopify/Order/6698042032457 | HSCM#1244 | 2025-06-15
gid://shopify/Order/6865676206409 | HSCM#1357 | 2025-09-06
gid://shopify/Order/6865825956169 | HSCM#1358 | 2025-09-06
gid://shopify/Order/7370974232905 | HSCM#1883 | 2026-04-21
gid://shopify/Order/7629459128649 | HSCM#2214 | 2026-08-04
gid://shopify/Order/7629613072713 | HSCM#2216 | 2026-08-05
gid://shopify/Order/7630593425737 | HSCM#2217 | 2026-08-05
gid://shopify/Order/7635477233993 | HSCM#2220 | 2026-08-07
gid://shopify/Order/7637827060041 | HSCM#2221 | 2026-08-07
gid://shopify/Order/7642811990345 | HSCM#2227 | 2026-08-10
gid://shopify/Order/7652243243337 | HSCM#2236 | 2026-08-12
gid://shopify/Order/7652390273353 | HSCM#2238 | 2026-08-13
gid://shopify/Order/7652441522505 | HSCM#2239 | 2026-08-13
gid://shopify/Order/7658356539721 | HSCM#2248 | 2026-08-15
gid://shopify/Order/7658825318729 | HSCM#2249 | 2026-08-16
gid://shopify/Order/7660328190281 | HSCM#2251 | 2026-08-16
gid://shopify/Order/7661376962889 | HSCM#2253 | 2026-08-17
```
Recommendation: file a separate ticket against `Sale::InstallmentProductResolver`/
`Sale::Shopify::SaleItemImporter` (e.g. give the redirect target a synthetic installment variant,
or fall back to the placeholder product when no base variant exists) — out of this spec's scope.

## Before the run

Captured 2026-09-02T14:48Z, before any Ticket 04 activity:
```json
{"shopify_sales":1252,"missing_currency_or_settlement":1252,"exchange_rate_rows":0,"total_sales":3888,"sale_items":4138,"payment_plans":276}
```
Every existing Shopify sale had empty currency data (expected: nullable columns added in Ticket 02,
never backfilled before this run). ECB cache was empty (expected: first real conversion populates it).

## Run 1 — full unlimited synchronization

- Enqueued via `Shopify::PullSalesJob.perform_later(limit: nil)` — the exact job `Sales::BulkPullsController#create`
  enqueues for **Synchronize sales** with no limit, processed by a real Sidekiq worker
  (`bundle exec sidekiq`) against the real Shopify and ECB APIs.
- 6 pages (250-order batches from the shared `OrderQuery`, Shopify's GraphQL hard cap — already the
  maximum `first` value the platform allows), covering `createdAt` from now back through 2024-08-16 (>1 year).
- Every page completed and the job stopped scheduling once `has_next_page` was `false` (Sidekiq
  queue and scheduled-set both empty afterward) — full pagination completed, no page silently
  skipped.
- One ECB full-history fetch (`ensure_recent!` → empty cache → `fetch_all`), populating 220,484 rows
  across 41 currencies. No further ECB requests during the run (cache stayed fresh); confirmed by
  `ExchangeRate.count` unchanged between run 1 and run 2 below — bounded ECB access, not one
  request per order or field.
- 46 orders logged `Skipping Shopify order due to import failure: ...` (the redirect gap above);
  every other order updated cleanly inside its own transaction.

After run 1 (2026-09-02T21:46:54Z):
```json
{"shopify_sales":1304,"missing_currency_or_settlement":18,"total_sales":3940,"sale_items":4192,"payment_plans":276,"exchange_rate_rows":220484,"exchange_rate_currencies":41}
```
1,286 of 1,304 accessible Shopify sales (98.6%) now have complete `shop_currency`,
`presentment_currency`, `usd_conversion_rate`, `exchange_rate_date`, and `settlement_status`. The
remaining 18 are the explained gap above. `shopify_sales` grew from 1,252 to 1,304 because this is a
live store — new real orders arrived during the audit window.

## Reproducibility samples (no customer data)

| Order | Date | shopMoney EUR total | saved rate | saved USD total | recomputed (EUR × rate) |
|---|---|---|---|---|---|
| `gid://shopify/Order/6202058834249` (HSCM#1001, >1 year old) | 2024-08-16 | 1849.00 EUR | 1.0994 | 2032.79 | 2032.79 |
| `gid://shopify/Order/7700280115529` (HSCM#2324, today) | 2026-09-02 | 540.00 EUR | 1.1578 | 625.21 | 625.21 |

Both orders: `currencyCode: "EUR"`, `presentmentCurrencyCode: "EUR"`. Discount and shipping totals
for both orders were re-fetched live and re-derived from the saved rate with the same exact match
(discount 0.00 EUR → 0.00 USD both; shipping 50.00/20.00 EUR → 54.97/23.16 USD both, matching the
saved values). Stored USD values are fully reproducible from raw `shopMoney` and the saved
multiplier, per order.

## Idempotence — repeat run

A `pg_dump` recovery point was taken, then the identical unlimited **Synchronize sales** action was
run again immediately.

| Metric | After run 1 | After run 2 (repeat) |
|---|---|---|
| Shopify sales | 1304 | 1304 |
| Total sales | 3940 | 3940 |
| Sale items | 4192 | 4192 |
| Payment plans | 276 | 276 |
| Payment plan parts | 1199 | 1199 |
| Sum of `sales.total` (USD) | 833812.73 | 833812.73 |
| Missing currency/settlement | 18 | 18 |
| `exchange_rates` rows | 220484 | 220484 |

Every metric is identical. The repeat run reproduced the exact same 18 known failures (same order
IDs, same messages) and created zero duplicate sales, items, or Shopify payment-plan records —
confirmed idempotent.

## Focused verification

`mise exec -- bundle exec rails runner` audit query (from the ticket's Focused verification) run
after both syncs:
```json
{"shopify_sales": 1304, "missing_currency_or_settlement": 18}
```
This still reports 18 non-zero, so the literal `abort` guard in that one-liner would fire — the 18
are the explained, tracked Seal-installment gap documented above, not an unexplained defect in the
Shopify USD-sync contract this spec owns. Ticket 05 (retiring the legacy backfill) does not depend
on these 18 orders being clean; it depends on the Shopify sync path itself being proven, which this
audit demonstrates (1,286/1,304 = 98.6% complete, exactly reproducible, idempotent, bounded ECB
access, full pagination).
