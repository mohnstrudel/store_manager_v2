# 01. Make Seal order IDs authoritative

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Make Seal synchronization persist plan relationships solely from subscription origin order IDs and completed billing-attempt order IDs.

## Acceptance criteria

- [x] Normalize subscription `order_id` into the plan's external origin order ID and link `origin_sale` by that Shopify order ID.
- [x] Normalize each completed attempt `order_id` into its part and link the payment `sale` by that Shopify order ID.
- [x] Missing local orders leave explicit unlinked IDs and become linked idempotently after those sales arrive.
- [x] Duplicate provider attempts do not create duplicate active parts.
- [x] Customer, title, amount, date proximity, and Seal item product data never establish a relationship.
- [x] The sync fetches each required Seal dataset once per run.

## TDD cases

- `origin and billing-attempt IDs` — parser/model specs; write the failing example first and expect exact local sale links.
- `missing local orders` — sync/model specs; expect retained provider IDs followed by idempotent linking after import.
- `duplicate attempt ID` — plan reconciliation spec; expect one active part relationship.
- `matching customer and amount with different IDs` — sync/model spec; expect no relationship.

## Anchors

- `app/services/seal/api/client.rb:36-100` — subscription and billing-attempt datasets.
- `app/models/sale_payment_plan/seal/parser.rb:3-149` — normalized provider snapshots.
- `app/jobs/seal/sync_payment_plans_job.rb:7-30` — provider iteration and origin lookup.
- `app/models/sale_payment_plan.rb:44-79` — plan and sale relinking.
- `app/models/sale_payment_plan.rb:144-176` — part reconciliation by external order ID.

## Non-goals

No product attribution, job sequencing, or customer-based fallback.

## Focused verification

- `mise exec -- bin/rspec spec/services/seal/api/client_spec.rb spec/models/sale_payment_plan/seal/parser_spec.rb spec/jobs/seal/sync_payment_plans_job_spec.rb spec/models/sale_payment_plan_spec.rb` — proves exact provider-ID relationships and recovery.
- `mise exec -- bundle exec rubocop app/services/seal/api/client.rb app/models/sale_payment_plan/seal/parser.rb app/jobs/seal/sync_payment_plans_job.rb app/models/sale_payment_plan.rb spec/services/seal/api/client_spec.rb spec/models/sale_payment_plan/seal/parser_spec.rb spec/jobs/seal/sync_payment_plans_job_spec.rb spec/models/sale_payment_plan_spec.rb` — checks affected Ruby code.
- `git diff --check` — checks patch whitespace.
