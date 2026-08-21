import type { SalePaymentPlanRecord } from "@/types/payment";

export type CustomerRecord = {
  id: number | null;
  first_name: string;
  last_name: string;
  full_name: string;
  email: string;
  phone: string;
  woo_store_id: string;
  created_at: string | null;
  updated_at: string | null;
  path: string;
};

export type CustomerDetailRecord = CustomerRecord & {
  shopify_id: string;
  shopify_id_short: string;
};

export type SaleRecord = {
  id: number;
  path: string;
  payment_plans: SalePaymentPlanRecord[];
  partially_paid: boolean;
  store_id: string;
  sale_identifier: string;
  sold_product_name: string;
  product_thumb_url: string | null;
  store_type: "shopify" | "woo" | null;
  status: string;
  active: boolean;
  total: string;
  country: string;
  city: string;
  note: string;
  created_at: string;
  updated_at: string;
  // Decided once on the server (Sale#follow_up_payment?); see Sales/types.ts.
  is_follow_up_payment: boolean;
};

export type PaginationMeta = {
  current_page: number;
  total_pages: number;
  total_count: number;
  limit: number;
};
