export type PurchaseItemCellRecord = {
  id: number;
  tracking_number: string;
  shipping_company_id: number | null;
  shipping_company_name: string;
};

export type ShippingCompanyOption = {
  id: number;
  name: string;
};

export const purchaseItemResource = {
  collection: "purchase_items",
  paramKey: "purchase_item",
  idParam: "purchase_item_id",
} as const;
