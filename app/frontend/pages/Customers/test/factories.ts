import type {
  CustomerDetailRecord,
  CustomerFormRecord,
  CustomerRecord,
  SaleRecord,
} from "../types";

export function makeCustomerForm(overrides: Partial<CustomerFormRecord> = {}): CustomerFormRecord {
  return {
    first_name: null,
    last_name: null,
    email: null,
    phone: null,
    ...overrides,
  };
}

export function makeCustomerDetail(
  overrides: Partial<CustomerDetailRecord> = {},
): CustomerDetailRecord {
  return {
    ...makeCustomer(),
    shopify_id: "gid://shopify/Customer/1",
    shopify_id_short: "SHOP-1",
    ...overrides,
  };
}

export function makeCustomer(overrides: Partial<CustomerRecord> = {}): CustomerRecord {
  return {
    id: 1,
    first_name: "Dale",
    last_name: "Cooper",
    full_name: "Dale Cooper",
    email: "dale@fbi.gov",
    phone: "+1555000",
    woo_store_id: "WOO-1",
    created_at: "19. May '26 10:00",
    updated_at: "19. May '26 10:00",
    path: "/customers/1",
    ...overrides,
  };
}

export function makeCustomerSale(overrides: Partial<SaleRecord> = {}): SaleRecord {
  return {
    id: 10,
    path: "/sales/10",
    store_id: "1001",
    sale_identifier: "HSCM#1958",
    sold_product_name: "Twin Peaks Cherry Pie",
    product_thumb_url: null,
    store_type: "shopify",
    warehouses: [],
    total: "100.00",
    country: "DE",
    city: "Berlin",
    note: "",
    created_at: "19. May '26",
    updated_at: "19. May '26",
    payment_plans: [],
    payment_progress: null,
    partially_paid: false,
    settlement_status: null,
    is_follow_up_payment: false,
    ...overrides,
  };
}
