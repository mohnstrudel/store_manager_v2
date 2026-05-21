export type PaginationMeta = {
  current_page: number;
  total_pages: number;
  total_count: number;
  limit: number;
};

export type SaleIndexPurchaseItemRecord = {
  id: number;
  path: string;
  warehouse_name: string;
  expenses: string;
};

export type SaleIndexSaleItemRecord = {
  id: number;
  title: string;
  qty: number;
  purchased_count: number;
  product_thumb_url: string | null;
  purchase_items: SaleIndexPurchaseItemRecord[];
};

export type SaleIndexRecord = {
  id: number;
  path: string;
  customer_name: string;
  customer_email: string;
  sale_items: SaleIndexSaleItemRecord[];
  total: string;
  created_at: string;
  updated_at: string;
  active: boolean;
  completed: boolean;
  shopify_name: string;
  shopify_id: string;
  shopify_id_short: string;
  woo_store_id: string;
};

export type SaleAddressRecord = {
  address_1: string;
  address_2: string;
  city: string;
  company: string;
  country: string;
  email: string;
  first_name: string;
  last_name: string;
  phone: string;
  postcode: string;
  state: string;
};

export type SalePurchaseMovementRecord = {
  moved_in: string;
  warehouse_name: string;
};

export type SaleShowPurchaseItemRecord = {
  id: number;
  path: string;
  supplier_title: string;
  purchase_date: string;
  item_price: string;
  unlink_path: string;
  current_warehouse_name: string;
  current_warehouse_path: string;
  warehouse_movements: SalePurchaseMovementRecord[];
};

export type SaleShowSaleItemRecord = {
  id: number;
  title: string;
  price: string;
  qty: number;
  product_path: string;
  product_thumb_url: string | null;
  purchase_items: SaleShowPurchaseItemRecord[];
};

export type SaleCustomerRecord = {
  id: number;
  first_name: string;
  last_name: string;
  full_name: string;
  email: string;
  shopify_id_short: string;
  shop_admin_url: string;
};

export type SaleShowRecord = {
  id: number;
  path: string;
  edit_path: string;
  pull_path: string;
  link_purchase_items_path: string;
  can_link_purchase_items: boolean;
  shop_admin_url: string;
  status: string;
  active: boolean;
  completed: boolean;
  total: string;
  discount_total: string;
  shipping_total: string;
  note: string;
  created_at: string;
  updated_at: string;
  shopify_name: string;
  shopify_id: string;
  shopify_id_short: string;
  woo_store_id: string;
  shop_identifier: string;
  billing_differs_from_shipping: boolean;
  customer: SaleCustomerRecord;
  shipping_address: SaleAddressRecord | null;
  billing_address: SaleAddressRecord | null;
  sale_items: SaleShowSaleItemRecord[];
};
