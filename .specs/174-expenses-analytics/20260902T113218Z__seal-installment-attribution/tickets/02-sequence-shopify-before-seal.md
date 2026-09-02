# 02. Sequence Shopify before Seal

Spec: ../spec.md
Status: todo
Blocked by: 01-make-seal-order-ids-authoritative

## What to build

Start one Seal sync only after the selected Shopify sales crawl reaches a terminal successful page, and prevent overlapping Seal provider iterations.

## Acceptance criteria

- [ ] The bulk sales action enqueues Shopify and delayed Woo as before but no longer enqueues Seal directly.
- [ ] An intermediate Shopify page enqueues only the next Shopify page.
- [ ] A terminal full-history page enqueues one Seal sync after every order on that page imports successfully.
- [ ] A successful limited pull treats its processed page as terminal and enqueues Seal even when Shopify reports another page.
- [ ] Failed fetch/import and retry attempts enqueue no Seal job.
- [ ] A single-order pull never starts a full Seal sync.
- [ ] Seal sync holds one advisory lock over its complete provider iteration; a competing job exits without provider calls or writes.
- [ ] The lock releases on success and exception.

## TDD cases

- `bulk sync request` — request spec; write the failing example first and expect Shopify and Woo enqueues but no direct Seal enqueue.
- `Shopify page outcomes` — pull-job specs; expect correct handoff for intermediate, terminal, limited-terminal, failed, and rate-limited pages.
- `single-order pull` — pull-sale job spec; expect no full Seal enqueue.
- `concurrent and failed Seal syncs` — separate-connection job specs; expect one provider iteration and lock release after failure.

## Anchors

- `app/controllers/sales/bulk_pulls_controller.rb:3-24` — current parallel enqueue boundary.
- `app/jobs/shopify/base_pull_job.rb:8-52` — pagination, limit, and retry flow.
- `app/jobs/shopify/pull_sales_job.rb:3-22` — sale-pull specialization.
- `app/jobs/shopify/pull_sale_job.rb:3-14` — single-order path.
- `app/jobs/seal/sync_payment_plans_job.rb:3-30` — complete provider iteration.
- `spec/jobs/shopify/base_pull_job_spec.rb:108-229` — paging and retry seams.

## Non-goals

No attribution job yet, serialized Shopify crawls, or provider parsing in jobs/controllers.

## Focused verification

- `mise exec -- bin/rspec spec/requests/sales_sync_spec.rb spec/jobs/shopify/base_pull_job_spec.rb spec/jobs/shopify/pull_job_interface_spec.rb spec/jobs/shopify/pull_sales_job_spec.rb spec/jobs/shopify/pull_sale_job_spec.rb spec/jobs/seal/sync_payment_plans_job_spec.rb` — proves terminal handoff, retry behavior, and Seal single-flight execution.
- `mise exec -- bundle exec rubocop app/controllers/sales/bulk_pulls_controller.rb app/jobs/shopify/base_pull_job.rb app/jobs/shopify/pull_sales_job.rb app/jobs/shopify/pull_sale_job.rb app/jobs/seal/sync_payment_plans_job.rb spec/requests/sales_sync_spec.rb spec/jobs/shopify/base_pull_job_spec.rb spec/jobs/shopify/pull_job_interface_spec.rb spec/jobs/shopify/pull_sales_job_spec.rb spec/jobs/shopify/pull_sale_job_spec.rb spec/jobs/seal/sync_payment_plans_job_spec.rb` — checks affected Ruby code.
- `git diff --check` — checks patch whitespace.
