import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import Items from "./Items";
import {
  makeSalePurchaseMovement,
  makeSaleShowPurchaseItem,
  makeSaleShowSaleItem,
} from "../test/factories";

describe("Sales/Show/Items", () => {
  it("renders nothing without sale items", () => {
    const { container } = render(<Items saleItems={[]} />);

    expect(container).toBeEmptyDOMElement();
  });

  it("renders the product link, purchase details, and warehouse status", () => {
    render(<Items saleItems={[makeSaleShowSaleItem()]} />);

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
    render(
      <Items
        saleItems={[
          makeSaleShowSaleItem({
            product_thumb_url: null,
            purchase_items: [],
          }),
        ]}
      />,
    );

    expect(screen.getByText("Image unavailable")).toBeInTheDocument();
    expect(screen.getByText("NO PURCHASE")).toBeInTheDocument();
  });

  it("renders warehouse movement history when the purchase item has prior moves", () => {
    render(
      <Items
        saleItems={[
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
        ]}
      />,
    );

    expect(screen.getByText("Moved in")).toBeInTheDocument();
    expect(screen.getByText("Paris Hub")).toBeInTheDocument();
  });

  it("unlinks a purchase item after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
    render(<Items saleItems={[makeSaleShowSaleItem()]} />);

    await user.click(screen.getByRole("button", { name: /Unlink/ }));

    expect(window.confirm).toHaveBeenCalledWith("Unlink this purchase item?");
    expect(router.delete).toHaveBeenCalledWith("/purchase_items/101/unlink");
  });
});
