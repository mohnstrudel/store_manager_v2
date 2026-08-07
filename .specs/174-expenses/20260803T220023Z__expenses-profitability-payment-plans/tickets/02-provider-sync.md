# 02. Synchronize Shopify and SEAL plan structure

Spec: ../spec.md
Status: done
Blocked by: 01

## What to build

Import exact native Shopify PaymentTerms schedules and synchronize SEAL subscription plans through the existing Store Sync lifecycle. Reconcile any existing or subsequently imported Sales without adding a new polling lifecycle.

## Acceptance criteria

- [x] Shopify imports complete PaymentTerms and PaymentSchedule identity, amount, currency, due, and completion data.
- [x] Native Shopify plans and parts are reconciled in the Sale import transaction.
- [x] Store Sync enqueues an idempotent SEAL plan synchronization for both limited and full Sales pulls.
- [x] SEAL plans link existing Sales, while later Shopify imports link previously synchronized SEAL origins and parts.
- [x] Provider failures preserve the previous snapshot and remain visible through existing job failure handling.
