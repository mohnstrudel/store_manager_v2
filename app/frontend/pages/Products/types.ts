import type { MediaFormData } from "@/types/media";
import type {
  Pagination,
  ProductsDetail,
  ProductsForm,
  ProductsFormProduct,
  ProductsFormStoreInfo,
  ProductsFormVariant,
  ProductsListing,
  ProductsNew,
  ProductsPaymentItem,
  ProductsPurchase,
  ProductsSaleItem,
  ProductsShow,
  ProductsVariant,
} from "@/types/serializers";

export type { MediaFormData };

export type PaginationMeta = Pagination;

export type ProductIndexRecord = ProductsListing;

export type TimestampColumn = ProductsDetail["created_at_columns"][number];

export type VariantRecord = ProductsVariant;

export type SaleItemRecord = ProductsSaleItem;

export type PaymentItemRecord = ProductsPaymentItem;

export type PurchaseRecord = ProductsPurchase;

export type ProductShowRecord = ProductsDetail;

export type ProfitabilityRecord = NonNullable<ProductsShow["profitability"]>;

export type SelectOption<Value extends string | number = string | number> = {
  value: Value;
  label: string;
};

export type FormOptions = ProductsForm["options"];

export type VariantFormData = ProductsFormVariant;

export type StoreInfoFormData = Omit<ProductsFormStoreInfo, "store_name"> & { store_name: string };

export type PurchaseFormData = ProductsNew["purchase"];

export type ProductFormRecord = ProductsFormProduct;
