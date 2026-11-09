import type { Customer, CustomersDetail, CustomersNew, CustomersSale } from "@/types/serializers";

export type CustomerRecord = Customer;

export type CustomerFormRecord = CustomersNew["customer"];

export type CustomerDetailRecord = CustomersDetail;

export type SaleRecord = CustomersSale;
