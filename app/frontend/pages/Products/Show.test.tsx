import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import Show from "./Show";
import type { ProductShowRecord, PurchaseRecord, SaleItemRecord, VariantRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

vi.mock("@/components/ImageGallery", () => ({
  default: ({ media }: { media: ProductShowRecord["media"] }) => (
    <div data-testid="image-gallery">Images: {media.length}</div>
  ),
}));

vi.mock("./Show/ProductVariants", () => ({
  default: ({ variants }: { variants: VariantRecord[] }) => (
    <div data-testid="product-variants">Variants: {variants.length}</div>
  ),
}));

vi.mock("./Show/SalesSection", () => ({
  default: ({
    hasVariants,
    sales,
    title,
  }: {
    hasVariants: boolean;
    sales: SaleItemRecord[];
    title: string;
  }) => (
    <section data-has-variants={hasVariants} data-testid={title}>
      {title}: {sales.length}
    </section>
  ),
}));

vi.mock("./Show/PurchasesSection", () => ({
  default: ({ purchases }: { purchases: PurchaseRecord[] }) => (
    <div data-testid="purchases">Purchases: {purchases.length}</div>
  ),
}));

vi.mock("@/components/CopyToClipboardButton", () => ({
  default: ({ text }: { text: string }) => <button type="button">Copy {text}</button>,
}));

describe("Products/Show", () => {
  it("renders product details, store identifiers, and page actions", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "Pikachu" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Pokemon - Pikachu" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Fetch/ })).toHaveAttribute(
      "href",
      "/products/1/pull_shopify",
    );
    expect(screen.getByRole("link", { name: /Fetch/ })).toHaveAttribute("data-method", "post");
    expect(screen.getByRole("link", { name: /New Purchase/ })).toHaveAttribute(
      "href",
      "/purchases/new?product=1",
    );
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/products/1/edit");
    expect(screen.getByText("Pokemon")).toBeInTheDocument();
    expect(screen.getByText("Nendoroid")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "WOO-1" })).toHaveAttribute(
      "href",
      "https://woo.example/products/1",
    );
    expect(screen.getByRole("link", { name: "SHOP-1" })).toHaveAttribute(
      "href",
      "https://shopify.example/products/1",
    );
    expect(screen.getByText("featured")).toBeInTheDocument();
    expect(screen.getByText("synced")).toBeInTheDocument();
    expect(screen.getByText("A very electric mouse.")).toBeInTheDocument();
  });

  it("passes variant presence to sale sections", () => {
    renderShow({ variants: [makeVariant()] });

    expect(screen.getByTestId("Active Sales")).toHaveAttribute("data-has-variants", "true");
    expect(screen.getByTestId("Completed Sales")).toHaveAttribute("data-has-variants", "true");
  });

  it("renders timestamp columns from created_at_columns and updated_at_columns", () => {
    renderShow({
      product: makeProduct({
        created_at_columns: [
          { key: "local", label: "StoreMate", value: "19. Apr '26" },
          { key: "shopify", label: "Shopify", value: "20. Apr '26" },
        ],
        updated_at_columns: [
          { key: "local", label: "StoreMate", value: "21. Apr '26" },
          { key: "shopify", label: "Shopify", value: "22. Apr '26" },
        ],
      }),
    });

    expect(screen.getByText("19. Apr '26")).toBeInTheDocument();
    expect(screen.getByText("20. Apr '26")).toBeInTheDocument();
    expect(screen.getByText("21. Apr '26")).toBeInTheDocument();
    expect(screen.getByText("22. Apr '26")).toBeInTheDocument();
  });

  it("renders copy buttons for woo and shopify store IDs when present", () => {
    renderShow({
      product: makeProduct({
        woo_info: {
          store_id: "99000",
          product_url: "https://woo.example/products/1",
        },
        shopify_info: {
          store_id: "gid://shopify/Product/10166608396617",
          id_short: "10166608396617",
          tag_list: [],
          product_url: "https://shopify.example/products/1",
        },
      }),
    });

    expect(screen.getByText("Copy 99000")).toBeInTheDocument();
    expect(screen.getByText("Copy 10166608396617")).toBeInTheDocument();
  });

  it("does not render copy buttons when store IDs are absent", () => {
    renderShow({
      product: makeProduct({
        woo_info: { store_id: null, product_url: null },
        shopify_info: {
          store_id: null,
          id_short: null,
          tag_list: [],
          product_url: null,
        },
        shopify_linked: false,
        can_pull_from_shopify: false,
      }),
    });

    expect(screen.queryByText(/^Copy/)).toBeNull();
  });

  it("does not render the Shopify fetch action when the product cannot be pulled", () => {
    renderShow({
      product: makeProduct({ can_pull_from_shopify: false }),
    });

    expect(screen.queryByRole("link", { name: /Fetch/ })).not.toBeInTheDocument();
  });

  it("destroys the product after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
    renderShow();

    await user.click(screen.getByRole("button", { name: "Destroy this product" }));

    expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
    expect(router.delete).toHaveBeenCalledWith("/products/1");
  });
});

function renderShow({
  activeSales = [],
  completedSales = [],
  product = makeProduct(),
  purchases = [],
  variants = [],
}: {
  activeSales?: SaleItemRecord[];
  completedSales?: SaleItemRecord[];
  product?: ProductShowRecord;
  purchases?: PurchaseRecord[];
  variants?: VariantRecord[];
} = {}) {
  return render(
    <Show
      active_sales={activeSales}
      completed_sales={completedSales}
      product={product}
      purchases={purchases}
      variants={variants}
    />,
  );
}

function makeProduct(overrides: Partial<ProductShowRecord> = {}): ProductShowRecord {
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
      {
        id: 1,
        alt: "Front",
        position: 1,
        preview_url: "/front.jpg",
        thumb_url: "/front.jpg",
      },
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

function makeVariant(): VariantRecord {
  return {
    id: 1,
    title: "Default",
    types_name: "Default",
    weight: 0,
    purchase_cost: 0,
    selling_price: 0,
    deactivated: false,
    active_sales_count: 0,
    purchases_count: 0,
    shopify_id_short: "SHOP-V1",
    woo_store_id: "WOO-V1",
  };
}
