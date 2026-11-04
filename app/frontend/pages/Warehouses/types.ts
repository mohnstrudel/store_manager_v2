import type { PaginationMeta } from "@/types/pagination";
import type {
  ShippingCompanyOption,
  WarehousesDetail,
  WarehousesForm,
  WarehousesListing,
  WarehousesPurchaseItem,
} from "@/types/serializers";
import type { WarehouseOption } from "@/types/warehouse";

export type { PaginationMeta, ShippingCompanyOption, WarehouseOption };

export type WarehouseIndexRecord = WarehousesListing;

export type WarehouseShowRecord = WarehousesDetail;

export type WarehousePurchaseItemRecord = WarehousesPurchaseItem;

export type WarehouseFormRecord = WarehousesForm["warehouse"];

export type WarehouseFormOptions = WarehousesForm["options"];
