import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makeSaleItem } from "../test/factories";
import type { SaleItemRecord } from "../types";
import SalesSection from "./SalesSection";

describe("Products/Show/SalesSection", () => {
  it("renders nothing without sales", () => {
    const { container } = renderSalesSection({ sales: [] });

    expect(container).toBeEmptyDOMElement();
  });

  it("renders the title and sales count in the header", () => {
    renderSalesSection({ sales: [makeSaleItem({ id: 1 }), makeSaleItem({ id: 2 })] });

    expect(screen.getByRole("heading", { name: /Active Sales.*2/ })).toBeInTheDocument();
  });

  it("renders customer, date, price, and quantity for each sale", () => {
    renderSalesSection();

    expect(screen.getByRole("cell", { name: /Ash Ketchum/ })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "19 May 2026" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "30.00" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "1" })).toBeInTheDocument();
  });

  it("capitalizes the sale status", () => {
    renderSalesSection({ sales: [makeSaleItem({ status: "active" })] });

    expect(screen.getByText("Active")).toBeInTheDocument();
  });

  describe("store icons", () => {
    it("shows the shopify icon for shopify sales", () => {
      renderSalesSection({ sales: [makeSaleItem({ store_type: "shopify" })] });

      expect(document.querySelector(".icon_shopify")).toBeInTheDocument();
    });

    it("shows the woo icon for woo sales", () => {
      renderSalesSection({ sales: [makeSaleItem({ store_type: "woo" })] });

      expect(document.querySelector(".icon_woo")).toBeInTheDocument();
    });
  });

  describe("variant column", () => {
    it("shows the variant column when the product has variants", () => {
      renderSalesSection({
        hasVariants: true,
        sales: [makeSaleItem({ variant_title: "Red Edition" })],
      });

      expect(screen.getByRole("columnheader", { name: "Variant?" })).toBeInTheDocument();
      expect(screen.getByRole("cell", { name: "Red Edition" })).toBeInTheDocument();
    });

    it("hides the variant column when the product has no variants", () => {
      renderSalesSection();

      expect(screen.queryByRole("columnheader", { name: "Variant?" })).not.toBeInTheDocument();
    });
  });

  describe("row navigation", () => {
    it("visits the sale when the row is clicked", async () => {
      const user = userEvent.setup();
      renderSalesSection();

      await user.click(screen.getByRole("row", { name: /Ash Ketchum/ }));

      expect(router.visit).toHaveBeenCalledWith("/sales/1");
    });
  });

  describe("purchase item link", () => {
    it("links to the purchase item labeled with its warehouse", () => {
      renderSalesSection({
        sales: [makeSaleItem({ purchase_item_path: "/purchase_items/1", warehouse: "Tokyo" })],
      });

      expect(screen.getByRole("link", { name: /Tokyo/ })).toHaveAttribute(
        "href",
        "/purchase_items/1",
      );
    });

    it("labels the link 'Purchase Item' when warehouse is empty", () => {
      renderSalesSection({
        sales: [makeSaleItem({ purchase_item_path: "/purchase_items/1", warehouse: "" })],
      });

      expect(screen.getByRole("link", { name: /Purchase Item/ })).toBeInTheDocument();
    });

    it("does not navigate the row when the purchase item link is clicked", async () => {
      const user = userEvent.setup();
      renderSalesSection({
        sales: [makeSaleItem({ purchase_item_path: "/purchase_items/1" })],
      });

      await user.click(screen.getByRole("link", { name: /Tokyo/ }));

      expect(router.visit).not.toHaveBeenCalledWith("/sales/1");
    });
  });
});

type RenderSalesSectionOptions = {
  hasVariants?: boolean;
  sales?: SaleItemRecord[];
  title?: string;
};

function renderSalesSection({
  hasVariants = false,
  sales = [makeSaleItem()],
  title = "Active Sales",
}: RenderSalesSectionOptions = {}) {
  return render(<SalesSection hasVariants={hasVariants} sales={sales} title={title} />);
}
