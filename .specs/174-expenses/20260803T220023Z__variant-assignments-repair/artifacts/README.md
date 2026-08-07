# Variant assignment contraction activation

The final migration is staged here so it does not create a pending migration
that blocks the live repair workspace while unresolved assignments remain.

Activate it only in this order:

1. Repair every row shown by `Variant Repairs`.
2. Run `Variant::AssignmentContractionGate.verify!` in the target environment.
3. Continue only when its complete snapshot is zero.
4. Move `20260731120000_contract_variant_assignments.rb` into `db/migrate/`.
5. Run the migration normally. Do not edit or bypass its gate.
6. Remove the legacy nil-Variant branches from:
   - `SaleItem::Linkability` linking and sold-item resolution;
   - `Purchase::Titling`, `SaleItem::Titling`, and their display projections;
   - `Product::Profitability#inventory_purchases`;
   - `DashboardDebtReporting`.
7. Run the final constraint specs and the complete repository verification
   gate twice.
