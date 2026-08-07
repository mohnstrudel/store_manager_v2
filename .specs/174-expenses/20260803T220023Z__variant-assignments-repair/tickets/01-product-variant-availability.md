# 01. Product Variant availability

Spec: ../spec.md
Status: done
Blocked by: none

## What to build

Give Product one persisted Base Model lifecycle and one assignment-availability contract. Enforce same-Product identity and normal assignment eligibility for Purchase and SaleItem while preserving unchanged historical references. Add only the database groundwork needed by later link and contraction tickets.

## Acceptance criteria

- [x] Every Product retains exactly one Base Model and at least one active Variant.
- [x] Activating the first real Variant deactivates Base under a Product lock.
- [x] Deactivating or removing the last active real Variant reactivates Base under the same boundary.
- [x] Users and integrations cannot directly activate, deactivate, or remove Base, while Product-owned destruction still succeeds.
- [x] `assignable_variants` returns active real Variants or the active Base fallback exactly as specified.
- [x] `variant_repair_candidates` adds only same-Product deactivated real Variants and labels them historical.
- [x] New or changed Purchase and SaleItem identity normalizes missing Variant to assignable Base, requires an explicit real Variant otherwise, and rejects cross-Product identity.
- [x] An unchanged same-Product deactivated real Variant remains a valid historical reference.
- [x] Focused tests are written first and the complete repository verification gate passes.
