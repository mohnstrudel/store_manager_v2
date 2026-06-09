import type { WarehouseOption } from "@/types/warehouse";

export type SaleItemShowRecord = {
  id: number;
  title: string;
  qty: number;
  price: string;
  product_path: string;
  sale_path: string;
};

export type SaleItemPurchaseItemRecord = {
  id: number;
  path: string;
  edit_path: string;
  unlink_path: string;
  warehouse_name: string;
  size: string;
  weight: string;
  expenses: string;
  shipping_cost: string;
};

export type { WarehouseOption };
