import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import Show from "./Show";
import {
  makeSaleItemPurchaseItemRecord,
  makeSaleItemShowRecord,
  makeWarehouseOption,
} from "./test/factories";

describe("SaleItems/Show", () => {
  it("renders the sale item heading, product and sale links, and linked purchase item rows", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "Sale Item" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Pikachu Figure" })).toBeInTheDocument();
    expect(screen.getByText(/Amount: 2/)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Product$/ })).toHaveAttribute("href", "/products/5");
    expect(screen.getByRole("link", { name: /Sale$/ })).toHaveAttribute("href", "/sales/7");
    expect(screen.getByRole("heading", { name: /Linked Purchased Items/ })).toBeInTheDocument();
    expect(screen.getByText("Main Warehouse")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/purchase_items/42/edit",
    );
  });

  it("reveals the move form when a purchase item is selected", async () => {
    const user = userEvent.setup();
    renderShow();

    expect(screen.queryByRole("button", { name: /Move/ })).not.toBeInTheDocument();

    await user.click(screen.getByRole("checkbox"));

    expect(screen.getByRole("button", { name: /Move.*1/ })).toBeInTheDocument();
  });

  it("unlinks a purchase item after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
    renderShow();

    await user.click(screen.getByRole("button", { name: /Unlink$/ }));

    expect(window.confirm).toHaveBeenCalledWith("Unlink this purchase item?");
    expect(router.delete).toHaveBeenCalledWith("/purchase_items/42/unlink_sale_item");
  });

  it("hides the linked purchase items section when there are no linked purchase items", () => {
    renderShow({ purchase_items: [] });

    expect(
      screen.queryByRole("heading", { name: /Linked Purchased Items/ }),
    ).not.toBeInTheDocument();
  });
});

function renderShow({
  purchase_items = [makeSaleItemPurchaseItemRecord()],
  sale_item = makeSaleItemShowRecord(),
  warehouse_move_path = "/purchase_items/move",
  warehouses = [makeWarehouseOption()],
}: {
  purchase_items?: ReturnType<typeof makeSaleItemPurchaseItemRecord>[];
  sale_item?: ReturnType<typeof makeSaleItemShowRecord>;
  warehouse_move_path?: string;
  warehouses?: ReturnType<typeof makeWarehouseOption>[];
} = {}) {
  return render(
    <Show
      purchase_items={purchase_items}
      sale_item={sale_item}
      warehouse_move_path={warehouse_move_path}
      warehouses={warehouses}
    />,
  );
}
