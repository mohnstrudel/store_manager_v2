/** The purchase_item fields the shared inline cell editors read and write. */
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

/** Collection prop, strong-params key, and id param shared by every purchase_item cell route. */
export const purchaseItemResource = {
  collection: "purchase_items",
  paramKey: "purchase_item",
  idParam: "purchase_item_id",
} as const;
