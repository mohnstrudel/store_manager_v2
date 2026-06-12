import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Table from "./Table";
import { makeCustomer } from "../test/factories";
import type { CustomerRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Customers/components/Table", () => {
  it("renders customer rows with edit links", () => {
    renderTable();

    expect(screen.getByRole("cell", { name: "Dale Cooper" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/customers/1/edit",
    );
  });

  it("navigates to the customer page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderTable();
    const customerRow = screen.getByRole("cell", { name: "Dale Cooper" }).closest("tr");

    expect(customerRow).not.toBeNull();
    await user.click(customerRow!);

    expect(router.visit).toHaveBeenCalledWith("/customers/1");
  });

  it("renders empty search results when no customers match a query", () => {
    renderTable({ customers: [], searchQuery: "dale" });

    expect(screen.getByText("Nothing found")).toBeInTheDocument();
  });
});

function renderTable({
  customers = [makeCustomer()],
  searchQuery = "",
}: {
  customers?: CustomerRecord[];
  searchQuery?: string;
} = {}) {
  return render(<Table customers={customers} searchQuery={searchQuery} />);
}
