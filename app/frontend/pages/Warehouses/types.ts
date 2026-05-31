import type { MediaFormData, MediaRecord } from "@/pages/Products/types";
import type { PaginationMeta, PaymentProgress, WarehouseOption } from "@/pages/Purchases/types";

export type WarehouseShowRecord = {
  id: number;
  name: string;
  edit_path: string;
  destroy_path: string;
  new_item_path: string;
  external_name_en: string;
  desc_en: string;
  external_name_de: string;
  desc_de: string;
  cbm: string;
  container_tracking_number: string;
  courier_tracking_url: string;
  is_default: boolean;
  created_at: string;
  media: MediaRecord[];
  payment_progress: PaymentProgress;
};

export type WarehousePurchaseItemRecord = {
  id: number;
  path: string;
  title: string;
  variant_title: string;
  sku: string;
  sale_path: string | null;
  sale_title: string;
  sale_store_type: "shopify" | "woo" | null;
  sale_summary: string;
  sale_note: string;
  customer_email: string;
  tracking_number: string;
  tracking_edit_path: string;
  shipping_company_name: string;
  shipping_company_edit_path: string;
  payment_progress: PaymentProgress;
};

export type { PaginationMeta, WarehouseOption };

export type WarehouseFormRecord = {
  id: number | null;
  path: string;
  name: string;
  external_name_en: string;
  external_name_de: string;
  desc_en: string;
  desc_de: string;
  cbm: string;
  container_tracking_number: string;
  courier_tracking_url: string;
  is_default: boolean;
  position: number;
  media: MediaFormData[];
  transition_ids: number[];
};

export type WarehouseFormOptions = {
  positions: number[];
  transition_destinations: WarehouseOption[];
};
