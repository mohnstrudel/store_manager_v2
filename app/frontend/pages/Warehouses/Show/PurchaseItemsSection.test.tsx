import { router } from "@inertiajs/react";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { makePagination } from "@/test/factories";
import { mockPage } from "@/test/mocks/inertia";

import { makeWarehousePurchaseItem, makeWarehouseShowRecord } from "../test/factories";
import type { WarehousePurchaseItemRecord } from "../types";
import { PurchaseItemsSection } from "./PurchaseItemsSection";

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

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));
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
    expect(screen.getByRole("button", { name: "Edit tracking number" }).closest("td")).toHaveClass(
      "bg-lime-100/80",
    );

    await user.click(screen.getByRole("button", { name: "Edit shipping company" }));
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

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));

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

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));

    expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
    expect(screen.queryByLabelText("Shipping company")).not.toBeInTheDocument();
  });

  it("shows a shipping required error and does not submit when saving tracking without a shipping company", async () => {
    const user = userEvent.setup();

    renderSection({ purchaseItems: [makeWarehousePurchaseItem({ shipping_company_id: null })] });

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));
    await user.type(screen.getByLabelText("Tracking number"), "-updated");
    // Tracking Save is first in DOM (before auto-opened shipping Save)
    await user.click(screen.getAllByRole("button", { name: "Save" })[0]);

    expect(screen.getByText("Shipping company is required")).toBeInTheDocument();
    expect(router.patch).not.toHaveBeenCalled();
  });

  it("clears the shipping required error when the user cancels tracking editing", async () => {
    const user = userEvent.setup();

    renderSection({ purchaseItems: [makeWarehousePurchaseItem({ shipping_company_id: null })] });

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));
    await user.click(screen.getAllByRole("button", { name: "Save" })[0]);
    expect(screen.getByText("Shipping company is required")).toBeInTheDocument();

    await user.click(screen.getAllByRole("button", { name: "Exit" })[0]);
    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));

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

  it("opens inline editors without validation errors before submitting", async () => {
    const user = userEvent.setup();

    renderSection({
      purchaseItems: [
        makeWarehousePurchaseItem({ shipping_company_id: 3, shipping_company_name: "Skyline" }),
      ],
    });

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));
    await user.click(screen.getByRole("button", { name: "Edit shipping company" }));

    expect(screen.queryByText("Could not save tracking number")).not.toBeInTheDocument();
    expect(screen.queryByText("Could not save shipping company")).not.toBeInTheDocument();
  });
});

function renderSection({
  purchaseItems = [makeWarehousePurchaseItem()],
}: {
  purchaseItems?: WarehousePurchaseItemRecord[];
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
      warehouse_move_path="/purchase_items/move"
      warehouses={[{ id: 1, name: "Warehouse A" }]}
    />,
  );
}
