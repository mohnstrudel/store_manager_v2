import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import Index from "./Index";
import { makePagination } from "@/test/factories";
import { makeSaleIndexRecord } from "./test/factories";
import type { PaginationMeta, SaleIndexRecord } from "./types";

describe("Sales/Index", () => {
  it("renders the sales heading and add new record link", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Sales" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/sales/new",
    );
  });

  it("renders the sale customer and product title in the table", () => {
    renderIndex();

    expect(screen.getByText("Dale Cooper")).toBeInTheDocument();
    expect(screen.getByText("Pikachu Figure")).toBeInTheDocument();
  });

  it("renders a search form with the current query", () => {
    renderIndex({ search: { q: "dale" } });

    expect(screen.getByRole("searchbox")).toHaveValue("dale");
  });

  it("shows purchase item warehouse links instead of sale status text", () => {
    renderIndex();

    const warehouseLink = screen.getByRole("link", { name: /Berlin Hub/ });
    expect(warehouseLink).toHaveAttribute("href", "/purchase_items/101");
    expect(screen.queryByText("Processing")).not.toBeInTheDocument();
  });

  it("renders an empty state when a search has no matches", () => {
    renderIndex({
      pagination: makePagination({ total_count: 0 }),
      sales: [],
      search: { q: "missing sale" },
    });

    expect(screen.getByText("Nothing found")).toBeInTheDocument();
  });

  describe("Store Sync dialog", () => {
    it("renders the Store Sync button", () => {
      renderIndex();

      expect(screen.getByRole("button", { name: "Store Sync" })).toBeInTheDocument();
    });

    it("opens the dialog when Store Sync is clicked", async () => {
      const user = userEvent.setup();
      renderIndex();

      await user.click(screen.getByRole("button", { name: "Store Sync" }));

      expect(screen.getByText("Sales Synchronization")).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Fetch Everything" })).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Fetch Last 100 Sales" })).toBeInTheDocument();
      expect(screen.getByRole("link", { name: "Track Jobs Progress" })).toBeInTheDocument();
    });

    it("shows the last sync time when last_sync_time is provided", async () => {
      const user = userEvent.setup();
      renderIndex({ last_sync_time: "20.05 at 10:00" });

      await user.click(screen.getByRole("button", { name: "Store Sync" }));

      expect(screen.getByText("Last sync: 20.05 at 10:00")).toBeInTheDocument();
    });

    it("closes the dialog when Close is clicked", async () => {
      const user = userEvent.setup();
      renderIndex();

      await user.click(screen.getByRole("button", { name: "Store Sync" }));
      await user.click(screen.getByRole("button", { name: "Close" }));

      expect(screen.queryByText("Sales Synchronization")).not.toBeInTheDocument();
    });
  });
});

function renderIndex({
  sales = [makeSaleIndexRecord()],
  pagination = makePagination(),
  search = { q: "" },
  last_sync_time = "20.05 at 10:00",
}: {
  sales?: SaleIndexRecord[];
  pagination?: PaginationMeta;
  search?: { q: string };
  last_sync_time?: string | null;
} = {}) {
  return render(
    <Index last_sync_time={last_sync_time} pagination={pagination} sales={sales} search={search} />,
  );
}
