import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import { mockPage } from "@/test/mocks/inertia";
import Show from "./Show";
import type { WarehousePurchaseItemRecord, WarehouseShowRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

const writeText = vi.fn<(...args: unknown[]) => Promise<void>>();

describe("Warehouses/Show", () => {
  beforeEach(() => {
    mockPage({ url: "/warehouses/1" });
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText },
    });
  });

  it("edits item tracking and shipping inline from the warehouse page", async () => {
    const user = userEvent.setup();

    render(
      <Show
        pagination={{
          current_page: 1,
          limit: 25,
          total_count: 1,
          total_pages: 1,
        }}
        purchase_items={[
          makePurchaseItem({
            sale_note: "Handle with care",
            sale_path: "/sales/1",
            sale_summary: "Patricia Morales Ponce, Calle Mirador de la Sierra 20",
            shipping_company_id: 3,
            shipping_company_name: "Skyline",
          }),
        ]}
        search={{ q: "" }}
        selected_id={null}
        shipping_companies={[{ id: 3, name: "Skyline" }]}
        total_purchase_items={1}
        warehouse={makeWarehouse()}
        warehouse_move_path="/purchase_items/move"
        warehouses={[{ id: 1, name: "Warehouse A" }]}
      />,
    );

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

    expect(screen.getByText("Handle with care")).toHaveClass("cursor-text");
  });

  it("auto-opens the shipping editor when starting to edit tracking with no shipping company", async () => {
    const user = userEvent.setup();

    render(
      <Show
        pagination={{
          current_page: 1,
          limit: 25,
          total_count: 1,
          total_pages: 1,
        }}
        purchase_items={[makePurchaseItem({ shipping_company_id: null })]}
        search={{ q: "" }}
        selected_id={null}
        shipping_companies={[{ id: 3, name: "Skyline" }]}
        total_purchase_items={1}
        warehouse={makeWarehouse()}
        warehouse_move_path="/purchase_items/move"
        warehouses={[{ id: 1, name: "Warehouse A" }]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));

    expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
    await waitFor(() => {
      expect(screen.getByLabelText("Shipping company")).toBeInTheDocument();
    });
  });

  it("does not auto-open the shipping editor when tracking already has a shipping company", async () => {
    const user = userEvent.setup();

    render(
      <Show
        pagination={{
          current_page: 1,
          limit: 25,
          total_count: 1,
          total_pages: 1,
        }}
        purchase_items={[
          makePurchaseItem({
            shipping_company_id: 3,
            shipping_company_name: "Skyline",
          }),
        ]}
        search={{ q: "" }}
        selected_id={null}
        shipping_companies={[{ id: 3, name: "Skyline" }]}
        total_purchase_items={1}
        warehouse={makeWarehouse()}
        warehouse_move_path="/purchase_items/move"
        warehouses={[{ id: 1, name: "Warehouse A" }]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));

    expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
    expect(screen.queryByLabelText("Shipping company")).not.toBeInTheDocument();
  });

  it("shows a shipping required error and does not submit when saving tracking without a shipping company", async () => {
    const user = userEvent.setup();

    render(
      <Show
        pagination={{
          current_page: 1,
          limit: 25,
          total_count: 1,
          total_pages: 1,
        }}
        purchase_items={[makePurchaseItem({ shipping_company_id: null })]}
        search={{ q: "" }}
        selected_id={null}
        shipping_companies={[{ id: 3, name: "Skyline" }]}
        total_purchase_items={1}
        warehouse={makeWarehouse()}
        warehouse_move_path="/purchase_items/move"
        warehouses={[{ id: 1, name: "Warehouse A" }]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));
    await user.type(screen.getByLabelText("Tracking number"), "-updated");
    // Tracking Save is first in DOM (before auto-opened shipping Save)
    await user.click(screen.getAllByRole("button", { name: "Save" })[0]);

    expect(screen.getByText("Shipping company is required")).toBeInTheDocument();
    expect(router.patch).not.toHaveBeenCalled();
  });

  it("clears the shipping required error when the user cancels tracking editing", async () => {
    const user = userEvent.setup();

    render(
      <Show
        pagination={{
          current_page: 1,
          limit: 25,
          total_count: 1,
          total_pages: 1,
        }}
        purchase_items={[makePurchaseItem({ shipping_company_id: null })]}
        search={{ q: "" }}
        selected_id={null}
        shipping_companies={[{ id: 3, name: "Skyline" }]}
        total_purchase_items={1}
        warehouse={makeWarehouse()}
        warehouse_move_path="/purchase_items/move"
        warehouses={[{ id: 1, name: "Warehouse A" }]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));
    await user.click(screen.getAllByRole("button", { name: "Save" })[0]);
    expect(screen.getByText("Shipping company is required")).toBeInTheDocument();

    // Exit tracking — shipping stays open from auto-open; tracking cell becomes clickable again
    await user.click(screen.getAllByRole("button", { name: "Exit" })[0]);
    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));

    expect(screen.queryByText("Shipping company is required")).not.toBeInTheDocument();
  });

  it("keeps copy buttons from triggering the warehouse row navigation", async () => {
    const user = userEvent.setup();

    render(
      <Show
        pagination={{
          current_page: 1,
          limit: 25,
          total_count: 1,
          total_pages: 1,
        }}
        purchase_items={[
          makePurchaseItem({
            sale_path: "/sales/1",
            sale_summary: "Patricia Morales Ponce, Calle Mirador de la Sierra 20",
          }),
        ]}
        search={{ q: "" }}
        selected_id={null}
        shipping_companies={[{ id: 3, name: "Skyline" }]}
        total_purchase_items={1}
        warehouse={makeWarehouse()}
        warehouse_move_path="/purchase_items/move"
        warehouses={[{ id: 1, name: "Warehouse A" }]}
      />,
    );

    await user.click(screen.getAllByRole("button", { name: /Copy/ })[0]);

    expect(router.visit).not.toHaveBeenCalled();
  });

  it("opens inline editors without validation errors before submitting", async () => {
    const user = userEvent.setup();

    render(
      <Show
        pagination={{
          current_page: 1,
          limit: 25,
          total_count: 1,
          total_pages: 1,
        }}
        purchase_items={[
          makePurchaseItem({
            shipping_company_id: 3,
            shipping_company_name: "Skyline",
          }),
        ]}
        search={{ q: "" }}
        selected_id={null}
        shipping_companies={[{ id: 3, name: "Skyline" }]}
        total_purchase_items={1}
        warehouse={makeWarehouse()}
        warehouse_move_path="/purchase_items/move"
        warehouses={[{ id: 1, name: "Warehouse A" }]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));
    await user.click(screen.getByRole("button", { name: "Edit shipping company" }));

    expect(screen.queryByText("Could not save tracking number")).not.toBeInTheDocument();
    expect(screen.queryByText("Could not save shipping company")).not.toBeInTheDocument();
  });
});

function makeWarehouse(): WarehouseShowRecord {
  return {
    cbm: "1.0",
    container_tracking_number: "",
    courier_tracking_url: "",
    created_at: "01 Jun 2026",
    desc_de: "",
    desc_en: "",
    destroy_path: "/warehouses/1",
    edit_path: "/warehouses/1/edit",
    external_name_de: "",
    external_name_en: "",
    id: 1,
    is_default: false,
    media: [],
    name: "Warehouse A",
    new_item_path: "/warehouses/1/items/new",
    payment_progress: { debt: "$0", paid: "", price: "", progress: 0 },
  };
}

function makePurchaseItem(
  overrides: Partial<WarehousePurchaseItemRecord> = {},
): WarehousePurchaseItemRecord {
  return {
    customer_email: "buyer@example.com",
    id: 10,
    path: "/purchase_items/10",
    payment_progress: { debt: "$0", paid: "$0", price: "$0", progress: 0 },
    sale_note: "",
    sale_path: null,
    sale_store_type: null,
    sale_summary: "",
    sale_title: "",
    shipping_company_id: null,
    shipping_company_name: "",
    sku: "SKU-10",
    title: "Jacket",
    tracking_number: "TRACK-1",
    variant_title: "",
    ...overrides,
  };
}
