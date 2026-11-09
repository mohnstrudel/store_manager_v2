import { router } from "@inertiajs/react";
import { act, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { makePagination } from "@/test/factories";
import { mockPage } from "@/test/mocks/inertia";

import { makeWarehousePurchaseItem, makeWarehouseShowRecord } from "../test/factories";
import type { WarehouseOption, WarehousePurchaseItemRecord } from "../types";
import { PurchaseItemsSection } from "./PurchaseItemsSection";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

const writeText = vi.fn<(...args: unknown[]) => Promise<void>>();

describe("Warehouses/Show/PurchaseItemsSection", () => {
  beforeEach(() => {
    mockPage({ url: "/warehouses/1" });
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText },
    });
  });

  it("edits item tracking and shipping inline from the warehouse page", async () => {
    const user = userEvent.setup();

    renderSection({
      purchaseItems: [
        makeWarehousePurchaseItem({
          sale_note: "Handle with care",
          sale_path: "/sales/1",
          sale_summary: "Patricia Morales Ponce, Calle Mirador de la Sierra 20",
          shipping_company_id: 3,
          shipping_company_name: "Skyline",
        }),
      ],
    });

    await user.click(screen.getByLabelText("Edit tracking number"));
    await user.clear(screen.getByLabelText("Tracking number"));
    await user.type(screen.getByLabelText("Tracking number"), "TRACK-99");
    await user.click(screen.getByRole("button", { name: "Save" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/purchase_items/10/tracking_number",
      {
        purchase_item: { tracking_number: "TRACK-99" },
        return_to: "/warehouses/1",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
    expect(screen.queryByLabelText("Tracking number")).not.toBeInTheDocument();
    expect(screen.getByLabelText("Edit tracking number").closest("td")).toHaveClass(
      "bg-lime-100/80",
    );

    await user.click(screen.getByLabelText("Edit shipping company"));
    await user.selectOptions(screen.getByLabelText("Shipping company"), "3");
    await user.click(screen.getByRole("button", { name: "Save" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_company",
      {
        purchase_item: { shipping_company_id: "3" },
        return_to: "/warehouses/1",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
    expect(router.visit).not.toHaveBeenCalled();

    expect(screen.getByLabelText("More information")).toHaveTextContent("*");
  });

  it("auto-opens the shipping editor when starting to edit tracking with no shipping company", async () => {
    const user = userEvent.setup();

    renderSection({ purchaseItems: [makeWarehousePurchaseItem({ shipping_company_id: null })] });

    await user.click(screen.getByLabelText("Edit tracking number"));

    expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
    await waitFor(() => {
      expect(screen.getByLabelText("Shipping company")).toBeInTheDocument();
    });
  });

  it("does not auto-open the shipping editor when tracking already has a shipping company", async () => {
    const user = userEvent.setup();

    renderSection({
      purchaseItems: [
        makeWarehousePurchaseItem({ shipping_company_id: 3, shipping_company_name: "Skyline" }),
      ],
    });

    await user.click(screen.getByLabelText("Edit tracking number"));

    expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
    expect(screen.queryByLabelText("Shipping company")).not.toBeInTheDocument();
  });

  it("shows a shipping required error and does not submit when saving tracking without a shipping company", async () => {
    const user = userEvent.setup();

    renderSection({ purchaseItems: [makeWarehousePurchaseItem({ shipping_company_id: null })] });

    await user.click(screen.getByLabelText("Edit tracking number"));
    await user.type(screen.getByLabelText("Tracking number"), "-updated");
    await user.click(screen.getAllByRole("button", { name: "Save" })[0]);

    expect(screen.getByText("Shipping company is required")).toBeInTheDocument();
    expect(router.patch).not.toHaveBeenCalled();
  });

  it("clears the shipping required error when the user cancels tracking editing", async () => {
    const user = userEvent.setup();

    renderSection({ purchaseItems: [makeWarehousePurchaseItem({ shipping_company_id: null })] });

    await user.click(screen.getByLabelText("Edit tracking number"));
    await user.click(screen.getAllByRole("button", { name: "Save" })[0]);
    expect(screen.getByText("Shipping company is required")).toBeInTheDocument();

    await user.click(screen.getAllByRole("button", { name: "Exit" })[0]);
    await user.click(screen.getByLabelText("Edit tracking number"));

    expect(screen.queryByText("Shipping company is required")).not.toBeInTheDocument();
  });

  it("keeps copy buttons from triggering the warehouse row navigation", async () => {
    const user = userEvent.setup();

    renderSection({
      purchaseItems: [
        makeWarehousePurchaseItem({
          sale_path: "/sales/1",
          sale_summary: "Patricia Morales Ponce, Calle Mirador de la Sierra 20",
        }),
      ],
    });

    await user.click(screen.getAllByRole("button", { name: /Copy/ })[0]);

    expect(router.visit).not.toHaveBeenCalled();
  });

  it("posts the checked rows to the warehouse move path and clears the selection after the move", async () => {
    const user = userEvent.setup();

    renderSection({
      purchaseItems: [
        makeWarehousePurchaseItem({ id: 10 }),
        makeWarehousePurchaseItem({ id: 11 }),
        makeWarehousePurchaseItem({ id: 12 }),
      ],
      warehouseMovePath: "/purchase_items/move?warehouse_id=1",
      warehouses: [
        { id: 1, name: "Warehouse From" },
        { id: 2, name: "Warehouse To" },
      ],
    });

    await user.click(screen.getByLabelText("Select purchase item 10"));
    await user.click(screen.getByLabelText("Select purchase item 11"));
    await user.selectOptions(screen.getByLabelText("Destination warehouse"), "2");
    await user.click(screen.getByRole("button", { name: /Move/ }));

    expect(router.post).toHaveBeenCalledWith(
      "/purchase_items/move?warehouse_id=1",
      expect.objectContaining({ destination_id: "2", selected_items_ids: [10, 11] }),
      expect.anything(),
    );

    const options = vi.mocked(router.post).mock.calls[0][2];
    if (!hasOnSuccess(options)) {
      throw new Error("Expected move success callback");
    }
    act(() => options.onSuccess?.());

    expect(screen.getByLabelText("Select purchase item 10")).not.toBeChecked();
    expect(screen.queryByRole("button", { name: /Move/ })).not.toBeInTheDocument();
  });

  it("opens inline editors without validation errors before submitting", async () => {
    const user = userEvent.setup();

    renderSection({
      purchaseItems: [
        makeWarehousePurchaseItem({ shipping_company_id: 3, shipping_company_name: "Skyline" }),
      ],
    });

    await user.click(screen.getByLabelText("Edit tracking number"));
    await user.click(screen.getByLabelText("Edit shipping company"));

    expect(screen.queryByText("Could not save tracking number")).not.toBeInTheDocument();
    expect(screen.queryByText("Could not save shipping company")).not.toBeInTheDocument();
  });
});

function renderSection({
  purchaseItems = [makeWarehousePurchaseItem()],
  warehouseMovePath = "/purchase_items/move",
  warehouses = [{ id: 1, name: "Warehouse A" }],
}: {
  purchaseItems?: WarehousePurchaseItemRecord[];
  warehouseMovePath?: string;
  warehouses?: WarehouseOption[];
} = {}) {
  return render(
    <PurchaseItemsSection
      pagination={makePagination({ total_count: purchaseItems.length })}
      purchase_items={purchaseItems}
      search={{ q: "" }}
      selected_id={null}
      shipping_companies={[{ id: 3, name: "Skyline" }]}
      total_purchase_items={purchaseItems.length}
      warehouse={makeWarehouseShowRecord()}
      warehouse_move_path={warehouseMovePath}
      warehouses={warehouses}
    />,
  );
}

function hasOnSuccess(value: unknown): value is { onSuccess?: () => void } {
  return typeof value === "object" && value !== null;
}
