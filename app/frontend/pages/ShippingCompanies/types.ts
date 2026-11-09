import type {
  ShippingCompaniesNew,
  ShippingCompaniesPurchaseItem,
  ShippingCompany,
} from "@/types/serializers";

export type ShippingCompanyRecord = ShippingCompany;

export type ShippingCompanyFormRecord = ShippingCompaniesNew["shippingCompany"];

export type PurchaseItemRecord = ShippingCompaniesPurchaseItem;
