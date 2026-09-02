# 03. Use one Shopify sale synchronization path

Spec: ../spec.md
Status: done
Blocked by: 02-store-shopify-orders-in-usd

## What to build

Prove that full-history, limited, and single-order Shopify synchronization all fetch the complete order and apply the same USD conversion and persistence contract.

## Acceptance criteria

- [x] The same raw order imported through full, limited, and single-order synchronization produces identical USD values and currency data.
- [x] Bulk and single-order jobs both call `Sale::Shopify::Parser` and `Sale::Shopify::Importer`; neither writes sale money or currency data directly.
- [x] A limited pull changes only the number of fetched orders, not the query fields, conversion, or persistence behavior.
- [x] Repeating or alternating entry points updates one sale idempotently.
- [x] The existing **Synchronize sales** action enqueues the bulk Shopify job with the requested limit and exposes no backfill action.
- [x] Existing WooCommerce and Seal jobs triggered by the bulk action remain unchanged.
- [x] Existing truncated-line-item reporting remains intact.
- [x] Read-only Shopify order lookup used by Seal attribution remains unchanged and does not become a sale write path.

## TDD cases

- `same EUR order through all synchronization entry points` — job specs; write the failing examples first and expect identical persisted USD values and currency data.
- `limited pull` — bulk job spec; expect the requested count through the normal query, parser, and importer.
- `bulk then single-order import` — job/importer specs; expect one stable sale.
- `synchronization request` — existing request-boundary coverage; expect the bulk Shopify job with the submitted limit and no backfill command.
- `truncated line items` — API client regression spec; expect existing reporting behavior.

## Anchors

- `app/services/shopify/api/client.rb:117-155` — by-ID and paginated order fetching through the shared query.
- `app/jobs/shopify/base_pull_job.rb:8-42` — paginated parser/importer template.
- `app/jobs/shopify/pull_sales_job.rb:3-22` — full and limited sale synchronization.
- `app/jobs/shopify/pull_sale_job.rb:3-14` — single-order synchronization.
- `app/controllers/sales/bulk_pulls_controller.rb:7-17` — user-triggered bulk synchronization boundary.
- `app/controllers/sales/pulls_controller.rb:7-15` — user-triggered single-sale synchronization boundary.
- `spec/jobs/shopify/base_pull_job_spec.rb:108-229` — pagination and limit seams.
- `spec/controllers/sales/bulk_pulls_controller_spec.rb:7-45` — existing bulk request coverage; do not add a new controller spec.

## Non-goals

No second importer, job-local conversion, controller conversion, Seal sequencing change, attribution change, or backfill command.

## Focused verification

- `mise exec -- bin/rspec spec/services/shopify/api/client_spec.rb spec/jobs/shopify/base_pull_job_spec.rb spec/jobs/shopify/pull_sales_job_spec.rb spec/jobs/shopify/pull_sale_job_spec.rb spec/controllers/sales/bulk_pulls_controller_spec.rb spec/controllers/sales/pulls_controller_spec.rb` — proves entry-point parity, idempotence, and existing request routing.
- `mise exec -- bundle exec rubocop app/services/shopify/api/client.rb app/jobs/shopify/base_pull_job.rb app/jobs/shopify/pull_sales_job.rb app/jobs/shopify/pull_sale_job.rb app/controllers/sales/bulk_pulls_controller.rb app/controllers/sales/pulls_controller.rb spec/services/shopify/api/client_spec.rb spec/jobs/shopify/base_pull_job_spec.rb spec/jobs/shopify/pull_sales_job_spec.rb spec/jobs/shopify/pull_sale_job_spec.rb` — checks affected Ruby code.
- `git diff --check` — checks patch whitespace.
