import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import { mockPage } from "@/test/mocks/inertia";
import Show from "./Show";
import {
  makePagination,
  makeWarehousePurchaseItem,
  makeWarehouseShowRecord,
} from "./test/factories";
import type { WarehousePurchaseItemRecord, WarehouseShowRecord } from "./types";

vi.mock("@/components/ImageGallery", () => ({
  default: () => <div data-testid="image-gallery" />,
}));

describe("Warehouses/Show", () => {
  beforeEach(() => {
    mockPage({ url: "/warehouses/1" });
  });

  it("renders the warehouse name and navigation links", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "Main Warehouse" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/warehouses/1/edit",
    );
    expect(screen.getByRole("link", { name: /Add product/ })).toHaveAttribute(
      "href",
      "/warehouses/1/items/new",
    );
  });

  it("renders the purchase items section when items are present", () => {
    renderShow({ purchaseItems: [makeWarehousePurchaseItem()] });

    expect(screen.getByText("Jacket")).toBeInTheDocument();
  });

  it("hides the purchase items section when the warehouse has no items", () => {
    renderShow({ purchaseItems: [], totalPurchaseItems: 0 });

    expect(screen.queryByText("Jacket")).not.toBeInTheDocument();
  });

  describe("destroy", () => {
    it("destroys the warehouse after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this warehouse" }));

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/warehouses/1");
    });

    it("does not destroy the warehouse when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this warehouse" }));

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({
  purchaseItems = [makeWarehousePurchaseItem()],
  totalPurchaseItems = 1,
  warehouse = makeWarehouseShowRecord(),
}: {
  purchaseItems?: WarehousePurchaseItemRecord[];
  totalPurchaseItems?: number;
  warehouse?: WarehouseShowRecord;
} = {}) {
  return render(
    <Show
      pagination={makePagination({ total_count: totalPurchaseItems })}
      purchase_items={purchaseItems}
      search={{ q: "" }}
      selected_id={null}
      shipping_companies={[]}
      total_purchase_items={totalPurchaseItems}
      warehouse={warehouse}
      warehouse_move_path="/purchase_items/move"
      warehouses={[]}
    />,
  );
}
