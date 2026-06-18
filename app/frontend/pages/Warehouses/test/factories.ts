import type { WarehouseRecord } from "../Index/Table";
import type {
  WarehouseFormOptions,
  WarehouseFormRecord,
  WarehousePurchaseItemRecord,
  WarehouseShowRecord,
} from "../types";

export function makeWarehouseRecord(overrides: Partial<WarehouseRecord> = {}): WarehouseRecord {
  return {
    id: 1,
    path: "/warehouses/1",
    edit_path: "/warehouses/1/edit",
    position_path: "/warehouses/1/position",
    position: 1,
    positions: [1, 2],
    name: "Main Warehouse",
    is_default: false,
    external_name_en: "Main Warehouse EN",
    cbm: "12.5",
    purchase_items_count: 42,
    has_purchase_items: true,
    payment_progress: { progress: 50, paid: "$500", price: "$1000", debt: "$500" },
    ...overrides,
  };
}

export function makeWarehouseShowRecord(
  overrides: Partial<WarehouseShowRecord> = {},
): WarehouseShowRecord {
  return {
    id: 1,
    name: "Main Warehouse",
    edit_path: "/warehouses/1/edit",
    destroy_path: "/warehouses/1",
    new_item_path: "/warehouses/1/items/new",
    external_name_en: "Main Warehouse EN",
    desc_en: "English description",
    external_name_de: "Hauptlager",
    desc_de: "Deutsche Beschreibung",
    cbm: "12.5",
    container_tracking_number: "CONT-001",
    courier_tracking_url: "https://tracking.example/container",
    is_default: false,
    created_at: "01 Jun 2026",
    media: [],
    payment_progress: { progress: 0, paid: "", price: "", debt: "$0" },
    ...overrides,
  };
}

export function makeWarehousePurchaseItem(
  overrides: Partial<WarehousePurchaseItemRecord> = {},
): WarehousePurchaseItemRecord {
  return {
    id: 10,
    path: "/purchase_items/10",
    title: "Jacket",
    variant_title: "",
    sku: "SKU-10",
    sale_path: null,
    sale_title: "",
    sale_store_type: null,
    sale_summary: "",
    sale_note: "",
    customer_email: "buyer@example.com",
    tracking_number: "TRACK-1",
    shipping_company_id: null,
    shipping_company_name: "",
    payment_progress: { debt: "$0", paid: "$0", price: "$0", progress: 0 },
    ...overrides,
  };
}

export function makeWarehouseFormRecord(
  overrides: Partial<WarehouseFormRecord> = {},
): WarehouseFormRecord {
  return {
    id: 1,
    path: "/warehouses/1",
    name: "Main Warehouse",
    external_name_en: "Warehouse",
    external_name_de: "Lager",
    desc_en: "English description",
    desc_de: "Deutsche Beschreibung",
    cbm: "12.5",
    container_tracking_number: "CONT-1",
    courier_tracking_url: "https://tracking.example/package",
    is_default: false,
    position: 2,
    media: [
      {
        alt: "Warehouse front",
        id: 1,
        position: 0,
        preview_url: "/warehouse.png",
        thumb_url: "/warehouse-thumb.png",
        _destroy: false,
      },
    ],
    transition_ids: [10],
    ...overrides,
  };
}

export function makeWarehouseFormOptions(
  overrides: Partial<WarehouseFormOptions> = {},
): WarehouseFormOptions {
  return {
    positions: [1, 2, 3],
    transition_destinations: [
      { id: 10, name: "Berlin Warehouse" },
      { id: 20, name: "Tokyo Warehouse" },
    ],
    ...overrides,
  };
}

