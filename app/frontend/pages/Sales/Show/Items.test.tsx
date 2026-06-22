import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import type { WarehouseOption } from "@/types/warehouse";
import Items from "./Items";
import {
  makeSalePurchaseMovement,
  makeSaleShowPurchaseItem,
  makeSaleShowSaleItem,
} from "../test/factories";
import type { SaleShowSaleItemRecord } from "../types";

const warehouses: WarehouseOption[] = [
  { id: 1, name: "Berlin Hub" },
  { id: 2, name: "Paris Hub" },
];

function renderItems(saleItems: SaleShowSaleItemRecord[]) {
  return render(
    <Items
      saleId={7}
      saleItems={saleItems}
      warehouseMovePath="/purchase_items/move"
      warehouses={warehouses}
    />,
  );
}

describe("Sales/Show/Items", () => {
  it("renders nothing without sale items", () => {
    const { container } = renderItems([]);

    expect(container).toBeEmptyDOMElement();
  });

  it("renders the product link, purchase details, and warehouse status", () => {
    renderItems([makeSaleShowSaleItem()]);

    expect(screen.getByRole("link", { name: "Pikachu Figure" })).toHaveAttribute(
      "href",
      "/products/pikachu",
    );
    expect(screen.getByRole("link", { name: /Acme Imports/ })).toHaveAttribute(
      "href",
      "/purchases/55",
    );
    expect(screen.getByRole("link", { name: "Berlin Hub" })).toHaveAttribute(
      "href",
      "/warehouses/1?selected=101#101",
    );
  });

  it("shows the unavailable image placeholder and no-purchase marker", () => {
    renderItems([
      makeSaleShowSaleItem({
        product_thumb_url: null,
        purchase_items: [],
      }),
    ]);

    expect(screen.getByText("Image unavailable")).toBeInTheDocument();
    expect(screen.getByText("NO PURCHASE")).toBeInTheDocument();
  });

  it("hides the checkbox column when no sale items have linked purchases", () => {
    renderItems([
      makeSaleShowSaleItem({ purchase_items: [] }),
      makeSaleShowSaleItem({ id: 12, purchase_items: [] }),
    ]);

    expect(screen.queryByRole("checkbox")).not.toBeInTheDocument();
  });

  it("renders warehouse movement history when the purchase item has prior moves", () => {
    renderItems([
      makeSaleShowSaleItem({
        purchase_items: [
          makeSaleShowPurchaseItem({
            warehouse_movements: [
              makeSalePurchaseMovement(),
              makeSalePurchaseMovement({
                moved_in: "17. May '26 08:30",
                warehouse_name: "Paris Hub",
              }),
            ],
          }),
        ],
      }),
    ]);

    expect(screen.getByText("Moved in")).toBeInTheDocument();
    expect(screen.getByText("Paris Hub")).toBeInTheDocument();
  });

  it("unlinks a purchase item after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
    renderItems([makeSaleShowSaleItem()]);

    await user.click(screen.getByRole("button", { name: /Unlink/ }));

    expect(window.confirm).toHaveBeenCalledWith("Unlink this purchase item?");
    expect(router.delete).toHaveBeenCalledWith("/purchase_items/101/unlink");
  });

  it("reveals the move form only after a purchase item is selected", async () => {
    const user = userEvent.setup();
    renderItems([makeSaleShowSaleItem()]);

    expect(screen.queryByRole("button", { name: /Move/ })).not.toBeInTheDocument();

    await user.click(screen.getByRole("checkbox"));

    expect(screen.getByRole("button", { name: /Move/ })).toBeInTheDocument();
  });

  it("moves the selected purchase items to the chosen warehouse", async () => {
    const user = userEvent.setup();
    renderItems([makeSaleShowSaleItem()]);

    await user.click(screen.getByRole("checkbox"));
    await user.selectOptions(screen.getByRole("combobox"), "2");
    await user.click(screen.getByRole("button", { name: /Move/ }));

    expect(router.post).toHaveBeenCalledWith(
      "/purchase_items/move",
      expect.objectContaining({
        destination_id: "2",
        sale_id: 7,
        selected_items_ids: [101],
      }),
      expect.anything(),
    );
  });
});
