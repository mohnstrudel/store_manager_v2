# 01. Persist and reconcile payment plans

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Persist provider payment plans and their contractual parts, normalize Shopify order IDs, link origins and parts to Sales in either synchronization order, and expose derived collected/projection summaries without changing existing Sale money behavior.

## Acceptance criteria

- [x] Multiple plans can belong to one origin Sale and one Sale can participate in multiple plans.
- [x] Plan and part snapshots upsert idempotently with database-backed scoped identity constraints.
- [x] Shopify GIDs and SEAL numeric order IDs reconcile through one normalizer.
- [x] Provider refreshes prune obsolete unlinked parts and preserve linked historical parts.
- [x] Collected counts, generic partial state, deposit projection, and ambiguous-projection behavior follow the approved authority rules.
