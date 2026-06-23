import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import SaleItemsTable from "./SaleItemsTable";
import { makeSaleItemTableRow } from "../test/factories";

describe("PurchaseItems/components/SaleItemsTable", () => {
  it("renders nothing without related sale item rows", () => {
    const { container } = render(<SaleItemsTable rows={[]} />);

    expect(container).toBeEmptyDOMElement();
  });

  it("renders linked purchase information and a relink action", () => {
    render(<SaleItemsTable rows={[makeSaleItemTableRow()]} />);

    expect(screen.getByRole("link", { name: "Sale 7" })).toHaveAttribute("href", "/sales/7");
    expect(screen.getByRole("link", { name: /Purchase Item #42/ })).toHaveAttribute(
      "href",
      "/purchase_items/42",
    );
    expect(screen.getByRole("button", { name: "Relink" })).toBeInTheDocument();
  });

  it("links an available sale item after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
    render(
      <SaleItemsTable
        rows={[
          makeSaleItemTableRow({
            is_available: true,
            linked_purchase_item: null,
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Link" }));

    expect(router.post).toHaveBeenCalledWith("/purchase_items/42/link", { sale_item_id: 9 });
  });

  it("unlinks the current sale item after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
    render(
      <SaleItemsTable
        rows={[
          makeSaleItemTableRow({
            is_current: true,
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Unlink" }));

    expect(router.delete).toHaveBeenCalledWith("/purchase_items/42/unlink_sale_item");
  });
});
