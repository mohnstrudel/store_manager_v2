import type { PurchaseItemRecord, ShippingCompanyRecord } from "../types";

export function makeShippingCompany(
  overrides: Partial<ShippingCompanyRecord> = {},
): ShippingCompanyRecord {
  return {
    id: 1,
    name: "DHL",
    tracking_url: "https://dhl.com/track",
    created_at: "19. May '26 16:18",
    updated_at: "20. May '26 16:18",
    ...overrides,
  };
}

export function makeShippingCompanyPurchaseItem(
  overrides: Partial<PurchaseItemRecord> = {},
): PurchaseItemRecord {
  return {
    id: 1,
    path: "/purchase_items/1",
    product_full_title: "Pokemon - Pikachu",
    purchased_ago: "2 days ago",
    tracking_number: "TRACK123",
    ...overrides,
  };
}
