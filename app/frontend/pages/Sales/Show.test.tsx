import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
  router: { delete: vi.fn(), post: vi.fn(), visit: vi.fn() },
}));

const sale = {
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
  customer: {
    id: 2,
    first_name: "Dale",
    last_name: "Cooper",
    full_name: "Dale Cooper",
    email: "dale@fbi.gov",
    shopify_id_short: "9341147185481",
    shop_admin_url: "https://admin.shopify.com/store/68d8f5-af/customers/9341147185481",
  },
  shipping_address: {
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
  },
  billing_address: {
    address_1: "456 Side St",
    address_2: "",
    city: "Paris",
    company: "",
    country: "FR",
    email: "dale@fbi.gov",
    first_name: "Dale",
    last_name: "Cooper",
    phone: "+4912345",
    postcode: "75001",
    state: "",
  },
  sale_items: [
    {
      id: 11,
      title: "Pikachu Figure",
      price: "1060",
      qty: 2,
      product_path: "/products/pikachu",
      product_thumb_url: null,
      purchase_items: [
        {
          id: 101,
          path: "/purchases/55",
          supplier_title: "Acme Imports",
          purchase_date: "18. May '26",
          item_price: "1030",
          unlink_path: "/purchase_items/101/unlink",
          current_warehouse_name: "Berlin Hub",
          current_warehouse_path: "/warehouses/1?selected=101#101",
          warehouse_movements: [{ moved_in: "18. May '26 08:30", warehouse_name: "Berlin Hub" }],
        },
      ],
    },
  ],
};

describe("Sales/Show", () => {
  it("renders the sale details and purchase controls", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);

    render(<Show sale={sale} />);

    expect(screen.getByRole("heading", { name: "Sale HSCM#1746" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Link with purchases/ })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Fetch/ })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Go to Shopify/ })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toBeInTheDocument();
    expect(screen.getByText("Leave at the door")).toBeInTheDocument();
    expect(screen.getByText("Pikachu Figure")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /Unlink/ })).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: /Billing/ }));

    expect(screen.getByText("456 Side St")).toBeInTheDocument();
    expect(screen.getByText("Paris")).toBeInTheDocument();
  });
});
