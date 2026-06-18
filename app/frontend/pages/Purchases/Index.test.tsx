import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Index from "./Index";
import { makePagination } from "@/test/factories";
import { makePurchaseIndexRecord, makeWarehouseOption } from "./test/factories";
import type { PaginationMeta, PurchaseIndexRecord, WarehouseOption } from "./types";

describe("Purchases/Index", () => {
  it("renders the purchases heading and add new record link", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Purchases" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/purchases/new",
    );
  });

  it("renders the purchase product and supplier in the table", () => {
    renderIndex();

    expect(screen.getByText(/Pikachu Figure/)).toBeInTheDocument();
    expect(screen.getByText("Acme Imports")).toBeInTheDocument();
  });

  it("renders a search form with the current query", () => {
    renderIndex({ search: { q: "pikachu" } });

    expect(screen.getByRole("searchbox")).toHaveValue("pikachu");
  });

  it("keeps pagination visible even when the list is empty", () => {
    renderIndex({
      pagination: makePagination({ total_pages: 2 }),
      purchases: [],
      warehouses: [],
    });

    expect(screen.getAllByRole("navigation", { name: "Pagination" })).toHaveLength(2);
  });
});

function renderIndex({
  move_path = "/purchases/move",
  pagination = makePagination(),
  purchases = [makePurchaseIndexRecord()],
  search = { q: "" },
  warehouses = [makeWarehouseOption()],
}: {
  move_path?: string;
  pagination?: PaginationMeta;
  purchases?: PurchaseIndexRecord[];
  search?: { q: string };
  warehouses?: WarehouseOption[];
} = {}) {
  return render(
    <Index
      move_path={move_path}
      pagination={pagination}
      purchases={purchases}
      search={search}
      warehouses={warehouses}
    />,
  );
}
