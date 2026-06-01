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
  sale_items: SelectOption[];
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
  product_path: string;
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
