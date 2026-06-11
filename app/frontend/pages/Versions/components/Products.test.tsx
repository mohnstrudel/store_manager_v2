import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Products from "./Products";
import { makeVersionProduct } from "../test/factories";
import type { ProductRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Versions/components/Products", () => {
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
  products = [makeVersionProduct()],
}: {
  products?: ProductRecord[];
} = {}) {
  return render(<Products products={products} />);
}
