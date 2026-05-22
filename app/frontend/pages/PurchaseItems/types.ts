import type { MediaRecord } from "@/pages/Products/types";

export type WarehouseMovementRecord = {
  id: number;
  moved_in: string;
  warehouse_name: string;
  warehouse_path: string | null;
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
