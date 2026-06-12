import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import ProductVariants from "./ProductVariants";
import { makeVariant } from "../test/factories";

describe("Products/Show/ProductVariants", () => {
  it("renders nothing without variants", () => {
    const { container } = render(<ProductVariants variants={[]} />);

    expect(container).toBeEmptyDOMElement();
  });

  it("renders id, title, type, and counts for each variant", () => {
    render(
      <ProductVariants variants={[makeVariant({ active_sales_count: 5, purchases_count: 3 })]} />,
    );

    const row = screen.getByRole("row", { name: /Default/ });

    expect(within(row).getByRole("cell", { name: "1" })).toBeInTheDocument();
    expect(within(row).getByRole("cell", { name: "5" })).toBeInTheDocument();
    expect(within(row).getByRole("cell", { name: "3" })).toBeInTheDocument();
    expect(within(row).getByRole("cell", { name: "SHOP-V1" })).toBeInTheDocument();
  });

  describe("formatting", () => {
    it("formats weight in kg and money with two decimals", () => {
      render(<ProductVariants variants={[makeVariant()]} />);

      const row = screen.getByRole("row", { name: /Default/ });

      expect(within(row).getByRole("cell", { name: "0.5 kg" })).toBeInTheDocument();
      expect(within(row).getByRole("cell", { name: "$12.50" })).toBeInTheDocument();
      expect(within(row).getByRole("cell", { name: "$30.00" })).toBeInTheDocument();
    });

    it("renders '-' for zero weight and zero costs", () => {
      render(
        <ProductVariants
          variants={[makeVariant({ weight: 0, purchase_cost: 0, selling_price: 0 })]}
        />,
      );

      const cells = screen.getAllByRole("cell", { name: "-" });

      expect(cells).toHaveLength(3);
    });
  });

  describe("store id", () => {
    it("prefers the shopify short id over the woo store id", () => {
      render(<ProductVariants variants={[makeVariant()]} />);

      expect(screen.getByRole("cell", { name: "SHOP-V1" })).toBeInTheDocument();
    });

    it("falls back to the woo store id when shopify id is absent", () => {
      render(<ProductVariants variants={[makeVariant({ shopify_id_short: "" })]} />);

      expect(screen.getByRole("cell", { name: "WOO-V1" })).toBeInTheDocument();
    });
  });

  describe("when the variant is deactivated", () => {
    it("marks the variant title with '(Deactivated)'", () => {
      render(<ProductVariants variants={[makeVariant({ deactivated: true })]} />);

      expect(screen.getByText("(Deactivated)")).toBeInTheDocument();
    });
  });
});
