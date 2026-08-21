import { router } from "@inertiajs/react";
import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import Show from "./Show";
import {
  makeProduct,
  makeProfitability,
  makePurchase,
  makeSaleItem,
  makeVariant,
} from "./test/factories";
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

  describe("tabs", () => {
    it("opens on the overview with attributes and description", () => {
      renderShow();

      expect(screen.getByRole("tab", { name: "Overview" })).toHaveAttribute(
        "aria-selected",
        "true",
      );
      expect(screen.getByTestId("image-gallery")).toBeInTheDocument();
      expect(screen.getByText("Pokemon")).toBeInTheDocument();
      expect(screen.getByText("A very electric mouse.")).toBeInTheDocument();
    });

    it("shows sale and purchase counts in the tab labels", () => {
      renderShow({ activeSales: [makeSaleItem()], purchases: [makePurchase()] });

      expect(screen.getByRole("tab", { name: "Sales 1" })).toBeInTheDocument();
      expect(screen.getByRole("tab", { name: "Purchases 1" })).toBeInTheDocument();
    });

    it("switches to sales and hides the overview", async () => {
      const user = userEvent.setup();
      renderShow({
        activeSales: [makeSaleItem({ customer_name: "Ash Ketchum" })],
        completedSales: [makeSaleItem({ id: 2, customer_name: "Misty" })],
      });

      await user.click(screen.getByRole("tab", { name: /Sales/ }));

      const activeSection = screen.getByRole("heading", { name: /Active Sales/ }).closest("div")!;
      const completedSection = screen
        .getByRole("heading", { name: /Completed Sales/ })
        .closest("div")!;

      expect(within(activeSection).getByText("Ash Ketchum")).toBeInTheDocument();
      expect(within(completedSection).getByText("Misty")).toBeInTheDocument();
      expect(screen.queryByTestId("image-gallery")).not.toBeInTheDocument();
    });

    it("hides the sales tab when there are no sales", () => {
      renderShow({ activeSales: [], completedSales: [] });

      expect(screen.queryByRole("tab", { name: /Sales/ })).not.toBeInTheDocument();
    });

    it("switches to purchases", async () => {
      const user = userEvent.setup();
      renderShow({ purchases: [makePurchase()] });

      await user.click(screen.getByRole("tab", { name: /Purchases/ }));

      expect(screen.getByRole("heading", { name: /Purchases/ })).toBeInTheDocument();
      expect(screen.getByText("GoodSmile")).toBeInTheDocument();
    });

    it("hides the purchases tab when there are no purchases", () => {
      renderShow({ purchases: [] });

      expect(screen.queryByRole("tab", { name: /Purchases/ })).not.toBeInTheDocument();
    });

    describe("variants tab", () => {
      it("shows the variants table with its count", async () => {
        const user = userEvent.setup();
        renderShow({ variants: [makeVariant()] });

        await user.click(screen.getByRole("tab", { name: "Variants 1" }));

        expect(screen.getByRole("heading", { name: "Variants" })).toBeInTheDocument();
      });

      it("hides the tab without variants", () => {
        renderShow({ variants: [] });

        expect(screen.queryByRole("tab", { name: /Variants/ })).not.toBeInTheDocument();
      });

      it("shows the variant column in sales tables", async () => {
        const user = userEvent.setup();
        renderShow({
          variants: [makeVariant()],
          activeSales: [makeSaleItem({ variant_title: "Red Edition" })],
        });

        await user.click(screen.getByRole("tab", { name: /Sales/ }));

        const activeSection = screen
          .getAllByRole("heading", { name: /Active Sales/ })[0]
          .closest("div")!;

        expect(
          within(activeSection).getByRole("columnheader", { name: "Variant?" }),
        ).toBeInTheDocument();
      });

      it("renders without crashing for managers, who have no profitability data", async () => {
        const user = userEvent.setup();
        renderShow({ variants: [makeVariant()], profitability: null });

        await user.click(screen.getByRole("tab", { name: "Variants 1" }));

        expect(screen.getByRole("heading", { name: "Variants" })).toBeInTheDocument();
      });
    });

    describe("economics dashboard", () => {
      it("summarizes the product economics above the tabs", () => {
        renderShow({ activeSales: [makeSaleItem()], profitability: makeProfitability() });

        const dashboard = screen.getByTestId("economics-dashboard");

        expect(within(dashboard).getByTestId("profitability-snapshot-card")).toBeInTheDocument();
        expect(within(dashboard).getByText("Exp. Net Profit")).toBeInTheDocument();
      });

      it("stays visible on every tab", async () => {
        const user = userEvent.setup();
        renderShow({
          activeSales: [makeSaleItem()],
          profitability: makeProfitability(),
          purchases: [makePurchase()],
        });

        await user.click(screen.getByRole("tab", { name: /Purchases/ }));
        expect(screen.getByTestId("economics-dashboard")).toBeInTheDocument();
      });

      it("is absent for users without profitability access", () => {
        renderShow({ profitability: null });

        expect(screen.queryByTestId("economics-dashboard")).not.toBeInTheDocument();
      });

      it("shows the full picture for a purchased product with no sales", () => {
        renderShow({
          purchases: [makePurchase()],
          profitability: makeProfitability({
            collected_revenue: null,
            purchase_paid: null,
            cash_position: null,
            potential_sales: "120",
            expected_total_cost: "80",
            expected_net_profit: "28",
          }),
        });

        const dashboard = within(screen.getByTestId("economics-dashboard"));

        expect(dashboard.getByText("Exp. Total Cost")).toBeInTheDocument();
        expect(dashboard.getByText("80")).toBeInTheDocument();
        expect(screen.getByTestId("profitability-snapshot-card")).toBeInTheDocument();
      });

      it("is absent when there is nothing purchased and no cash position", () => {
        renderShow({
          profitability: makeProfitability({ expected_total_cost: null, cash_position: null }),
        });

        expect(screen.queryByTestId("economics-dashboard")).not.toBeInTheDocument();
      });
    });

    describe("when the description is empty", () => {
      it("hides the description card", () => {
        renderShow({ product: makeProduct({ description_html: "" }) });

        expect(screen.queryByText(/electric mouse/)).not.toBeInTheDocument();
      });
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
  profitability = null,
  purchases = [],
  variants = [],
}: {
  activeSales?: ReturnType<typeof makeSaleItem>[];
  completedSales?: ReturnType<typeof makeSaleItem>[];
  product?: ProductShowRecord;
  profitability?: ReturnType<typeof makeProfitability> | null;
  purchases?: ReturnType<typeof makePurchase>[];
  variants?: ReturnType<typeof makeVariant>[];
} = {}) {
  return render(
    <Show
      active_sales={activeSales}
      completed_sales={completedSales}
      product={product}
      profitability={profitability}
      purchases={purchases}
      variants={variants}
    />,
  );
}
