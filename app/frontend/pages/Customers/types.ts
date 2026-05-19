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

export type CustomerErrors = Partial<
  Record<"email" | "first_name" | "last_name" | "phone" | "base", string[]>
>;

export type SaleRecord = {
  id: number;
  path: string;
  store_id: string;
  store_type: "shopify" | "woo" | null;
  status: string;
  active: boolean;
  total: string;
  country: string;
  city: string;
  note: string;
  created_at: string;
  updated_at: string;
};

export type PaginationMeta = {
  current_page: number;
  total_pages: number;
  total_count: number;
  limit: number;
};
