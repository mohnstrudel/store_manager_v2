import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Details from "./Details";
import type { PurchaseShowRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Purchases/Show/Details", () => {
  it("renders the purchase summary and supplier link", () => {
    render(<Details purchase={makePurchase()} />);

    expect(screen.getByRole("link", { name: "Acme Imports" })).toHaveAttribute(
      "href",
      "/suppliers/1",
    );
    expect(screen.getByRole("img", { name: "Pikachu Figure" })).toBeInTheDocument();
    expect(screen.getByText("0")).toBeInTheDocument();
    expect(screen.getByText("-160.00")).toBeInTheDocument();
    expect(screen.getByText("PO-55")).toBeInTheDocument();
    expect(screen.getByText("20 May 2026")).toBeInTheDocument();
  });

  it("omits the image when the purchase has no product image", () => {
    render(<Details purchase={{ ...makePurchase(), product_image_url: null }} />);

    expect(screen.queryByRole("img", { name: "Pikachu Figure" })).not.toBeInTheDocument();
  });
});

function makePurchase(overrides: Partial<PurchaseShowRecord> = {}): PurchaseShowRecord {
  return {
    amount: 2,
    cost_total: "210.00",
    date: "20 May 2026",
    debt: "160.00",
    destroy_path: "/purchases/55",
    edit_path: "/purchases/55/edit",
    id: 55,
    item_price: "100.00",
    order_reference: "PO-55",
    paid: "",
    path: "/purchases/55",
    payment_progress: {
      debt: "160.00",
      paid: "50.00",
      price: "210.00",
      progress: 25,
    },
    product_image_url: "/pikachu.jpg",
    product_path: "/products/1",
    product_thumb_url: null,
    product_title: "Pikachu Figure",
    shipping_total: "10.00",
    supplier_path: "/suppliers/1",
    supplier_title: "Acme Imports",
    variant_title: "Default",
    ...overrides,
  };
}
