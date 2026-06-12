import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import SaleActions from "./SaleActions";
import { makeSaleShow } from "../test/factories";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Sales/Show/SaleActions", () => {
  it("renders purchase-linking, fetch, admin, and edit actions for a Shopify sale", () => {
    render(<SaleActions sale={makeSaleShow()} />);

    expect(screen.getByRole("link", { name: /Link with purchases/ })).toHaveAttribute(
      "href",
      "/sales/1/link_purchase_items",
    );
    expect(screen.getByRole("link", { name: /Fetch/ })).toHaveAttribute("href", "/sales/1/pull");
    expect(screen.getByRole("link", { name: /Go to Shopify/ })).toHaveAttribute(
      "href",
      "https://admin.shopify.com/store/68d8f5-af/orders/7383283466569",
    );
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/sales/1/edit");
  });

  it("hides the link-with-purchases action when purchase linking is unavailable", () => {
    render(<SaleActions sale={makeSaleShow({ can_link_purchase_items: false })} />);

    expect(screen.queryByRole("link", { name: /Link with purchases/ })).not.toBeInTheDocument();
  });

  it("hides the fetch action when the sale has no Shopify identifiers", () => {
    render(
      <SaleActions
        sale={makeSaleShow({ shopify_id: "", shopify_name: "", woo_store_id: "WOO-1" })}
      />,
    );

    expect(screen.queryByRole("link", { name: /Fetch/ })).not.toBeInTheDocument();
  });

  it("labels the admin link as WooCommerce for a non-Shopify sale", () => {
    render(
      <SaleActions
        sale={makeSaleShow({
          shop_admin_url: "https://woo.example/orders/1",
          shopify_id: "",
          shopify_name: "",
          woo_store_id: "WOO-1",
        })}
      />,
    );

    expect(screen.getByRole("link", { name: /Go to WooCommerce/ })).toHaveAttribute(
      "href",
      "https://woo.example/orders/1",
    );
  });
});
