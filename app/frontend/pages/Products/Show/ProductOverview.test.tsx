import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import type { ProductShowRecord } from "../types";
import ProductOverview from "./ProductOverview";
import { makeProduct } from "../test/factories";

vi.mock("@/components/ImageGallery", () => ({
  default: ({ media }: { media: { length: number } }) => (
    <div data-testid="image-gallery">Images: {media.length}</div>
  ),
}));

describe("Products/Show/ProductOverview", () => {
  it("renders the image gallery with the product media", () => {
    renderProductOverview();

    expect(screen.getByTestId("image-gallery")).toHaveTextContent("Images: 1");
  });

  describe("product details", () => {
    it("renders title, franchise, and shape", () => {
      renderProductOverview();

      expect(screen.getByText("Pikachu")).toBeInTheDocument();
      expect(screen.getByText("Pokemon")).toBeInTheDocument();
      expect(screen.getByText("Figure")).toBeInTheDocument();
    });

    it("renders versions, brands, sizes, and colors as comma-separated lists", () => {
      renderProductOverview({
        brands: [
          { id: 1, title: "Nendoroid" },
          { id: 2, title: "Figma" },
        ],
        versions: [
          { id: 1, value: "Classic" },
          { id: 2, value: "Limited" },
        ],
      });

      expect(screen.getByText("Nendoroid, Figma")).toBeInTheDocument();
      expect(screen.getByText("Classic, Limited")).toBeInTheDocument();
    });

    it("renders '-' for empty list attributes", () => {
      renderProductOverview({ brands: [], sizes: [], versions: [], colors: [] });

      expect(screen.getAllByText("-")).not.toHaveLength(0);
    });
  });

  describe("store identifiers", () => {
    it("renders the id and timestamp columns with their labels and values", () => {
      renderProductOverview({
        created_at_columns: [
          { key: "local", label: "StoreMate", value: "19. Apr '26" },
          { key: "shopify", label: "Shopify", value: "20. Apr '26" },
        ],
        updated_at_columns: [
          { key: "local", label: "StoreMate", value: "21. Apr '26" },
          { key: "shopify", label: "Shopify", value: "22. Apr '26" },
        ],
      });

      expect(screen.getByText("19. Apr '26")).toBeInTheDocument();
      expect(screen.getByText("20. Apr '26")).toBeInTheDocument();
      expect(screen.getByText("21. Apr '26")).toBeInTheDocument();
      expect(screen.getByText("22. Apr '26")).toBeInTheDocument();
    });

    describe("woo identifier", () => {
      it("links the store id to the woo product url and shows a copy button", () => {
        const { container } = renderProductOverview();

        expect(screen.getByRole("link", { name: "WOO-1" })).toHaveAttribute(
          "href",
          "https://woo.example/products/1",
        );
        expect(
          container.querySelector('[data-copy-to-clipboard-text-value="WOO-1"]'),
        ).toBeInTheDocument();
      });

      it("renders the store id as plain text when there is no product url", () => {
        renderProductOverview({ woo_info: { store_id: "WOO-1", product_url: null } });

        expect(screen.queryByRole("link", { name: "WOO-1" })).not.toBeInTheDocument();
        expect(screen.getByText("WOO-1")).toBeInTheDocument();
      });

      it("renders '-' when there is no store id", () => {
        const { container } = renderProductOverview({
          woo_info: { store_id: null, product_url: null },
        });

        expect(
          container.querySelector('[data-copy-to-clipboard-text-value="WOO-1"]'),
        ).not.toBeInTheDocument();
      });
    });

    describe("shopify identifier", () => {
      it("links the short id to the shopify product url and shows a copy button", () => {
        const { container } = renderProductOverview();

        expect(screen.getByRole("link", { name: "SHOP-1" })).toHaveAttribute(
          "href",
          "https://shopify.example/products/1",
        );
        expect(
          container.querySelector('[data-copy-to-clipboard-text-value="SHOP-1"]'),
        ).toBeInTheDocument();
      });

      it("renders '-' when there is no shopify id", () => {
        renderProductOverview({
          shopify_info: { store_id: null, id_short: null, tag_list: [], product_url: null },
        });

        expect(screen.queryByRole("link", { name: /SHOP/ })).not.toBeInTheDocument();
      });
    });

    describe("tags", () => {
      it("renders the shopify tag list", () => {
        renderProductOverview();

        expect(screen.getByText("featured")).toBeInTheDocument();
        expect(screen.getByText("synced")).toBeInTheDocument();
      });

      it("hides the tags row when the tag list is empty", () => {
        renderProductOverview({
          shopify_info: {
            store_id: "gid://shopify/Product/1",
            id_short: "SHOP-1",
            tag_list: [],
            product_url: "https://shopify.example/products/1",
          },
        });

        expect(screen.queryByText("Tags")).not.toBeInTheDocument();
      });
    });
  });
});

function renderProductOverview(overrides: Partial<ProductShowRecord> = {}) {
  return render(<ProductOverview product={makeProduct(overrides)} />);
}
