# 02. Assignment forms

Spec: ../spec.md
Status: done
Blocked by: 01

## What to build

Expose Product-owned assignable Variants to Purchase and manual Sale forms. Add explicit per-row Sale Variant selection. Extend new Product creation so an optional initial Purchase selects a stable draft Variant and resolves it atomically after the Variants are saved.

## Acceptance criteria

- [x] The assignable-Variants endpoint returns the approved `mode` and Variant shape from an authorized Product relation.
- [x] Purchase and Sale forms submit fixed Base in base mode and require an explicit choice in select mode.
- [x] Neither form auto-selects the first real Variant, and changing Product clears the old Variant.
- [x] Manual Sale rows persist `variant_id` and display row-specific backend validation errors.
- [x] Draft Variant rows keep stable client keys through edits, activation changes, and submission.
- [x] Draft Base is suppressed by the first active real Variant and restored after the last active real Variant is removed or deactivated.
- [x] Initial Purchase `variant_client_key` resolves only after Variant persistence inside the existing Product transaction.
- [x] A missing or invalid draft key rolls back Product, Variants, Purchase, PurchaseItems, and payment.
- [x] Request, component, and focused browser tests cover the public contract and error/reload seams.
- [x] The complete repository verification gate passes.
