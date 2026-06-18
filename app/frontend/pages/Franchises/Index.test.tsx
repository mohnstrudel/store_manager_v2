import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Index from "./Index";
import { makeFranchise } from "./test/factories";
import type { FranchiseRecord } from "./types";

describe("Franchises/Index", () => {
  it("renders the franchise heading, add link, and table row", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Franchises" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/franchises/new",
    );
    expect(screen.getByRole("cell", { name: "Pokemon" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/franchises/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/franchises/1/edit",
    );
  });
});

function renderIndex({ franchises = [makeFranchise()] }: { franchises?: FranchiseRecord[] } = {}) {
  return render(<Index franchises={franchises} />);
}
