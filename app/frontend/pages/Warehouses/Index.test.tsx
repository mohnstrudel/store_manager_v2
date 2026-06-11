import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Index from "./Index";
import { makeWarehouseRecord } from "./test/factories";
import type { WarehouseRecord } from "./Index/Table";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Warehouses/Index", () => {
  it("renders the heading, column headers, and warehouse rows", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Warehouses" })).toBeInTheDocument();
    expect(screen.getByRole("columnheader", { name: "Products" })).toBeInTheDocument();
    expect(screen.getByText("Main Warehouse")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/warehouses/1/edit",
    );
  });

  it("merges name and external name into a single column header", () => {
    renderIndex();

    expect(
      screen.getByRole("columnheader", { name: "Name + External Name for Clients" }),
    ).toBeInTheDocument();
    expect(
      screen.queryByRole("columnheader", { name: "External Name" }),
    ).not.toBeInTheDocument();
  });

  it("marks the default warehouse with a tip indicator", () => {
    renderIndex({ warehouses: [makeWarehouseRecord({ is_default: true })] });

    const star = screen.getByText("*");
    expect(star).toHaveClass("text-yellow-600");
    expect(
      screen.getByText(
        "New purchases go to this warehouse by default. Change it on the edit page.",
      ),
    ).toBeInTheDocument();
  });

  it("does not show a default tip for non-default warehouses", () => {
    renderIndex({ warehouses: [makeWarehouseRecord({ is_default: false })] });

    expect(
      screen.queryByText(
        "New purchases go to this warehouse by default. Change it on the edit page.",
      ),
    ).not.toBeInTheDocument();
  });
});

function renderIndex({
  warehouses = [makeWarehouseRecord()],
}: { warehouses?: WarehouseRecord[] } = {}) {
  return render(<Index warehouses={warehouses} />);
}
