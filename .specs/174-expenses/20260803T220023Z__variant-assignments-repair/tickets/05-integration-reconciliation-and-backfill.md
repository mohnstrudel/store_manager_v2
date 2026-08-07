# 05. Integration reconciliation and backfill

Spec: ../spec.md
Status: done
Blocked by: 04

## What to build

Add a dry-run-first, idempotent, resumable data command that reconciles external Variant identity and performs only deterministic internal repairs. Preserve the existing Woo synchronization process and hand every unresolved assignment to the live repair page.

## Acceptance criteria

- [x] The command defaults to dry-run and mutates only with `APPLY=1`.
- [x] It recalculates counts, checkpoints progress, resumes safely, and is idempotent.
- [x] Base activation is synchronized using Product-owned behavior.
- [x] Duplicate Shopify Variant external identities are reconciled atomically before dependent assignment repair.
- [x] Base-only Purchases and cross-Product Purchases targeting Base-only Products are repaired deterministically.
- [x] Base-only, origin-installment, and otherwise provable SaleItem identities are repaired without approximation.
- [x] PurchaseItem derived identity is backfilled and deterministic mismatches are silently unlinked and exact-relinked.
- [x] The post-backfill audit proves every PurchaseItem, including unlinked rows, exactly matches its Purchase Product/Variant identity.
- [x] Unresolved rows remain unchanged and visible through `Variant::AssignmentIntegrity`.
- [x] Operational output reports counts and failures without requiring CSV issue management.
- [x] The command performs no Woo network calls.
- [x] Woo pull, webhook, scheduling, full refresh, status transitions, shutdown, and stored-Variant preservation remain unchanged.
- [x] Regression tests prove Woo full refresh and status updates still work under the shared invariant.
- [x] Tests cover dry-run safety, `APPLY=1`, resumability, idempotency, deterministic repair, silence, unresolved handoff, Shopify reconciliation, and Woo compatibility.
- [x] The complete repository verification gate passes.
