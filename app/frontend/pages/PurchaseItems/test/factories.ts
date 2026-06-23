import type {
  PurchaseItemFormOptions,
  PurchaseItemFormRecord,
  PurchaseItemShowRecord,
  SaleItemTableRow,
  WarehouseMovementRecord,
} from "../types";

export function makePurchaseItemFormOptions(
  overrides: Partial<PurchaseItemFormOptions> = {},
): PurchaseItemFormOptions {
  return {
    warehouses: [
      { value: 1, label: "Main Warehouse" },
      { value: 2, label: "Secondary Warehouse" },
    ],
    purchases: [
      { value: 10, label: "Supplier A | Product X | 2024-01-01" },
      { value: 11, label: "Supplier B | Product Y | 2024-02-01" },
    ],
    shipping_companies: [
      { value: 20, label: "DHL" },
      { value: 21, label: "FedEx" },
    ],
    ...overrides,
  };
}

export function makePurchaseItemFormRecord(
  overrides: Partial<PurchaseItemFormRecord> = {},
): PurchaseItemFormRecord {
  return {
    id: 42,
    path: "/purchase_items/42",
    purchase_id: 10,
    sale_item_id: null,
    warehouse_id: 1,
    shipping_company_id: 20,
    length: "30",
    width: "20",
    height: "15",
    weight: "2.5",
    expenses: "100.00",
    shipping_cost: "25.00",
    tracking_number: "TRK-001",
    media: [
      {
        id: 1,
        alt: "Item photo",
        position: 0,
        preview_url: "/item.png",
        thumb_url: "/item-thumb.png",
        _destroy: false,
      },
    ],
    redirect_to_sale_item: false,
    ...overrides,
  };
}

export function makeWarehouseMovementRecord(
  overrides: Partial<WarehouseMovementRecord> = {},
): WarehouseMovementRecord {
  return {
    id: 1,
    moved_in: "20 May 2026",
    warehouse_name: "Main Warehouse",
    warehouse_path: "/warehouses/1",
    ...overrides,
  };
}

export function makePurchaseItemShowRecord(
  overrides: Partial<PurchaseItemShowRecord> = {},
): PurchaseItemShowRecord {
  return {
    id: 42,
    path: "/purchase_items/42",
    edit_path: "/purchase_items/42/edit",
    destroy_path: "/purchase_items/42",
    purchase_path: "/purchases/10",
    purchase_title: "Purchase 10",
    sale_path: "/sales/7",
    sale_item_path: "/sale_items/9",
    supplier_title: "Supplier A",
    supplier_path: "/suppliers/3",
    product_title: "Product X",
    product_path: "/products/5",
    warehouse_name: "Main Warehouse",
    warehouse_path: "/warehouses/1",
    expenses: "100.00",
    shipping_cost: "25.00",
    tracking_number: "TRK-001",
    shipping_company_name: "DHL",
    length: "30",
    width: "20",
    height: "15",
    weight: "2.5",
    created_at: "20 May 2026",
    updated_at: "21 May 2026",
    media: [
      {
        id: 1,
        alt: "Item photo",
        position: 0,
        preview_url: "/item.png",
        thumb_url: "/item-thumb.png",
      },
    ],
    warehouse_movements: [makeWarehouseMovementRecord()],
    ...overrides,
  };
}

export function makePurchaseItemIndexRecord(overrides: Record<string, unknown> = {}) {
  return {
    id: 42,
    path: "/purchase_items/42",
    edit_path: "/purchase_items/42/edit",
    purchase_path: "/purchases/10",
    purchase_title: "Purchase 10",
    product_path: "/products/5",
    product_title: "Product X",
    variant_title: "Deluxe",
    warehouse_name: "Main Warehouse",
    warehouse_path: "/warehouses/1",
    sale_path: "/sales/7",
    sale_title: "Sale 7",
    customer_email: "dale@fbi.gov",
    tracking_number: "TRK-001",
    shipping_company_name: "DHL",
    shipping_cost: "25.00",
    updated_at: "21 May 2026",
    ...overrides,
  };
}

export function makeSaleItemTableRow(overrides: Partial<SaleItemTableRow> = {}): SaleItemTableRow {
  return {
    slot_key: "sale-item-1",
    sale_item_id: 9,
    sale_label: "Sale 7",
    sale_path: "/sales/7",
    warehouse: "Main Warehouse",
    warehouse_path: "/warehouses/1",
    linked_purchase_item: {
      id: 42,
      path: "/purchase_items/42",
      purchase_id: 10,
      purchase_path: "/purchases/10",
      supplier_title: "Supplier A",
      purchase_date: "20 May 2026",
      item_price: "100.00",
    },
    is_current: false,
    is_available: false,
    link_path: "/purchase_items/42/link",
    unlink_path: "/purchase_items/42/unlink_sale_item",
    ...overrides,
  };
}
