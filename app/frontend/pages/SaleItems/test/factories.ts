import type { SaleItemPurchaseItemRecord, SaleItemShowRecord, WarehouseOption } from "../types";

export function makeSaleItemShowRecord(
  overrides: Partial<SaleItemShowRecord> = {},
): SaleItemShowRecord {
  return {
    id: 9,
    title: "Pikachu Figure",
    qty: 2,
    price: "1060",
    product_path: "/products/5",
    sale_path: "/sales/7",
    ...overrides,
  };
}

export function makeSaleItemPurchaseItemRecord(
  overrides: Partial<SaleItemPurchaseItemRecord> = {},
): SaleItemPurchaseItemRecord {
  return {
    id: 42,
    path: "/purchase_items/42",
    edit_path: "/purchase_items/42/edit",
    unlink_path: "/purchase_items/42/unlink_sale_item",
    warehouse_name: "Main Warehouse",
    size: "30 x 20 x 15",
    weight: "2.5",
    expenses: "100.00",
    shipping_cost: "25.00",
    ...overrides,
  };
}

export function makeWarehouseOption(overrides: Partial<WarehouseOption> = {}): WarehouseOption {
  return {
    id: 1,
    name: "Main Warehouse",
    ...overrides,
  };
}
