import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it } from "vitest";
import Table from "./Table";
import { makeCustomer } from "../test/factories";
import type { CustomerRecord } from "../types";

describe("Customers/components/Table", () => {
  it("renders customer rows with edit links", () => {
    renderTable();

    expect(screen.getByRole("cell", { name: "Dale Cooper" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/customers/1/edit");
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

  it("shows nothing for missing identifiers and contact details", () => {
    renderTable({
      customers: [makeCustomer({ woo_store_id: "", email: "", phone: "" })],
    });

    const row = screen.getByRole("cell", { name: "Dale Cooper" }).closest("tr")!;
    const cells = within(row).getAllByRole("cell");

    expect(cells[0]).toHaveTextContent("");
    expect(cells[2]).toHaveTextContent("");
    expect(cells[3]).toHaveTextContent("");
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
