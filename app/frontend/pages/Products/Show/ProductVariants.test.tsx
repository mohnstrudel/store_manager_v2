import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import type { VariantRecord } from "../types";
import ProductVariants from "./ProductVariants";
import { makeVariant } from "../test/factories";

describe("Products/Show/ProductVariants", () => {
  it("renders nothing without variants", () => {
    const { container } = renderProductVariants([]);

    expect(container).toBeEmptyDOMElement();
  });

  it("renders id, title, type, and counts for each variant", () => {
    renderProductVariants([makeVariant({ active_sales_count: 5, purchases_count: 3 })]);

    const row = screen.getByRole("row", { name: /Default/ });

    expect(within(row).getByRole("cell", { name: "1" })).toBeInTheDocument();
    expect(within(row).getByRole("cell", { name: "5" })).toBeInTheDocument();
    expect(within(row).getByRole("cell", { name: "3" })).toBeInTheDocument();
    expect(within(row).getByRole("cell", { name: "SHOP-V1" })).toBeInTheDocument();
  });

  describe("formatting", () => {
    it("formats weight in kg and catalog money with two decimals", () => {
      renderProductVariants();

      const row = screen.getByRole("row", { name: /Default/ });

      expect(screen.getByRole("columnheader", { name: "List cost" })).toBeInTheDocument();
      expect(within(row).getByRole("cell", { name: "0.5 kg" })).toBeInTheDocument();
      expect(within(row).getByRole("cell", { name: "12.50" })).toBeInTheDocument();
      expect(within(row).getByRole("cell", { name: "30.00" })).toBeInTheDocument();
    });

    it("renders nothing for zero weight and zero costs", () => {
      renderProductVariants([makeVariant({ weight: 0, purchase_cost: 0, selling_price: 0 })]);

      const row = screen.getByRole("row", { name: /Default/ });
      const cells = within(row).getAllByRole("cell");

      expect(cells[3]).toHaveTextContent("");
      expect(cells[4]).toHaveTextContent("");
      expect(cells[5]).toHaveTextContent("");
    });

    it("renders nothing for zero active sales, zero purchases, and no store id", () => {
      renderProductVariants([
        makeVariant({
          active_sales_count: 0,
          purchases_count: 0,
          shopify_id_short: "",
          woo_store_id: "",
        }),
      ]);

      const row = screen.getByRole("row", { name: /Default/ });
      const cells = within(row).getAllByRole("cell");

      // Active Sales, Purchases, and Store ID are the last three columns.
      expect(cells[cells.length - 3]).toHaveTextContent("");
      expect(cells[cells.length - 2]).toHaveTextContent("");
      expect(cells[cells.length - 1]).toHaveTextContent("");
    });
  });

  describe("total purchase cost and theoretical profit", () => {
    it("renders values when purchase data exists", () => {
      renderProductVariants([
        makeVariant({ total_purchase_cost: "150", theoretical_profit: "50" }),
      ]);

      expect(screen.getByRole("cell", { name: "150" })).toBeInTheDocument();
      expect(screen.getByRole("cell", { name: "50" })).toBeInTheDocument();
    });

    it("reaches touch and keyboard users through the same accessible hint pattern as every other economics label", () => {
      renderProductVariants();

      const totalHeader = screen.getByRole("columnheader", { name: "Total landed cost" });
      const profitHeader = screen.getByRole("columnheader", { name: "Theoretical profit" });

      expect(within(totalHeader).getByLabelText("More information")).toBeInTheDocument();
      expect(within(profitHeader).getByLabelText("More information")).toBeInTheDocument();
      expect(totalHeader).not.toHaveAttribute("title");
      expect(profitHeader).not.toHaveAttribute("title");
    });

    it("states that purchases booked against the product rather than a variant are excluded, so the reader knows why the column will not match Invested", async () => {
      const user = userEvent.setup();
      renderProductVariants();

      const totalHeader = screen.getByRole("columnheader", { name: "Total landed cost" });
      await user.hover(within(totalHeader).getByLabelText("More information"));

      expect(await screen.findByRole("tooltip")).toHaveTextContent(
        /purchases booked against the product.*not counted/i,
      );
    });

    it("colors a negative theoretical profit", () => {
      renderProductVariants([makeVariant({ theoretical_profit: "-25" })]);

      expect(screen.getByText("−25")).toHaveAttribute("data-tone", "negative");
    });

    it("hides economics columns when no purchase data exists", () => {
      renderProductVariants([makeVariant({ total_purchase_cost: null, theoretical_profit: null })]);

      expect(screen.queryByRole("columnheader", { name: "Total landed cost" })).toBeNull();
      expect(screen.queryByRole("columnheader", { name: "Theoretical profit" })).toBeNull();
    });

    it("shows the calculated profit even when the purchase cost total formats to zero (two zero-cost items, 200 selling price, 15% OpEx)", () => {
      renderProductVariants([
        makeVariant({ total_purchase_cost: null, theoretical_profit: "170" }),
      ]);

      const row = screen.getByRole("row", { name: /Default/ });

      expect(screen.getByRole("columnheader", { name: "Total landed cost" })).toBeInTheDocument();
      expect(screen.getByRole("columnheader", { name: "Theoretical profit" })).toBeInTheDocument();
      expect(within(row).getByRole("cell", { name: "170" })).toBeInTheDocument();
    });

    it("renders nothing for theoretical profit when there is no selling price even with purchase data", () => {
      renderProductVariants([
        makeVariant({ total_purchase_cost: "150", theoretical_profit: null }),
      ]);

      const row = screen.getByRole("row", { name: /Default/ });
      const cells = within(row).getAllByRole("cell");

      expect(cells[6]).toHaveTextContent("150");
      expect(cells[7]).toHaveTextContent("");
    });
  });

  describe("store id", () => {
    it("prefers the shopify short id over the woo store id", () => {
      renderProductVariants();

      expect(screen.getByRole("cell", { name: "SHOP-V1" })).toBeInTheDocument();
    });

    it("falls back to the woo store id when shopify id is absent", () => {
      renderProductVariants([makeVariant({ shopify_id_short: "" })]);

      expect(screen.getByRole("cell", { name: "WOO-V1" })).toBeInTheDocument();
    });

    it("renders nothing when there is no store id at all", () => {
      renderProductVariants([makeVariant({ shopify_id_short: "", woo_store_id: "" })]);

      const row = screen.getByRole("row", { name: /Default/ });
      const cells = within(row).getAllByRole("cell");

      expect(cells[cells.length - 1]).toBeEmptyDOMElement();
    });
  });

  describe("when the variant is deactivated", () => {
    it("marks the variant title with '(Deactivated)'", () => {
      renderProductVariants([makeVariant({ deactivated: true })]);

      expect(screen.getByText("(Deactivated)")).toBeInTheDocument();
    });
  });
});

function renderProductVariants(variants: VariantRecord[] = [makeVariant()]) {
  return render(<ProductVariants variants={variants} />);
}
