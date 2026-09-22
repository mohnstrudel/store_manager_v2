import type {
  NewPaymentRecord,
  NewPurchaseItemExpenseRecord,
  PaymentRecord,
  PurchaseItemExpenseRecord,
  PurchaseFormOptions,
  PurchaseFormRecord,
  PurchaseIndexRecord,
  PurchaseItemRecord,
  PurchaseShowRecord,
  ShippingCompanyOption,
  WarehouseOption,
} from "../types";

export function makeWarehouseOption(overrides: Partial<WarehouseOption> = {}): WarehouseOption {
  return {
    id: 1,
    name: "Berlin Hub",
    ...overrides,
  };
}

export function makeShippingCompanyOption(
  overrides: Partial<ShippingCompanyOption> = {},
): ShippingCompanyOption {
  return {
    id: 3,
    name: "Skyline",
    ...overrides,
  };
}

export function makePurchaseIndexRecord(
  overrides: Partial<PurchaseIndexRecord> = {},
): PurchaseIndexRecord {
  return {
    id: 1,
    path: "/purchases/1",
    edit_path: "/purchases/1/edit",
    product_title: "Pikachu Figure",
    product_thumb_url: null,
    variant_title: "Default",
    order_reference: "PO-55",
    supplier_title: "Acme Imports",
    amount: 2,
    purchase_items_count: 1,
    warehouse_counts: [{ warehouse_name: "Berlin Hub", count: 1 }],
    payment_progress: {
      progress: 25,
      paid: "50.00",
      price: "210.00",
      debt: "160.00",
    },
    ...overrides,
  };
}

export function makePurchaseShow(overrides: Partial<PurchaseShowRecord> = {}): PurchaseShowRecord {
  return {
    id: 55,
    path: "/purchases/55",
    edit_path: "/purchases/55/edit",
    destroy_path: "/purchases/55",
    product_path: "/products/1",
    product_title: "Pikachu Figure",
    product_image_url: "/pikachu.jpg",
    product_thumb_url: null,
    variant_title: "Default",
    amount: 2,
    item_price: "100.00",
    cost_total: "210.00",
    shipping_total: "10.00",
    expenses_total: "5.00",
    paid: "50.00",
    debt: "160.00",
    supplier_title: "Acme Imports",
    supplier_path: "/suppliers/1",
    order_reference: "PO-55",
    date: "20 May 2026",
    payment_progress: {
      progress: 25,
      paid: "50.00",
      price: "210.00",
      debt: "160.00",
    },
    ...overrides,
  };
}

export function makePurchaseItem(overrides: Partial<PurchaseItemRecord> = {}): PurchaseItemRecord {
  return {
    id: 10,
    path: "/purchase_items/10",
    edit_path: "/purchase_items/10/edit",
    unlink_path: "/purchase_items/10/unlink",
    warehouse_name: "Warehouse A",
    warehouse_path: "/warehouses/1",
    warehouse_movements: [],
    sale_title: "",
    sale_path: null,
    sale_address: "",
    customer_email: "",
    tracking_number: "TRACK-1",
    shipping_company_id: null,
    shipping_company_name: "",
    shipping_cost: "0",
    purchase_expenses: [],
    new_purchase_expense: {
      description: "",
      amount: "",
      create_path: "/purchase_items/10/expenses",
    },
    ...overrides,
  };
}

export function makePayment(overrides: Partial<PaymentRecord> = {}): PaymentRecord {
  return {
    id: 1,
    update_path: "/purchases/55/payments/1",
    destroy_path: "/purchases/55/payments/1",
    payment_date: "2026-05-20",
    value: "10.00",
    ...overrides,
  };
}

export function makeNewPayment(overrides: Partial<NewPaymentRecord> = {}): NewPaymentRecord {
  return {
    create_path: "/purchases/55/payments",
    payment_date: "2026-05-21",
    value: "10.00",
    ...overrides,
  };
}

export function makeNewPurchaseItemExpense(
  overrides: Partial<NewPurchaseItemExpenseRecord> = {},
): NewPurchaseItemExpenseRecord {
  return {
    description: "",
    amount: "",
    create_path: "/purchase_items/10/expenses",
    ...overrides,
  };
}

export function makePurchaseItemExpense(
  overrides: Partial<PurchaseItemExpenseRecord> = {},
): PurchaseItemExpenseRecord {
  return {
    id: 1,
    description: "Extra tax",
    amount: "10",
    update_path: "/purchase_items/10/expenses/1",
    destroy_path: "/purchase_items/10/expenses/1",
    ...overrides,
  };
}

export function makePurchaseForm(overrides: Partial<PurchaseFormRecord> = {}): PurchaseFormRecord {
  return {
    id: null,
    path: "",
    product_id: null,
    variant_id: null,
    supplier_id: null,
    order_reference: "",
    item_price: "",
    amount: "",
    warehouse_id: null,
    payment_value: "",
    variant_availability: null,
    ...overrides,
  };
}

export function makePurchaseFormOptions(
  overrides: Partial<PurchaseFormOptions> = {},
): PurchaseFormOptions {
  return {
    products: [{ value: 1, label: "Moon Statue" }],
    suppliers: [{ value: 10, label: "Acme Supplies" }],
    warehouses: [{ value: 20, label: "Main Warehouse" }],
    ...overrides,
  };
}
