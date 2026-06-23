import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Index from "./Index";
import { makePagination } from "@/test/factories";
import { makeCustomer } from "./test/factories";
import type { CustomerRecord, PaginationMeta } from "./types";

describe("Customers/Index", () => {
  it("renders the customers table and new-record link", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Customers" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/customers/new",
    );
    expect(screen.getByRole("cell", { name: "Dale Cooper" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "dale@fbi.gov" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/customers/1/edit");
  });

  it("renders a search form", () => {
    renderIndex({ search: { q: "dale" } });

    expect(screen.getByRole("searchbox")).toHaveValue("dale");
  });

  it("renders an empty state when a search returns no customers", () => {
    renderIndex({
      customers: [],
      pagination: makePagination({ total_count: 0 }),
      search: { q: "dale" },
    });

    expect(screen.getByText("Nothing found")).toBeInTheDocument();
  });

  it("renders without pagination when only one page", () => {
    renderIndex();

    expect(screen.queryByRole("navigation", { name: "Pagination" })).not.toBeInTheDocument();
  });
});

function renderIndex({
  customers = [makeCustomer()],
  pagination = makePagination(),
  search = { q: "" },
}: {
  customers?: CustomerRecord[];
  pagination?: PaginationMeta;
  search?: { q: string };
} = {}) {
  return render(<Index customers={customers} pagination={pagination} search={search} />);
}
