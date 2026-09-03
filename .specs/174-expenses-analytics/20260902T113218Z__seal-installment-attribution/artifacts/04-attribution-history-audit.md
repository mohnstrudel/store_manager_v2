# Ticket 04 — Resync and audit attribution history

Live run against the development environment's real Shopify store (`68d8f5-af.myshopify.com`) and real Seal Subscriptions account, using this environment's own Sidekiq worker (started by the operator). Verified with read-only reports before/after two full ordered syncs, per-plan correctness checks over the entire live dataset, and an idempotent rerun — per this ticket's verification route (no automated test suite; Tickets 01–03 own that).

## Actions taken

1. Captured baseline counts (read-only).
2. Triggered the bulk sales sync action exactly as `Sales::BulkPullsController#create` does (`Config.update_shopify_sales_sync_time`, `Shopify::PullSalesJob.perform_later(limit: nil)`, `Woo::PullSalesJob` delayed) — **Run 1**.
3. Observed the ordered handoff in `log/development.log` and Sidekiq queue state until settled.
4. Verified relationship and attribution correctness across the full live dataset (script below).
5. Snapshotted full per-item attribution state, then re-triggered the Shopify crawl alone (Seal always follows on its terminal page) — **Run 2**, to check idempotence.
6. **Found a real defect while observing Run 1/2's side effects** (see below), fixed it, reverted the bad writes it had made, and reran the database-only reconciliation job alone (no provider calls) to reconfirm idempotence under the fixed code.

## Pre-run baseline (before Run 1)

```json
{"plans":275,"missing_origins":0,"unlinked_completed_parts":7,"generic_payment_items":39,"attributed_payment_items":338,"sale_count":3940}
```

## Run 1 — ordered Shopify → Seal → attribution

- Shopify: 11 pages processed (`Shopify::PullSalesJob`), one distinct job id per page, each scheduling the next; last page had `has_next_page: false`.
- Seal: **exactly one** `Seal::SyncPaymentPlansJob` job id in the logs for the whole run (single ordered iteration, matches AC "Logs show one ordered Seal iteration").
- Attribution: **exactly one** `Seal::ReconcileInstallmentSaleItemsJob` job id, enqueued only after the Seal job's `each_subscription_detail` loop completed without error.
- Zero lines matching `httparty|graphql|shopifyapi|seal::api|shopify::api` among the reconciliation job's 16,788 log lines — attribution made no provider call (matches AC "no provider call from attribution").
- Unrelated: one `Woo::PullSalesJob` retry (`Unmapped Woo status: "im-zulauf"`) — pre-existing Woo status-mapping gap, out of this spec's scope (currency/Woo work is tracked separately).

Post-Run-1 state:

```json
{"plans":307,"missing_origins":0,"unlinked_completed_parts":0,"generic_payment_items":26,"attributed_payment_items":375,"sale_count":3968}
```

- `plans` 275→307: 32 new Seal subscriptions synced from the live provider (genuine provider update).
- `unlinked_completed_parts` 7→0: every completed billing attempt whose Shopify order now exists locally is linked to its plan part (AC met).
- `sale_count` 3940→3968: 28 new orders imported by the real Shopify crawl.

### Per-plan correctness check (full live dataset, after Run 1)

Script: iterate every `SalePaymentPlan.seal`, compute `follow_up_sales` and `eligible_origin_item`, and classify every payment item.

```json
{"unique_correct":375,"unique_wrong_count":0,"unique_wrong_sample":[],"missing_origin_generic":0,"zero_origin_generic":0,"multi_origin_generic":26,"unexpected_state_count":0,"unexpected_state_sample":[]}
```

- **375/375** attributed payment items exactly match their plan's single eligible origin item (product, variant, `origin_sale_item`) — zero wrong attributions.
- **26/26** generic payment items are generic for exactly one reason: their plan's origin sale currently has **multiple** eligible catalog items (genuinely ambiguous) — zero due to a missing local order, zero due to zero eligible items, zero unexplained. None are assigned by customer or amount (the code path never queries either — verified by construction in Ticket 01–03's specs, e.g. `constructs no Shopify or Seal client`).
- `unexpected_state_count: 0` — every payment item across all 307 plans is fully explained.

## Run 2 — idempotence check

Re-triggered the Shopify crawl alone (11 pages again; Seal + attribution followed on the terminal page, one job id each). Comparing full per-item snapshots before/after Run 2 (`SaleItem` id → product/variant/origin_sale_item, and the generic-item id set): no attribution relationship changed relative to Run 1's outcome beyond what new provider data explains. Sidekiq settled with one unrelated pre-existing Woo retry (same status-mapping gap), zero new attribution-path errors.

## Defect found during observation, fixed, and remediated

While watching Run 1/2 for side effects, real notification emails were generated (intercepted locally by `letter_opener`, confirmed via `config.action_mailer.delivery_method = :letter_opener` — **no email left the machine**). Root cause: `SaleItem#apply_installment_origin!` updates `product`/`variant` on an already-persisted payment item; `SaleItem` includes the shared `VariantAssignment` concern, whose `around_update` callback treats any product/variant change as "this item just received real merchandise" and relinks a real warehouse `PurchaseItem` to it, then emails the customer an order-status update. A Seal follow-up payment item never owns its own warehouse unit — the acceptance criteria for Ticket 03 already named "no purchase linking" as a non-goal, and this closes the gap.

Fix (committed as `fix(seal): stop installment attribution from relinking warehouse units`): `VariantAssignment` gained a narrow `skip_purchase_relink` instance flag; `apply_installment_origin!` sets it so the relink/notify step is skipped while validations and the `audited` history stay intact. Reproduced red (test failed against the pre-fix code, confirming the exact `NotificationsMailer.order_status_updated_email` call) then green.

Remediation: 26 real `PurchaseItem`s had been pulled from "available" onto follow-up payment items during Run 1/2 (before the fix landed); their `warehouse_id` was never touched (confirmed per item during revert). Unlinked all 26 back to `sale_item_id: nil` via the model's own `unlink_from_sale_item!`. Left 21 separate, pre-existing (2026-07-30) cases from the old one-time `Sale::InstallmentBackfill` task untouched — same latent `VariantAssignment` defect, but out of this spec's scope and predates it; noting it here for awareness since `Sale::InstallmentBackfill` retires in Ticket 05 without cleaning up data it already wrote.

### Post-fix reconfirmation (database-only, no provider calls)

Ran `Seal::ReconcileInstallmentSaleItemsJob.perform_now` directly (full mode) after the fix and the data revert:

```json
{"new_letter_opener_emails": 0, "purchase_item_state_changed": false, "attribution_changed": false, "attributed_before": 375, "attributed_after": 375, "generic_before": 26, "generic_after": 26}
```

Zero new emails, zero `PurchaseItem` state changes, identical attribution — reconciliation is idempotent under the fixed code with no side effects outside its own table.

## Final state

```json
{"plans":307,"missing_origins":0,"unlinked_completed_parts":0,"generic_payment_items":26,"attributed_payment_items":375,"sale_count":3968}
```

Every plan and payment item is accounted for: 375 correctly attributed, 26 correctly generic (all due to genuine multi-item ambiguity, reported separately), 0 missing origins, 0 unlinked completed parts, 0 wrong or unexplained cases.

## Completion

No unexplained wrong or missing links remain. Ticket 05 is unblocked.
