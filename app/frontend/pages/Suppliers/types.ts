export type SupplierRecord = {
  created_at: string | null;
  id: number | null;
  updated_at: string | null;
  title: string;
};


export type PurchaseRecord = {
  amount: number;
  has_debt: boolean;
  debt: string | null;
  id: number;
  item_price: string | null;
  path: string;
  purchased_ago: string;
  title: string;
  variant: string;
};
