import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import { router } from "@inertiajs/react";
import SalesSection from "./SalesSection";
import { makeSaleItem } from "../test/factories";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Products/Show/SalesSection", () => {
  it("renders nothing without sales", () => {
    const { container } = render(
      <SalesSection hasVariants={false} sales={[]} title="Active Sales" />,
    );

    expect(container).toBeEmptyDOMElement();
  });

  it("renders the title and sales count in the header", () => {
    render(
      <SalesSection
        hasVariants={false}
        sales={[makeSaleItem({ id: 1 }), makeSaleItem({ id: 2 })]}
        title="Active Sales"
      />,
    );

    expect(screen.getByRole("heading", { name: /Active Sales.*2/ })).toBeInTheDocument();
  });

  it("renders customer, date, price, and quantity for each sale", () => {
    render(<SalesSection hasVariants={false} sales={[makeSaleItem()]} title="Active Sales" />);

    expect(screen.getByRole("cell", { name: /Ash Ketchum/ })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "19 May 2026" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "30.00" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "1" })).toBeInTheDocument();
  });

  it("capitalizes the sale status", () => {
    render(
      <SalesSection
        hasVariants={false}
        sales={[makeSaleItem({ status: "active" })]}
        title="Active Sales"
      />,
    );

    expect(screen.getByText("Active")).toBeInTheDocument();
  });

  describe("store icons", () => {
    it("shows the shopify icon for shopify sales", () => {
      render(
        <SalesSection
          hasVariants={false}
          sales={[makeSaleItem({ store_type: "shopify" })]}
          title="Active Sales"
        />,
      );

      expect(document.querySelector(".icon_shopify")).toBeInTheDocument();
    });

    it("shows the woo icon for woo sales", () => {
      render(
        <SalesSection
          hasVariants={false}
          sales={[makeSaleItem({ store_type: "woo" })]}
          title="Active Sales"
        />,
      );

      expect(document.querySelector(".icon_woo")).toBeInTheDocument();
    });
  });

  describe("variant column", () => {
    it("shows the variant column when the product has variants", () => {
      render(
        <SalesSection
          hasVariants={true}
          sales={[makeSaleItem({ variant_title: "Red Edition" })]}
          title="Active Sales"
        />,
      );

      expect(screen.getByRole("columnheader", { name: "Variant?" })).toBeInTheDocument();
      expect(screen.getByRole("cell", { name: "Red Edition" })).toBeInTheDocument();
    });

    it("hides the variant column when the product has no variants", () => {
      render(<SalesSection hasVariants={false} sales={[makeSaleItem()]} title="Active Sales" />);

      expect(screen.queryByRole("columnheader", { name: "Variant?" })).not.toBeInTheDocument();
    });
  });

  describe("row navigation", () => {
    it("visits the sale when the row is clicked", async () => {
      const user = userEvent.setup();
      render(<SalesSection hasVariants={false} sales={[makeSaleItem()]} title="Active Sales" />);

      await user.click(screen.getByRole("row", { name: /Ash Ketchum/ }));

      expect(router.visit).toHaveBeenCalledWith("/sales/1");
    });
  });

  describe("purchase item link", () => {
    it("links to the purchase item labeled with its warehouse", () => {
      render(
        <SalesSection
          hasVariants={false}
          sales={[makeSaleItem({ purchase_item_path: "/purchase_items/1", warehouse: "Tokyo" })]}
          title="Active Sales"
        />,
      );

      expect(screen.getByRole("link", { name: /Tokyo/ })).toHaveAttribute(
        "href",
        "/purchase_items/1",
      );
    });

    it("labels the link 'Purchase Item' when warehouse is empty", () => {
      render(
        <SalesSection
          hasVariants={false}
          sales={[makeSaleItem({ purchase_item_path: "/purchase_items/1", warehouse: "" })]}
          title="Active Sales"
        />,
      );

      expect(screen.getByRole("link", { name: /Purchase Item/ })).toBeInTheDocument();
    });

    it("does not navigate the row when the purchase item link is clicked", async () => {
      const user = userEvent.setup();
      render(
        <SalesSection
          hasVariants={false}
          sales={[makeSaleItem({ purchase_item_path: "/purchase_items/1" })]}
          title="Active Sales"
        />,
      );

      await user.click(screen.getByRole("link", { name: /Tokyo/ }));

      expect(router.visit).not.toHaveBeenCalledWith("/sales/1");
    });
  });
});
