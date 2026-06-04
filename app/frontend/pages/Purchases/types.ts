export type PaginationMeta = {
  current_page: number;
  total_pages: number;
  total_count: number;
  limit: number;
};

export type WarehouseOption = {
  id: number;
  name: string;
};

export type SelectOption<Value extends string | number = string | number> = {
  value: Value;
  label: string;
};

export type PaymentProgress = {
  progress: number;
  paid: string;
  price: string;
  debt: string;
};

export type PurchaseIndexRecord = {
  id: number;
  path: string;
  edit_path: string;
  product_title: string;
  product_thumb_url: string | null;
  variant_title: string;
  order_reference: string;
  supplier_title: string;
  amount: number;
  purchase_items_count: number;
  warehouse_counts: Array<{ warehouse_name: string; count: number }>;
  payment_progress: PaymentProgress;
};

export type PurchaseShowRecord = {
  id: number;
  path: string;
  edit_path: string;
  destroy_path: string;
  product_path: string;
  product_title: string;
  product_image_url: string | null;
  product_thumb_url: string | null;
  variant_title: string;
  amount: number;
  item_price: string;
  cost_total: string;
  shipping_total: string;
  paid: string;
  debt: string;
  supplier_title: string;
  supplier_path: string;
  order_reference: string;
  date: string;
  payment_progress: PaymentProgress;
};

export type ShippingCompanyOption = {
  id: number;
  name: string;
};

export type WarehouseMovementRecord = {
  moved_in: string;
  warehouse_name: string;
};

export type PurchaseItemRecord = {
  id: number;
  path: string;
  edit_path: string;
  unlink_path: string;
  warehouse_name: string;
  warehouse_path: string;
  warehouse_movements: WarehouseMovementRecord[];
  sale_title: string;
  sale_path: string | null;
  sale_address: string;
  customer_email: string;
  tracking_number: string;
  shipping_company_id: number | null;
  shipping_company_name: string;
  shipping_cost: string;
};

export type PaymentRecord = {
  id: number;
  update_path: string;
  destroy_path: string;
  payment_date: string;
  value: string;
  errors: string[];
};

export type NewPaymentRecord = {
  create_path: string;
  payment_date: string;
  value: string;
  errors: string[];
};

export type PurchaseFormRecord = {
  id: number | null;
  path: string;
  product_id: number | null;
  variant_id: number | null;
  supplier_id: number | null;
  order_reference: string;
  item_price: string;
  amount: string;
  warehouse_id: number | null;
  payment_value: string;
  variant_options: SelectOption<number>[];
};

export type PurchaseFormOptions = {
  product_variants_path: string;
  products: SelectOption<number>[];
  suppliers: SelectOption<number>[];
  warehouses: SelectOption<number>[];
};
