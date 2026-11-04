import type { Supplier, SuppliersNew, SuppliersPurchase } from "@/types/serializers";

export type SupplierRecord = Supplier;

export type SupplierFormRecord = SuppliersNew["supplier"];

export type PurchaseRecord = SuppliersPurchase;
