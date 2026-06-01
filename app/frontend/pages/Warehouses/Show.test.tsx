import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Show from "./Show";
import type { WarehousePurchaseItemRecord, WarehouseShowRecord } from "./types";

const inertia = vi.hoisted(() => ({
  nextErrors: null as Record<string, string> | null,
  writeText: vi.fn<(...args: unknown[]) => Promise<void>>(),
  patch: vi.fn<(...args: unknown[]) => void>((...args: unknown[]) => {
    if (inertia.nextErrors) {
      callOnError(args[2], inertia.nextErrors);
      inertia.nextErrors = null;
    } else {
      callOnSuccess(args[2]);
    }
  }),
  visit: vi.fn<(...args: unknown[]) => unknown>(),
}));

vi.mock("@inertiajs/react", () => ({
  Link: ({
    children,
    href,
    prefetch: _prefetch,
    ...props
  }: {
    children: ReactNode;
    href: string;
    prefetch?: boolean;
  }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
  router: {
    patch: inertia.patch,
    prefetch: vi.fn<(...args: unknown[]) => unknown>(),
    visit: inertia.visit,
  },
}));

describe("Warehouses/Show", () => {
  beforeEach(() => {
    inertia.patch.mockClear();
    inertia.visit.mockClear();
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText: inertia.writeText },
    });
  });

  it("edits item tracking and shipping inline from the warehouse page", async () => {
    const user = userEvent.setup();

    render(
      <Show
        pagination={{ current_page: 1, limit: 25, total_count: 1, total_pages: 1 }}
        purchase_items={[
          makePurchaseItem({
            sale_note: "Handle with care",
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

    await user.click(screen.getByRole("button", { name: "Edit" }));
    await user.clear(screen.getByLabelText("Tracking number"));
    await user.type(screen.getByLabelText("Tracking number"), "TRACK-99");
    await user.click(screen.getByRole("button", { name: "Save" }));

    expect(inertia.patch).toHaveBeenCalledWith(
      "/purchase_items/10/tracking_number",
      {
        purchase_item: { tracking_number: "TRACK-99" },
        return_to: "/warehouses/1",
      },
      expect.objectContaining({ preserveScroll: true }),
    );

    await user.click(screen.getAllByRole("button", { name: "Add" })[0]);
    await user.selectOptions(screen.getByLabelText("Shipping company"), "3");
    await user.click(screen.getByRole("button", { name: "Save" }));

    expect(inertia.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_company",
      {
        purchase_item: { shipping_company_id: "3" },
        return_to: "/warehouses/1",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
    expect(inertia.visit).not.toHaveBeenCalled();

    expect(screen.getByText("Handle with care")).toHaveClass("cursor-text");
  });

  it("keeps copy buttons from triggering the warehouse row navigation", async () => {
    const user = userEvent.setup();

    render(
      <Show
        pagination={{ current_page: 1, limit: 25, total_count: 1, total_pages: 1 }}
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

    expect(inertia.visit).not.toHaveBeenCalled();
  });

  it("keeps validation errors inside the React inline editor", async () => {
    const user = userEvent.setup();

    render(
      <Show
        pagination={{ current_page: 1, limit: 25, total_count: 1, total_pages: 1 }}
        purchase_items={[makePurchaseItem({ shipping_company_id: null, tracking_number: "" })]}
        search={{ q: "" }}
        selected_id={null}
        shipping_companies={[{ id: 3, name: "Skyline" }]}
        total_purchase_items={1}
        warehouse={makeWarehouse()}
        warehouse_move_path="/purchase_items/move"
        warehouses={[{ id: 1, name: "Warehouse A" }]}
      />,
    );

    inertia.nextErrors = { shipping_company_id: "Shipping company can't be blank" };

    await user.click(screen.getAllByRole("button", { name: "Add" })[0]);
    await user.type(screen.getByLabelText("Tracking number"), "TRACK-99");
    await user.click(screen.getByRole("button", { name: "Save" }));

    expect(screen.getByText("Shipping company can't be blank")).toBeInTheDocument();
    expect(screen.getByLabelText("Tracking number")).toHaveValue("TRACK-99");
    expect(inertia.visit).not.toHaveBeenCalled();
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
    shipping_company_update_path: "/purchase_items/10/shipping_company",
    sku: "SKU-10",
    title: "Jacket",
    tracking_number: "TRACK-1",
    tracking_update_path: "/purchase_items/10/tracking_number",
    variant_title: "",
    ...overrides,
  };
}

function callOnSuccess(options: unknown) {
  if (!hasOnSuccessCallback(options)) return;

  options.onSuccess();
}

function callOnError(options: unknown, errors: Record<string, string>) {
  if (!hasOnErrorCallback(options)) return;

  options.onError(errors);
}

function hasOnSuccessCallback(options: unknown): options is { onSuccess: () => void } {
  return (
    typeof options === "object" &&
    options !== null &&
    "onSuccess" in options &&
    typeof options.onSuccess === "function"
  );
}

function hasOnErrorCallback(
  options: unknown,
): options is { onError: (errors: Record<string, string>) => void } {
  return (
    typeof options === "object" &&
    options !== null &&
    "onError" in options &&
    typeof options.onError === "function"
  );
}
