# 03. Reconcile installment items after Seal

Spec: ../spec.md
Status: todo
Blocked by: 02-sequence-shopify-before-seal

## What to build

Replace import-time product guessing with `Seal::ReconcileInstallmentSaleItemsJob`. It reads persisted plans and sales, then invokes cohesive model methods to apply or clear attribution without provider access.

## Acceptance criteria

- [ ] Add full-plan and single-sale modes to the reconciliation job.
- [ ] A complete successful Seal sync enqueues one full reconciliation; a failed sync enqueues none.
- [ ] A single-order Shopify pull may enqueue scoped reconciliation after import, but never a full Seal sync.
- [ ] `SalePaymentPlan` selects follow-up sales only from active linked parts distinct from its origin sale.
- [ ] Exactly one catalog, non-installment origin item assigns that item, its product, and its variant to the payment item.
- [ ] Missing records or zero/multiple eligible origin items leave or restore the canonical Seal placeholder product with no origin item or variant.
- [ ] Unique relationships correct previous guesses; ambiguous relationships clear unsupported guesses.
- [ ] Repeated full or scoped runs are idempotent.
- [ ] The reconciliation path constructs no Shopify/Seal client, pulls no product, links no purchase, and performs no customer-wide search.
- [ ] `Sale::Shopify::SaleItemImporter` stops invoking `Sale::InstallmentProductResolver`; the live behavior is model methods plus the delivery job, not another resolver object.

## TDD cases

- `unique, missing, zero, and multiple origin items` — plan/model specs; write failing examples first and expect the approved resolved or generic state.
- `historical guesses` — plan/model specs; expect a unique plan to correct a wrong guess and an ambiguous plan to clear it.
- `repeat full and scoped runs` — job/model specs; expect no changes or duplicates.
- `successful and failed Seal syncs` — Seal job spec; expect reconciliation enqueue only after complete success.
- `single sale with and without a persisted plan` — pull-sale/scoped-job specs; expect local repair or a no-op, never full Seal sync.
- `provider isolation` — job/model specs; expect no Shopify or Seal client construction.

## Anchors

- `app/models/sale_payment_plan.rb:44-79` — authoritative origin and payment-sale links.
- `app/models/sale_payment_plan.rb:144-190` — linked-part reads and plan-level orchestration seam.
- `app/models/sale.rb:76-103` — sale items and payment-plan associations.
- `app/models/sale_item.rb:41-49` — non-installment scope and origin-item relation.
- `app/models/sale/shopify/sale_item_importer.rb:67-108` — current inline resolver call to remove.
- `app/models/sale/installment_product_resolver.rb:22-119` — heuristic and provider behavior being replaced.
- `app/jobs/seal/sync_payment_plans_job.rb:7-23` — success-only full-job handoff seam.
- `app/jobs/shopify/pull_sale_job.rb:5-13` — scoped post-import handoff seam.

## Non-goals

No provider request, multi-product allocation, purchase linking, or replacement resolver/service.

## Focused verification

- `mise exec -- bin/rspec spec/models/sale_payment_plan/installment_attribution_spec.rb spec/jobs/seal/reconcile_installment_sale_items_job_spec.rb spec/jobs/seal/sync_payment_plans_job_spec.rb spec/jobs/shopify/pull_sale_job_spec.rb spec/models/sale/shopify/sale_item_importer_spec.rb spec/models/product_sales_history_spec.rb` — proves deterministic attribution, orchestration, isolation, and product history.
- `mise exec -- bundle exec rubocop app/models/sale_payment_plan.rb app/models/sale.rb app/models/sale_item.rb app/models/sale/shopify/sale_item_importer.rb app/models/product/sales_history.rb app/jobs/seal/reconcile_installment_sale_items_job.rb app/jobs/seal/sync_payment_plans_job.rb app/jobs/shopify/pull_sale_job.rb spec/models/sale_payment_plan/installment_attribution_spec.rb spec/jobs/seal/reconcile_installment_sale_items_job_spec.rb spec/jobs/seal/sync_payment_plans_job_spec.rb spec/jobs/shopify/pull_sale_job_spec.rb spec/models/sale/shopify/sale_item_importer_spec.rb spec/models/product_sales_history_spec.rb` — checks affected Ruby code.
- `git diff --check` — checks patch whitespace.
