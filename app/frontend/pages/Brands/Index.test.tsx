import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Index from "./Index";
import { makeBrand } from "./test/factories";
import type { BrandRecord } from "./types";

describe("Brands/Index", () => {
  it("renders the brands table and new-record link", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Brands" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/brands/new",
    );
    expect(screen.getByRole("cell", { name: "Moonbow" })).toBeInTheDocument();
  });
});

function renderIndex({ brands = [makeBrand()] }: { brands?: BrandRecord[] } = {}) {
  return render(<Index brands={brands} />);
}
