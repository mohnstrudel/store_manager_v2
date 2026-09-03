# 04. Resync and audit attribution history

Spec: ../spec.md
Status: done
Blocked by: 03-reconcile-installment-items-after-seal

## What to build

Run the ordered Shopify → Seal → database attribution workflow over accessible history and record deterministic resolved and unresolved outcomes. This ticket changes operational data, not application behavior.

## Acceptance criteria

- [x] Record pre-run counts for plans with missing origin/payment links, generic payment items, and historically attributed payment items.
- [x] Run one full Shopify sales crawl, allow the terminal Seal sync and attribution job to finish, and record job boundaries.
- [x] Every completed Seal attempt whose Shopify order exists links to its exact plan part.
- [x] Every plan with exactly one eligible origin item attributes payment items to that item.
- [x] Missing and zero/multi-item origins remain generic and are reported separately; none is assigned by customer or amount.
- [x] Logs show one ordered Seal iteration and no provider call from attribution.
- [x] A repeated workflow changes no relationship or attribution except genuine provider updates.
- [x] Save actions, counts, sampled IDs, unresolved reasons, and rerun comparison in `../artifacts/04-attribution-history-audit.md`.
- [x] Do not mark complete while unexplained wrong or missing links remain.

## Verification route

This is an operational ticket; Tickets 01–03 own automated behavior. Verify with read-only reports, the normal manager sync action with live credentials, queue/log observation, and an idempotent rerun.

## Failure and recovery

If Shopify fails, Seal and attribution must not start. If Seal fails, attribution must not start. Retry attribution alone after a local failure; never hand-edit product relationships during the audit.

## Anchors

- `app/jobs/shopify/pull_sales_job.rb:3-22` — full-history entry point.
- `app/jobs/seal/sync_payment_plans_job.rb:3-30` — ordered provider relationship sync.
- `app/jobs/seal/reconcile_installment_sale_items_job.rb` — database-only attribution job added by Ticket 03.
- `app/models/sale_payment_plan.rb:44-190` — relationship and attribution inspection boundary.
- `app/models/sale/installment_backfill.rb:11-67` — historical mechanism retained until audit completion.

## Non-goals

No parallel repair path, manual attribution, or currency audit.

## Focused verification

- `mise exec -- bundle exec rails runner 'plans = SalePaymentPlan.where(provider: "seal").includes(:origin_sale, parts: :sale); puts({plans: plans.size, missing_origins: plans.count { |plan| plan.origin_sale.nil? }, unlinked_completed_parts: plans.sum { |plan| plan.parts.active.count { |part| part.provider_completed_at && part.sale.nil? } }}.to_json)'` — reports relationship coverage.
- `mise exec -- bundle exec rails runner 'Seal::ReconcileInstallmentSaleItemsJob.perform_now; puts({generic_items: Product.where(non_catalog: true).joins(:sale_items).count, attributed_items: SaleItem.where.not(origin_sale_item_id: nil).count}.to_json)'` — runs and summarizes database-only attribution for comparison.
- `git diff --check` — checks the stored audit artifact.

## Completion evidence

Ticket 05 remains blocked until the artifact explains every unresolved case and confirms idempotence.
