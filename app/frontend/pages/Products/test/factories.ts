import type {
  ProductFormRecord,
  ProductIndexRecord,
  ProductShowRecord,
  ProfitabilityRecord,
  PurchaseFormData,
  PurchaseRecord,
  SaleItemRecord,
  StoreInfoFormData,
  VariantFormData,
  VariantRecord,
} from "../types";

export function makeProduct(overrides: Partial<ProductShowRecord> = {}): ProductShowRecord {
  return {
    id: 1,
    title: "Pikachu",
    full_title: "Pokemon - Pikachu",
    path: "/products/1",
    edit_path: "/products/1/edit",
    franchise: { id: 1, title: "Pokemon" },
    brands: [{ id: 1, title: "Nendoroid" }],
    sizes: [{ id: 1, value: "1/7" }],
    versions: [{ id: 1, value: "Classic" }],
    colors: [{ id: 1, value: "Yellow" }],
    shape: "Figure",
    description_html: "<p>A very electric mouse.</p>",
    media: [
      { id: 1, alt: "Front", position: 1, preview_url: "/front.jpg", thumb_url: "/front.jpg" },
    ],
    shopify_info: {
      store_id: "gid://shopify/Product/1",
      id_short: "SHOP-1",
      tag_list: ["featured", "synced"],
      product_url: "https://shopify.example/products/1",
    },
    woo_info: {
      store_id: "WOO-1",
      product_url: "https://woo.example/products/1",
    },
    created_at_columns: [{ key: "local", label: "Local", value: "19 May 2026" }],
    updated_at_columns: [{ key: "local", label: "Local", value: "20 May 2026" }],
    shopify_linked: true,
    can_pull_from_shopify: true,
    shopify_pull_path: "/products/1/pull_shopify",
    new_purchase_path: "/purchases/new?product=1",
    ...overrides,
  };
}

export function makeVariant(overrides: Partial<VariantRecord> = {}): VariantRecord {
  return {
    id: 1,
    title: "Default",
    types_name: "Default",
    weight: 0.5,
    purchase_cost: 12.5,
    selling_price: 30,
    deactivated: false,
    active_sales_count: 2,
    purchases_count: 1,
    shopify_id_short: "SHOP-V1",
    woo_store_id: "WOO-V1",
    total_purchase_cost: "150",
    theoretical_profit: "50",
    ...overrides,
  };
}

export function makeSaleItem(overrides: Partial<SaleItemRecord> = {}): SaleItemRecord {
  return {
    id: 1,
    sale_path: "/sales/1",
    store_type: "shopify",
    store_id: "#1001",
    customer_name: "Ash Ketchum",
    customer_email: "ash@example.com",
    country: "Japan",
    date: "19 May 2026",
    variant_title: null,
    price: "30.00",
    qty: 1,
    status: "active",
    warehouse: "Tokyo",
    purchase_item_path: null,
    ...overrides,
  };
}

export function makePurchase(overrides: Partial<PurchaseRecord> = {}): PurchaseRecord {
  return {
    id: 1,
    path: "/purchases/1",
    supplier: "GoodSmile",
    order_reference: "GS-1001",
    variant_title: null,
    item_price: "12.50",
    amount: 2,
    created_at: "2 days ago",
    warehouses: [{ id: 1, name: "Tokyo" }],
    ...overrides,
  };
}

export function makeProfitability(
  overrides: Partial<ProfitabilityRecord> = {},
): ProfitabilityRecord {
  return {
    potential_sales: "1 000",
    expected_total_cost: "400",
    business_expenses: "100",
    expected_net_profit: "500",
    received_revenue: "700",
    purchase_paid: "620",
    cash_position: "80",
    ...overrides,
  };
}

// ── Form factories (ProductFormRecord and its nested types) ───────────────────

export function makeProductIndexRecord(
  overrides: Partial<ProductIndexRecord> = {},
): ProductIndexRecord {
  return {
    id: 1,
    title: "Pikachu",
    full_title: "Pokémon — Pikachu | Nendoroid",
    path: "/products/1",
    edit_path: "/products/1/edit",
    thumb_url: null,
    variants: [{ id: 10, title: "1/6 Scale" }],
    woo_store_id: "WOO-1",
    shopify_id_short: "SHOP-1",
    new_purchase_path: "/purchases/new?product=1",
    ...overrides,
  };
}

export function makeVariantForm(overrides: Partial<VariantFormData> = {}): VariantFormData {
  return {
    id: null,
    base_model: true,
    sku: "SKU-001",
    size_id: null,
    version_id: null,
    color_id: null,
    purchase_cost: "10",
    selling_price: "20",
    weight: "0.5",
    deactivated: false,
    has_sales_or_purchases: false,
    _destroy: false,
    ...overrides,
  };
}

export function makeStoreInfoForm(overrides: Partial<StoreInfoFormData> = {}): StoreInfoFormData {
  return {
    id: null,
    store_name: "",
    tag_list: "",
    _destroy: false,
    ...overrides,
  };
}

export function makePurchaseForm(overrides: Partial<PurchaseFormData> = {}): PurchaseFormData {
  return {
    supplier_id: null,
    order_reference: "",
    item_price: "",
    amount: "",
    warehouse_id: null,
    payment_value: "",
    variant_client_key: null,
    ...overrides,
  };
}

export function makeProductForm(overrides: Partial<ProductFormRecord> = {}): ProductFormRecord {
  return {
    id: null,
    title: "Test Product",
    description_html: "<p>Product description</p>",
    franchise_id: null,
    shape: "Bust",
    brand_ids: [],
    path: "/products",
    variants: [makeVariantForm()],
    store_infos: [],
    media: [],
    ...overrides,
  };
}
