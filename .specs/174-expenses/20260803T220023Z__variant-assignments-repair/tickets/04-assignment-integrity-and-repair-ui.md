# 04. Assignment integrity and repair UI

Spec: ../spec.md
Status: done
Blocked by: 03

## What to build

Add a permanent administrator repair workspace backed by live integrity queries. Allow inline Purchase and SaleItem Variant repair and one-action PurchaseItem link repair through the sole silent repair command.

## Acceptance criteria

- [x] `Variant::AssignmentIntegrity` returns live counts and pageable relations for broken Purchases, broken SaleItems, and incompatible PurchaseItem links without persisting issues.
- [x] The admin page uses URL-backed tabs, filters, counters, and pagination and shows the approved evidence and impact fields.
- [x] Purchase and SaleItem rows edit only through `variant_repair_candidates`.
- [x] Link repair silently unlinks a mismatch and relinks exact available inventory only when capacity exists.
- [x] `Variant::AssignmentRepair` is the only silent writer and is callable only by the backfill and administrator repair resources.
- [x] Every repair rechecks the live predicate under ordered locks.
- [x] A stale already-resolved row is a successful no-op.
- [x] Successful repairs reload rows, counts, and pagination so resolved rows disappear.
- [x] `useInlineCellForm` supports an optional Inertia reload-props contract without gaining Variant-specific behavior.
- [x] The page, navigation entry, and every repair endpoint are administrator-only.
- [x] The empty state reads `No Variant assignment issues`.
- [x] Request, model, component, and focused browser tests cover authorization, pagination, filters, stale rows, inline errors, historical candidates, impact warnings, reload behavior, and silent link repair.
- [x] The complete repository verification gate passes.
