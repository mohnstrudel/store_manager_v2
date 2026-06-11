import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";
import { makeBrand, makeBrandProduct } from "./test/factories";
import type { BrandRecord, ProductRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Brands/Show", () => {
  it("renders brand details and linked products", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "Moonbow" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Products" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Studio Ghibli - Spirited Away" })).toHaveAttribute(
      "href",
      "/products/10",
    );
  });

  it("links to the edit page", () => {
    renderShow();

    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/brands/1/edit");
  });

  it("hides the products section when there are no linked products", () => {
    renderShow({ products: [] });

    expect(screen.queryByRole("heading", { name: "Products" })).not.toBeInTheDocument();
  });

  describe("destroy", () => {
    it("destroys the brand after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this brand" }));

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/brands/1");
    });

    it("does not destroy the brand when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this brand" }));

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({
  brand = makeBrand(),
  products = [makeBrandProduct()],
}: {
  brand?: BrandRecord;
  products?: ProductRecord[];
} = {}) {
  return render(<Show brand={brand} products={products} />);
}
