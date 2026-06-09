export type { PaginationMeta } from "@/types/pagination";
import type { MediaRecord, MediaFormData } from "@/types/media";
export type { MediaRecord, MediaFormData };

export type VariantSummary = {
  id: number;
  title: string;
};

export type ProductIndexRecord = {
  id: number;
  title: string;
  full_title: string;
  path: string;
  edit_path: string;
  thumb_url: string | null;
  variants: VariantSummary[];
  woo_store_id: string;
  shopify_id_short: string;
  new_purchase_path: string;
};

export type ShopifyInfo = {
  store_id: string | null;
  id_short: string | null;
  tag_list: string[];
  product_url: string | null;
};

export type WooInfo = {
  store_id: string | null;
  product_url: string | null;
};

export type TimestampColumn = {
  key: string;
  label: string;
  value: string;
};

export type VariantRecord = {
  id: number;
  title: string;
  types_name: string;
  weight: number;
  purchase_cost: number;
  selling_price: number;
  deactivated: boolean;
  active_sales_count: number;
  purchases_count: number;
  shopify_id_short: string;
  woo_store_id: string;
};

export type SaleItemRecord = {
  id: number;
  sale_path: string;
  store_type: "shopify" | "woo" | null;
  store_id: string;
  customer_name: string;
  customer_email: string;
  country: string;
  date: string;
  variant_title: string | null;
  price: string;
  qty: number;
  status: string;
  warehouse: string;
  purchase_item_path: string | null;
};

export type PurchaseWarehouse = {
  id: number;
  name: string;
};

export type PurchaseRecord = {
  id: number;
  path: string;
  supplier: string;
  order_reference: string;
  variant_title: string | null;
  item_price: string;
  amount: number;
  created_at: string;
  warehouses: PurchaseWarehouse[];
};

export type ProductShowRecord = {
  id: number;
  title: string;
  full_title: string;
  path: string;
  edit_path: string;
  franchise: { id: number; title: string };
  brands: { id: number; title: string }[];
  sizes: { id: number; value: string }[];
  versions: { id: number; value: string }[];
  colors: { id: number; value: string }[];
  shape: string;
  description_html: string;
  media: MediaRecord[];
  shopify_info: ShopifyInfo | null;
  woo_info: WooInfo | null;
  created_at_columns: TimestampColumn[];
  updated_at_columns: TimestampColumn[];
  shopify_linked: boolean;
  can_pull_from_shopify: boolean;
  shopify_pull_path: string;
  new_purchase_path: string;
};

export type SelectOption<Value extends string | number = string | number> = {
  value: Value;
  label: string;
};

export type FormOptions = {
  franchises: SelectOption<number>[];
  brands: SelectOption<number>[];
  shapes: string[];
  sizes: SelectOption<number>[];
  versions: SelectOption<number>[];
  colors: SelectOption<number>[];
  suppliers: SelectOption<number>[];
  warehouses: SelectOption<number>[];
  store_names: string[];
};

export type VariantFormData = {
  id: number | null;
  sku: string;
  size_id: number | null;
  version_id: number | null;
  color_id: number | null;
  purchase_cost: string;
  selling_price: string;
  weight: string;
  deactivated: boolean;
  has_sales_or_purchases: boolean;
  _destroy: boolean;
};

export type StoreInfoFormData = {
  id: number | null;
  store_name: string;
  tag_list: string;
  _destroy: boolean;
};

export type PurchaseFormData = {
  supplier_id: number | null;
  order_reference: string;
  item_price: string;
  amount: string;
  warehouse_id: number | null;
  payment_value: string;
};

export type ProductFormData = {
  title: string;
  description_html: string;
  franchise_id: number | null;
  shape: string;
  brand_ids: number[];
};

export type ProductFormRecord = {
  id: number | null;
  title: string;
  description_html: string;
  franchise_id: number | null;
  shape: string;
  brand_ids: number[];
  path: string;
  variants: VariantFormData[];
  store_infos: StoreInfoFormData[];
  media: MediaFormData[];
};
