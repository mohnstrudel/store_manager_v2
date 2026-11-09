import type {
  Pagination,
  SaleAddress,
  SaleCustomer,
  SalesDetail,
  SalesDetailItem,
  SalesDetailPurchaseItem,
  SalesForm,
  SalesFormAddress,
  SalesFormItem,
  SalesIndex,
  SalesListing,
  SalesListingItem,
} from "@/types/serializers";

export type SelectOption<Value extends string | number = string | number> = {
  value: Value;
  label: string;
};

export type PaginationMeta = Pagination;

export type SaleIndexPurchaseItemRecord = SalesListingItem["purchase_items"][number];

export type SaleIndexSaleItemRecord = SalesListingItem;

export type SalePaymentRecord = SalesListing["payment"];

export type SaleSort = SalesIndex["sort"];

export type SalesFilters = SalesIndex["filters"];

export type SaleIndexRecord = SalesListing;

export type SaleAddressRecord = SaleAddress;

export type SalePurchaseMovementRecord = SalesDetailPurchaseItem["warehouse_movements"][number];

export type SaleShowPurchaseItemRecord = SalesDetailPurchaseItem;

export type SaleItemProfitabilityRecord = NonNullable<SalesDetailItem["profitability"]>;

export type SaleProfitabilityRecord = NonNullable<SalesDetail["profitability"]>;

export type SaleProfitabilityScope = SaleProfitabilityRecord["scope"];

export type SaleShowSaleItemRecord = SalesDetailItem;

export type SaleAddressFormRecord = SalesFormAddress;

export type SaleItemFormRecord = SalesFormItem;

export type SaleFormRecord = SalesForm["sale"];

export type SaleFormOptions = SalesForm["options"];

export type SaleCustomerRecord = SaleCustomer;

export type SaleShowRecord = SalesDetail;
