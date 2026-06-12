import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Products from "./Products";
import { makeFranchiseProduct } from "../test/factories";
import type { ProductRecord } from "../types";

describe("Franchises/components/Products", () => {
  it("renders linked products", () => {
    renderProducts();

    expect(
      screen.getByRole("heading", { name: "Products" })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: "Pokemon - Pikachu" })
    ).toHaveAttribute("href", "/products/10");
  });

  it("hides the section when there are no products", () => {
    renderProducts({ products: [] });

    expect(
      screen.queryByRole("heading", { name: "Products" })
    ).not.toBeInTheDocument();
  });
});

function renderProducts({
  products = [makeFranchiseProduct()],
}: { products?: ProductRecord[] } = {}) {
  return render(<Products products={products} />);
}
