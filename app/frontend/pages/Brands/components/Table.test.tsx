import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Table from "./Table";
import { makeBrand } from "../test/factories";
import type { BrandRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Brands/components/Table", () => {
  it("renders brand rows with show and edit links", () => {
    renderTable();

    expect(screen.getByRole("cell", { name: "Moonbow" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/brands/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/brands/1/edit");
  });

  it("navigates to the brand page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderTable();
    const brandRow = screen.getByRole("cell", { name: "Moonbow" }).closest("tr");

    expect(brandRow).not.toBeNull();
    await user.click(brandRow!);

    expect(router.visit).toHaveBeenCalledWith("/brands/1");
  });
});

function renderTable({ brands = [makeBrand()] }: { brands?: BrandRecord[] } = {}) {
  return render(<Table brands={brands} />);
}
