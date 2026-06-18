import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import Show from "./Show";
import { makePurchaseItemShowRecord, makeWarehouseMovementRecord } from "./test/factories";

vi.mock("@/components/ImageGallery", () => ({
  default: ({ media }: { media: { length: number }[] }) => (
    <div data-testid="image-gallery">Images: {media.length}</div>
  ),
}));

describe("PurchaseItems/Show", () => {
  it("renders purchase item links, details, and image gallery", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: /Purchase Item 42/ })).toBeInTheDocument();
    expect(screen.getByTestId("image-gallery")).toHaveTextContent("Images: 1");
    expect(screen.getByRole("link", { name: /Purchase$/ })).toHaveAttribute(
      "href",
      "/purchases/10",
    );
    expect(screen.getByRole("link", { name: /Sale$/ })).toHaveAttribute("href", "/sales/7");
    expect(screen.getByRole("link", { name: "Sale Item" })).toHaveAttribute(
      "href",
      "/sale_items/9",
    );
    expect(screen.getByRole("link", { name: "Supplier A" })).toHaveAttribute(
      "href",
      "/suppliers/3",
    );
    expect(screen.getByRole("link", { name: "Product X" })).toHaveAttribute("href", "/products/5");
  });

  it("renders warehouse movement history and shows a dash when a past warehouse link is unavailable", () => {
    renderShow({
      warehouse_movements: [
        makeWarehouseMovementRecord(),
        makeWarehouseMovementRecord({
          id: 2,
          moved_in: "21 May 2026",
          warehouse_name: "Overflow Warehouse",
          warehouse_path: null,
        }),
      ],
    });

    const movementGrid = screen.getByRole("grid");

    expect(within(movementGrid).getByText("Moved in")).toBeInTheDocument();
    expect(within(movementGrid).getByText("21 May 2026")).toBeInTheDocument();
    expect(within(movementGrid).getByText("-")).toBeInTheDocument();
  });

  it("hides optional sale links when the purchase item is not linked to a sale", () => {
    renderShow({ sale_path: null, sale_item_path: null });

    expect(screen.queryByRole("link", { name: "Sale" })).not.toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "Sale Item" })).not.toBeInTheDocument();
  });

  it("destroys the purchase item after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
    renderShow();

    await user.click(screen.getByRole("button", { name: "Destroy this purchase item" }));

    expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
    expect(router.delete).toHaveBeenCalledWith("/purchase_items/42");
  });
});

function renderShow(overrides: Partial<ReturnType<typeof makePurchaseItemShowRecord>> = {}) {
  return render(<Show purchase_item={makePurchaseItemShowRecord(overrides)} />);
}
