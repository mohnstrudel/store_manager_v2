import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import Show from "./Show";
import { makeProduct, makePurchase, makeSaleItem, makeVariant } from "./test/factories";
import type { ProductShowRecord } from "./types";

vi.mock("@/components/ImageGallery", () => ({
  default: ({ media }: { media: ProductShowRecord["media"] }) => (
    <div data-testid="image-gallery">Images: {media.length}</div>
  ),
}));

describe("Products/Show", () => {
  describe("header", () => {
    it("renders the product title and full title", () => {
      renderShow();

      expect(screen.getByRole("heading", { name: "Pikachu" })).toBeInTheDocument();
      expect(screen.getByRole("heading", { name: "Pokemon - Pikachu" })).toBeInTheDocument();
    });

    it("renders edit and new purchase actions", () => {
      renderShow();

      expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
        "href",
        "/products/1/edit",
      );
      expect(screen.getByRole("link", { name: /New Purchase/ })).toHaveAttribute(
        "href",
        "/purchases/new?product=1",
      );
    });

    it("renders the Shopify fetch action posting to the pull path", () => {
      renderShow();

      expect(screen.getByRole("link", { name: /Fetch/ })).toHaveAttribute(
        "href",
        "/products/1/pull_shopify",
      );
      expect(screen.getByRole("link", { name: /Fetch/ })).toHaveAttribute("data-method", "post");
    });

    describe("when the product cannot be pulled from Shopify", () => {
      it("hides the fetch action", () => {
        renderShow({ product: makeProduct({ can_pull_from_shopify: false }) });

        expect(screen.queryByRole("link", { name: /Fetch/ })).not.toBeInTheDocument();
      });
    });
  });

  describe("sections", () => {
    it("renders the product overview", () => {
      renderShow();

      expect(screen.getByTestId("image-gallery")).toBeInTheDocument();
      expect(screen.getByText("Pokemon")).toBeInTheDocument();
    });

    it("renders the product description", () => {
      renderShow();

      expect(screen.getByText("A very electric mouse.")).toBeInTheDocument();
    });

    describe("when the description is empty", () => {
      it("hides the description card", () => {
        renderShow({ product: makeProduct({ description_html: "" }) });

        expect(screen.queryByText(/electric mouse/)).not.toBeInTheDocument();
      });
    });

    describe("when the product has variants", () => {
      it("renders the variants table", () => {
        renderShow({ variants: [makeVariant()] });

        expect(screen.getByRole("heading", { name: "Variants" })).toBeInTheDocument();
      });

      it("shows the variant column in sales tables", () => {
        renderShow({
          variants: [makeVariant()],
          activeSales: [makeSaleItem({ variant_title: "Red Edition" })],
        });

        const activeSection = screen
          .getAllByRole("heading", { name: /Active Sales/ })[0]
          .closest("div")!;

        expect(
          within(activeSection).getByRole("columnheader", { name: "Variant?" }),
        ).toBeInTheDocument();
      });
    });

    it("hides the variants section without variants", () => {
      renderShow({ variants: [] });

      expect(screen.queryByRole("heading", { name: "Variants" })).not.toBeInTheDocument();
    });

    it("renders active and completed sales in their own sections", () => {
      renderShow({
        activeSales: [makeSaleItem({ customer_name: "Ash Ketchum" })],
        completedSales: [makeSaleItem({ id: 2, customer_name: "Misty" })],
      });

      const activeSection = screen.getByRole("heading", { name: /Active Sales/ }).closest("div")!;
      const completedSection = screen
        .getByRole("heading", { name: /Completed Sales/ })
        .closest("div")!;

      expect(within(activeSection).getByText("Ash Ketchum")).toBeInTheDocument();
      expect(within(completedSection).getByText("Misty")).toBeInTheDocument();
    });

    it("hides sales sections without sales", () => {
      renderShow({ activeSales: [], completedSales: [] });

      expect(screen.queryByRole("heading", { name: /Active Sales/ })).not.toBeInTheDocument();
      expect(screen.queryByRole("heading", { name: /Completed Sales/ })).not.toBeInTheDocument();
    });

    it("renders the purchases section", () => {
      renderShow({ purchases: [makePurchase()] });

      expect(screen.getByRole("heading", { name: /Purchases/ })).toBeInTheDocument();
      expect(screen.getByText("GoodSmile")).toBeInTheDocument();
    });

    it("hides the purchases section without purchases", () => {
      renderShow({ purchases: [] });

      expect(screen.queryByRole("heading", { name: /Purchases/ })).not.toBeInTheDocument();
    });
  });

  describe("destroy", () => {
    it("destroys the product after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this product" }));

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/products/1");
    });

    it("does not destroy the product when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this product" }));

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({
  activeSales = [],
  completedSales = [],
  product = makeProduct(),
  purchases = [],
  variants = [],
}: {
  activeSales?: ReturnType<typeof makeSaleItem>[];
  completedSales?: ReturnType<typeof makeSaleItem>[];
  product?: ProductShowRecord;
  purchases?: ReturnType<typeof makePurchase>[];
  variants?: ReturnType<typeof makeVariant>[];
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
