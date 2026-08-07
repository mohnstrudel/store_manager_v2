# 06. Constraint contraction and cleanup

Spec: ../spec.md
Status: in progress
Blocked by: 05
Live blocker: 44 Purchases and 81 SaleItems still fail the zero gate; final contraction and nil-fallback removal remain staged.

## What to build

Gate final schema contraction on a zero-result integrity audit, apply the permanent Product/Variant constraints, and remove legacy nil-Variant behavior from domain projections and linking.

## Acceptance criteria

- [x] Constraint application refuses to proceed while any assignment-integrity count is nonzero or any unlinked PurchaseItem differs from its Purchase identity.
- [ ] Purchase, SaleItem, and PurchaseItem Product/Variant identity is non-null.
- [ ] Composite Product/Variant foreign keys enforce same-Product identity and exact PurchaseItem link identity.
- [ ] The database enforces one Base Model per Product.
- [ ] Nonblank Variant StoreInfo external identity is unique within its store scope.
- [x] Variant deletion behavior cannot nullify required historical identity and Product-owned destruction remains valid.
- [ ] Legacy nil-Variant fallbacks are removed from linking, titles, profitability, debt reporting, and sold-item resolution.
- [x] Obsolete generated route modules from retired Variant endpoints are removed and generated exports contain only live routes.
- [ ] The live integrity query reports zero issues after the final migration in the verified environment.
- [ ] Focused constraint, migration, model, reporting, profitability, linking, and integration regression tests pass.

## Focused verification

```bash
mise exec -- bin/rspec spec/models/variant/assignment_contraction_gate_spec.rb spec/models/variant_assignment_constraints_spec.rb spec/models/variant_assignment_contraction_artifact_spec.rb spec/models/variant_assignment_spec.rb spec/models/purchase_item/identity_reconciliation_spec.rb spec/models/purchase_item/exact_linking_spec.rb spec/models/sale_item/linkability_spec.rb spec/models/product/profitability_spec.rb spec/models/sale/profitability_spec.rb spec/models/product_sales_history_spec.rb spec/models/sale_linking_spec.rb
```
