import type { PaymentProgress, SalePaymentPlanRecord } from "@/types/payment";
import type { VariantAvailability } from "@/types/variantAssignment";
import type { WarehouseOption } from "@/types/warehouse";

export type SelectOption<Value extends string | number = string | number> = {
  value: Value;
  label: string;
};

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

export type SalePaymentRecord = PaymentProgress & {
  payment_overdue: boolean;
};

export type SaleIndexRecord = {
  id: number;
  path: string;
  customer_name: string;
  customer_email: string;
  sale_items: SaleIndexSaleItemRecord[];
  created_at: string;
  updated_at: string;
  active: boolean;
  completed: boolean;
  shopify_name: string;
  shopify_id: string;
  shopify_id_short: string;
  woo_store_id: string;
  payment: SalePaymentRecord;
  payment_plans: SalePaymentPlanRecord[];
  partially_paid: boolean;
  // Decided once on the server (Sale#follow_up_payment?); see SaleShowRecord.
  is_follow_up_payment: boolean;
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

export type SaleItemProfitabilityRecord = {
  expected_revenue: string | null;
  purchase_cost: string | null;
  expected_final_profit: string | null;
};

export type SaleProfitabilityScope = "plan" | "sale";

export type SaleProfitabilityRecord = {
  scope: SaleProfitabilityScope;
  gross_revenue: string | null;
  item_price_total: string | null;
  purchase_expenses: string | null;
  purchase_shipping_cost: string | null;
  direct_expenses: string | null;
  business_expenses: string | null;
  net_profit: string | null;
  collected_revenue: string | null;
  purchase_paid: string | null;
  cash_position: string | null;
};

export type SaleShowSaleItemRecord = {
  id: number;
  title: string;
  qty: number;
  product_path: string;
  product_thumb_url: string | null;
  purchase_items: SaleShowPurchaseItemRecord[];
  payment: PaymentProgress;
  profitability: SaleItemProfitabilityRecord | null;
};

export type SaleAddressFormRecord = {
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  company: string;
  address_1: string;
  address_2: string;
  city: string;
  state: string;
  postcode: string;
  country: string;
};

export type SaleItemFormRecord = {
  id: number | null;
  product_id: number | null;
  variant_id: number | null;
  qty: string;
  price: string;
  _destroy: boolean;
  variant_availability: VariantAvailability | null;
};

export type SaleFormRecord = {
  id: number | null;
  path: string;
  status: string;
  customer_id: number | null;
  note: string;
  total: string;
  discount_total: string;
  shipping_total: string;
  shipping_address: SaleAddressFormRecord;
  billing_address: SaleAddressFormRecord;
  sale_items: SaleItemFormRecord[];
};

export type SaleFormOptions = {
  customers: SelectOption<number>[];
  products: SelectOption<number>[];
  status_names: string[];
};

export type SaleCustomerRecord = {
  id: number;
  path: string;
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
  warehouses: WarehouseOption[];
  warehouse_move_path: string;
  edit_path: string;
  pull_path: string;
  link_purchase_items_path: string;
  can_link_purchase_items: boolean;
  shop_admin_url: string;
  status: string;
  active: boolean;
  completed: boolean;
  total: string;
  note: string;
  created_at: string;
  updated_at: string;
  shopify_name: string;
  shopify_id: string;
  shopify_id_short: string;
  woo_store_id: string;
  shop_identifier: string;
  is_follow_up_payment: boolean;
  discount_total?: string;
  shipping_total?: string;
  billing_differs_from_shipping?: boolean;
  customer: SaleCustomerRecord;
  shipping_address?: SaleAddressRecord | null;
  billing_address?: SaleAddressRecord | null;
  sale_items: SaleShowSaleItemRecord[];
  payment: SalePaymentRecord;
  payment_plans: SalePaymentPlanRecord[];
  partially_paid: boolean;
  profitability: SaleProfitabilityRecord | null;
};
