import type {
  SaleAddressFormRecord,
  SaleAddressRecord,
  SaleCustomerRecord,
  SaleFormOptions,
  SaleFormRecord,
  SaleIndexPurchaseItemRecord,
  SaleIndexRecord,
  SaleIndexSaleItemRecord,
  SaleItemFormRecord,
  SalePurchaseMovementRecord,
  SaleShowPurchaseItemRecord,
  SaleShowRecord,
  SaleShowSaleItemRecord,
} from "../types";

export function makeSaleIndexPurchaseItem(
  overrides: Partial<SaleIndexPurchaseItemRecord> = {},
): SaleIndexPurchaseItemRecord {
  return {
    id: 101,
    path: "/purchase_items/101",
    warehouse_name: "Berlin Hub",
    expenses: "9.99",
    ...overrides,
  };
}

export function makeSaleIndexSaleItem(
  overrides: Partial<SaleIndexSaleItemRecord> = {},
): SaleIndexSaleItemRecord {
  return {
    id: 11,
    title: "Pikachu Figure",
    qty: 2,
    purchased_count: 1,
    product_thumb_url: null,
    purchase_items: [makeSaleIndexPurchaseItem()],
    ...overrides,
  };
}

export function makeSaleIndexRecord(overrides: Partial<SaleIndexRecord> = {}): SaleIndexRecord {
  return {
    id: 1,
    path: "/sales/1",
    customer_name: "Dale Cooper",
    customer_email: "dale@fbi.gov",
    sale_items: [makeSaleIndexSaleItem()],
    total: "1060",
    created_at: "20. May '26 10:00",
    updated_at: "20. May '26 11:00",
    active: true,
    completed: false,
    shopify_name: "HSCM#1746",
    shopify_id: "gid://shopify/Order/7383283466569",
    shopify_id_short: "7383283466569",
    woo_store_id: "WOO-1",
    ...overrides,
  };
}

export function makeSaleAddress(overrides: Partial<SaleAddressRecord> = {}): SaleAddressRecord {
  return {
    address_1: "123 Main St",
    address_2: "",
    city: "Bremerhaven",
    company: "",
    country: "DE",
    email: "dale@fbi.gov",
    first_name: "Dale",
    last_name: "Cooper",
    phone: "+4912345",
    postcode: "27570",
    state: "",
    ...overrides,
  };
}

export function makeSaleAddressForm(
  overrides: Partial<SaleAddressFormRecord> = {},
): SaleAddressFormRecord {
  return {
    first_name: "",
    last_name: "",
    email: "",
    phone: "",
    company: "",
    address_1: "",
    address_2: "",
    city: "",
    state: "",
    postcode: "",
    country: "",
    ...overrides,
  };
}

export function makeSaleCustomer(overrides: Partial<SaleCustomerRecord> = {}): SaleCustomerRecord {
  return {
    id: 2,
    path: "/customers/2",
    first_name: "Dale",
    last_name: "Cooper",
    full_name: "Dale Cooper",
    email: "dale@fbi.gov",
    shopify_id_short: "9341147185481",
    shop_admin_url: "https://admin.shopify.com/store/68d8f5-af/customers/9341147185481",
    ...overrides,
  };
}

export function makeSalePurchaseMovement(
  overrides: Partial<SalePurchaseMovementRecord> = {},
): SalePurchaseMovementRecord {
  return {
    moved_in: "18. May '26 08:30",
    warehouse_name: "Berlin Hub",
    ...overrides,
  };
}

export function makeSaleShowPurchaseItem(
  overrides: Partial<SaleShowPurchaseItemRecord> = {},
): SaleShowPurchaseItemRecord {
  return {
    id: 101,
    path: "/purchases/55",
    supplier_title: "Acme Imports",
    purchase_date: "18. May '26",
    item_price: "1030",
    unlink_path: "/purchase_items/101/unlink",
    current_warehouse_name: "Berlin Hub",
    current_warehouse_path: "/warehouses/1?selected=101#101",
    warehouse_movements: [makeSalePurchaseMovement()],
    ...overrides,
  };
}

export function makeSaleShowSaleItem(
  overrides: Partial<SaleShowSaleItemRecord> = {},
): SaleShowSaleItemRecord {
  return {
    id: 11,
    title: "Pikachu Figure",
    price: "1060",
    qty: 2,
    product_path: "/products/pikachu",
    product_thumb_url: null,
    purchase_items: [makeSaleShowPurchaseItem()],
    ...overrides,
  };
}

export function makeSaleShow(overrides: Partial<SaleShowRecord> = {}): SaleShowRecord {
  return {
    id: 1,
    path: "/sales/1",
    edit_path: "/sales/1/edit",
    pull_path: "/sales/1/pull",
    link_purchase_items_path: "/sales/1/link_purchase_items",
    can_link_purchase_items: true,
    shop_admin_url: "https://admin.shopify.com/store/68d8f5-af/orders/7383283466569",
    status: "processing",
    active: true,
    completed: false,
    total: "1060",
    discount_total: "0",
    shipping_total: "20",
    note: "Leave at the door",
    created_at: "20. May '26",
    updated_at: "20. May '26",
    shopify_name: "HSCM#1746",
    shopify_id: "gid://shopify/Order/7383283466569",
    shopify_id_short: "7383283466569",
    woo_store_id: "WOO-1",
    shop_identifier: "HSCM#1746",
    billing_differs_from_shipping: true,
    warehouses: [
      { id: 1, name: "Berlin Hub" },
      { id: 2, name: "Paris Hub" },
    ],
    warehouse_move_path: "/purchase_items/move",
    customer: makeSaleCustomer(),
    shipping_address: makeSaleAddress(),
    billing_address: makeSaleAddress({
      address_1: "456 Side St",
      city: "Paris",
      country: "FR",
      postcode: "75001",
    }),
    sale_items: [makeSaleShowSaleItem()],
    ...overrides,
  };
}

export function makeSaleItemForm(overrides: Partial<SaleItemFormRecord> = {}): SaleItemFormRecord {
  return {
    id: null,
    product_id: null,
    qty: "",
    price: "",
    _destroy: false,
    ...overrides,
  };
}

export function makeSaleForm(overrides: Partial<SaleFormRecord> = {}): SaleFormRecord {
  return {
    id: null,
    path: "",
    status: "processing",
    customer_id: null,
    note: "",
    total: "",
    discount_total: "",
    shipping_total: "",
    shipping_address: makeSaleAddressForm(),
    billing_address: makeSaleAddressForm(),
    sale_items: [],
    ...overrides,
  };
}

export function makeSaleFormOptions(overrides: Partial<SaleFormOptions> = {}): SaleFormOptions {
  return {
    customers: [{ value: 1, label: "Ada Lovelace" }],
    products: [{ value: 2, label: "Moon Statue" }],
    status_names: ["processing"],
    ...overrides,
  };
}
