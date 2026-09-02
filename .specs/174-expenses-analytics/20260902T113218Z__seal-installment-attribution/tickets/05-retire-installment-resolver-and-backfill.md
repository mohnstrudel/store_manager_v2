# 05. Retire the installment resolver and backfill

Spec: ../spec.md
Status: todo
Blocked by: 04-resync-and-audit-attribution-history

## What to build

After the attribution audit succeeds, remove the heuristic/provider resolver and the one-time installment backfill so only persisted Seal relationships and the database-only model command remain.

## Acceptance criteria

- [ ] Remove `Sale::InstallmentProductResolver`, its specs, and every reference.
- [ ] Remove `Sale::InstallmentBackfill`, `lib/tasks/backfill_installment_sale_items.rake`, obsolete specs, and every reference.
- [ ] Preserve the canonical Seal placeholder identity under a stable domain owner used by import and reconciliation.
- [ ] The only attribution path is persisted Seal relationships → `SalePaymentPlan` model command → reconciliation job.
- [ ] No production command, callback, scheduled task, or documentation invokes customer/amount/provider fallback.
- [ ] Unique, missing, and ambiguous attribution behavior remains green after deletion.

## TDD cases

- `post-cleanup unique and ambiguous cases` — plan/job specs; write failing regression examples first and expect approved outcomes without either removed constant.
- `generic Shopify payment import` — sale-item importer spec; expect the placeholder until reconciliation.
- `provider isolation after cleanup` — job/model specs; expect no Shopify or Seal client construction.

## Failure and recovery

If cleanup reveals unaudited references or invalid historical outcomes, stop and return to Ticket 04. Do not restore heuristic resolution.

## Anchors

- `app/models/sale/installment_product_resolver.rb:3-120` — resolver being removed.
- `spec/models/sale/installment_product_resolver_spec.rb:5-131` — obsolete resolver coverage.
- `app/models/sale/installment_backfill.rb:3-67` — backfill being removed.
- `lib/tasks/backfill_installment_sale_items.rake:1-12` — obsolete task entry point.
- `spec/models/sale/installment_backfill_spec.rb:5-96` — obsolete backfill coverage.
- `app/models/sale/shopify/sale_item_importer.rb:67-108` — importer after resolver removal.

## Non-goals

No deletion of the new reconciliation job, audit artifact, or unresolved multi-product records.

## Focused verification

- `mise exec -- bin/rspec spec/models/sale_payment_plan/installment_attribution_spec.rb spec/jobs/seal/reconcile_installment_sale_items_job_spec.rb spec/models/sale/shopify/sale_item_importer_spec.rb spec/models/product_sales_history_spec.rb` — proves final attribution behavior after deletion.
- `mise exec -- bundle exec rubocop app/models/sale_payment_plan.rb app/models/sale.rb app/models/sale_item.rb app/models/sale/shopify/sale_item_importer.rb app/jobs/seal/reconcile_installment_sale_items_job.rb spec/models/sale_payment_plan/installment_attribution_spec.rb spec/jobs/seal/reconcile_installment_sale_items_job_spec.rb spec/models/sale/shopify/sale_item_importer_spec.rb spec/models/product_sales_history_spec.rb` — checks affected Ruby code.
- `rg -n "Sale::InstallmentProductResolver|Sale::InstallmentBackfill|backfill_installment_sale_items" app lib spec config db` — finds no unexpected live legacy references.
- `git diff --check` — checks patch whitespace.
