export type ShippingCompanyRecord = {
  created_at: string | null;
  id: number | null;
  name: string;
  tracking_url: string | null;
  updated_at: string | null;
};


export type PurchaseItemRecord = {
  id: number;
  path: string;
  product_full_title: string;
  purchased_ago: string;
  tracking_number: string;
};
