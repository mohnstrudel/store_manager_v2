import type { PurchaseRecord, SupplierRecord } from "../types";

export function makeSupplier(overrides: Partial<SupplierRecord> = {}): SupplierRecord {
  return {
    id: 1,
    title: "GoodSmile",
    created_at: "19. May '26 16:18",
    updated_at: "20. May '26 16:18",
    ...overrides,
  };
}

export function makeSupplierPurchase(overrides: Partial<PurchaseRecord> = {}): PurchaseRecord {
  return {
    id: 1,
    amount: 2,
    has_debt: true,
    debt: "12.50",
    item_price: "25.00",
    path: "/purchases/1",
    purchased_ago: "2 days ago",
    title: "Pokemon - Pikachu",
    variant: "Default",
    ...overrides,
  };
}
