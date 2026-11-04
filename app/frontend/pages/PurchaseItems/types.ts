import type {
  PurchaseItemsDetail,
  PurchaseItemsEdit,
  PurchaseItemsFormRecord,
  PurchaseItemsListing,
  PurchaseItemsNew,
} from "@/types/serializers";

export type PurchaseItemIndexRecord = PurchaseItemsListing;

export type WarehouseMovementRecord = PurchaseItemsDetail["warehouse_movements"][number];

export type PurchaseItemFormOptions = PurchaseItemsNew["options"];

export type SelectOption = PurchaseItemFormOptions["warehouses"][number];

export type SaleItemTableRow = PurchaseItemsEdit["sale_items_table"][number];

export type PurchaseItemFormRecord = PurchaseItemsFormRecord;

export type PurchaseItemShowRecord = PurchaseItemsDetail;
