import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";
import { makeFranchise, makeFranchiseProduct } from "./test/factories";
import type { FranchiseRecord, ProductRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Franchises/Show", () => {
  it("renders the franchise details and linked products", () => {
    renderShow();

    expect(
      screen.getByRole("heading", { name: "Pokemon" })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("heading", { name: "Products" })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: "Pokemon - Pikachu" })
    ).toHaveAttribute("href", "/products/10");
  });

  it("links to the edit page", () => {
    renderShow();

    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/franchises/1/edit"
    );
  });

  it("hides the products section when there are no linked products", () => {
    renderShow({ products: [] });

    expect(
      screen.queryByRole("heading", { name: "Products" })
    ).not.toBeInTheDocument();
  });

  describe("destroy", () => {
    it("destroys the franchise after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(
        screen.getByRole("button", { name: "Destroy this franchise" })
      );

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/franchises/1");
    });

    it("does not destroy the franchise when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(
        screen.getByRole("button", { name: "Destroy this franchise" })
      );

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({
  franchise = makeFranchise(),
  products = [makeFranchiseProduct()],
}: {
  franchise?: FranchiseRecord;
  products?: ProductRecord[];
} = {}) {
  return render(<Show franchise={franchise} products={products} />);
}
