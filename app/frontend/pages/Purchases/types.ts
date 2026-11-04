import type {
  PurchasesDetail,
  PurchasesExpense,
  PurchasesForm,
  PurchasesListing,
  PurchasesPayment,
  PurchasesPurchaseItem,
  PurchasesShow,
  ShippingCompanyOption,
} from "@/types/serializers";

export type { PaginationMeta } from "@/types/pagination";
export type { WarehouseOption } from "@/types/warehouse";
export type { ShippingCompanyOption };

export type PurchaseIndexRecord = PurchasesListing;

export type PurchaseShowRecord = PurchasesDetail;

export type PurchaseItemRecord = PurchasesPurchaseItem;

export type PaymentRecord = PurchasesPayment;

export type NewPaymentRecord = PurchasesShow["new_payment"];

export type PurchaseItemExpenseRecord = PurchasesExpense;

export type NewPurchaseItemExpenseRecord = PurchasesPurchaseItem["new_purchase_expense"];

export type PurchaseFormRecord = PurchasesForm["purchase"];

export type PurchaseFormOptions = PurchasesForm["options"];
