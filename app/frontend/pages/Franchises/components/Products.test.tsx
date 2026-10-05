import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { makeFranchiseProduct } from "../test/factories";
import Products from "./Products";

describe("Franchises/components/Products", () => {
  it("renders linked products", () => {
    render(<Products products={[makeFranchiseProduct()]} />);

    expect(screen.getByRole("heading", { name: "Products" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Pokemon - Pikachu" })).toHaveAttribute(
      "href",
      "/products/10",
    );
  });

  it("hides the section when there are no products", () => {
    render(<Products products={[]} />);

    expect(screen.queryByRole("heading", { name: "Products" })).not.toBeInTheDocument();
  });
});
