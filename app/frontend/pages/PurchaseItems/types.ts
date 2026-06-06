import type { MediaFormData, MediaRecord } from "@/pages/Products/types";

export type WarehouseMovementRecord = {
  id: number;
  moved_in: string;
  warehouse_name: string;
  warehouse_path: string | null;
};

export type SelectOption = {
  value: number;
  label: string;
};

export type SaleItemTableRow = {
  slot_key: string;
  sale_item_id: number;
  sale_label: string;
  sale_path: string;
  warehouse: string | null;
  warehouse_path: string | null;
  linked_purchase_item: {
    id: number;
    path: string;
    purchase_id: number;
    purchase_path: string;
    supplier_title: string;
    purchase_date: string;
    item_price: string | null;
  } | null;
  is_current: boolean;
  is_available: boolean;
  link_path: string;
  unlink_path: string;
};

export type PurchaseItemFormRecord = {
  id: number | null;
  path: string;
  purchase_id: number | null;
  sale_item_id: number | null;
  warehouse_id: number | null;
  shipping_company_id: number | null;
  length: string;
  width: string;
  height: string;
  weight: string;
  expenses: string;
  shipping_cost: string;
  tracking_number: string;
  media: MediaFormData[];
  redirect_to_sale_item: boolean;
};

export type PurchaseItemFormOptions = {
  warehouses: SelectOption[];
  purchases: SelectOption[];
  shipping_companies: SelectOption[];
};

export type PurchaseItemShowRecord = {
  id: number;
  path: string;
  edit_path: string;
  destroy_path: string;
  purchase_path: string;
  purchase_title: string;
  sale_path: string | null;
  sale_item_path: string | null;
  supplier_title: string;
  supplier_path: string;
  product_title: string;
  product_path: string | null;
  warehouse_name: string;
  warehouse_path: string;
  expenses: string;
  shipping_cost: string;
  tracking_number: string;
  shipping_company_name: string;
  length: string;
  width: string;
  height: string;
  weight: string;
  created_at: string;
  updated_at: string;
  media: MediaRecord[];
  warehouse_movements: WarehouseMovementRecord[];
};
