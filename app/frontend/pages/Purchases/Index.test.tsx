import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { makePagination } from "@/test/factories";

import Index from "./Index";
import { makePurchaseIndexRecord, makeWarehouseOption } from "./test/factories";
import type { PaginationMeta, PurchaseIndexRecord, WarehouseOption } from "./types";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

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

  it("shows how many items of a purchase sit in each warehouse", () => {
    renderIndex({
      purchases: [
        makePurchaseIndexRecord({
          warehouse_counts: [{ warehouse_name: "Warehouse From", count: 3 }],
        }),
      ],
    });

    expect(screen.getByText("Warehouse From ← 3")).toBeInTheDocument();
  });

  it("posts the checked purchases to the move path", async () => {
    const user = userEvent.setup();
    renderIndex({
      purchases: [makePurchaseIndexRecord({ id: 1 }), makePurchaseIndexRecord({ id: 2 })],
      warehouses: [makeWarehouseOption({ id: 7, name: "Warehouse To" })],
    });

    await user.click(screen.getByLabelText("Select purchase 1"));
    await user.selectOptions(screen.getByLabelText("Destination warehouse"), "7");
    await user.click(screen.getByRole("button", { name: /Move/ }));

    expect(router.post).toHaveBeenCalledWith(
      "/purchases/move",
      expect.objectContaining({ destination_id: "7", selected_items_ids: [1] }),
      expect.anything(),
    );
  });

  it("reloads only the purchase list props when searching", async () => {
    const user = userEvent.setup();
    renderIndex();

    await user.type(screen.getByRole("searchbox"), "Asuka");
    await user.click(screen.getByRole("button", { name: /Search/ }));

    expect(router.get).toHaveBeenCalledWith(
      "/purchases",
      { q: "Asuka" },
      expect.objectContaining({ only: ["purchases", "pagination", "search"], preserveState: true }),
    );
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
