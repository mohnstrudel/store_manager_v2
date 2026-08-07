# 03. Exact links and notifications

Spec: ../spec.md
Status: done
Blocked by: 02

## What to build

Make PurchaseItem links database-backed exact Product/Variant assignments. Route all normal link and relink flows through one locked atomic command and notify affected customers only after the outermost transaction commits.

## Acceptance criteria

- [x] PurchaseItem stores derived Product and Variant identity copied from Purchase.
- [x] Composite database references prevent PurchaseItem identity from disagreeing with its Purchase or linked SaleItem.
- [x] General PurchaseItem and warehouse parameters cannot assign `sale_item_id` directly.
- [x] Link commands lock affected SaleItems and PurchaseItems in ascending ID order, then recheck exact identity and capacity.
- [x] Each requested link batch succeeds atomically or rolls back entirely.
- [x] Purchase or SaleItem identity changes unlink incompatible PurchaseItems before updating and exact-match relink within capacity.
- [x] Every normal new link or relink path schedules customer notification after the outermost commit.
- [x] Notification IDs are deduplicated within a command; repeated links and unlink-only changes send nothing.
- [x] Silent notification suppression is unavailable to normal controllers, forms, jobs, and integrations.
- [x] Tests cover database constraints, locking order, stale capacity, rollback, every normal link path, notification timing, deduplication, and no-ops.
- [x] The complete repository verification gate passes.
