import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import MoveToWarehouseForm from "./MoveToWarehouseForm";
import type { WarehouseOption } from "@/types/warehouse";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

afterEach(() => {
  vi.restoreAllMocks();
});

describe("MoveToWarehouseForm", () => {
  it("stays hidden when nothing is selected", () => {
    render(
      <MoveToWarehouseForm
        movePath="/purchase_items/move"
        selectedIds={[]}
        warehouses={makeWarehouses()}
      />,
    );

    expect(screen.queryByRole("combobox")).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /Move/ })).not.toBeInTheDocument();
  });

  it("posts the selected ids and destination to the move path", async () => {
    const user = userEvent.setup();
    const onMoved = vi.fn<() => void>();

    render(
      <MoveToWarehouseForm
        movePath="/purchase_items/move"
        onMoved={onMoved}
        purchaseId={55}
        redirectToSaleItem
        selectedIds={[10, 11]}
        warehouses={makeWarehouses()}
      />,
    );

    await user.selectOptions(screen.getByRole("combobox"), "2");
    await user.click(screen.getByRole("button", { name: /Move/ }));

    expect(router.post).toHaveBeenCalledWith(
      "/purchase_items/move",
      {
        destination_id: "2",
        purchase_id: 55,
        redirect_to_sale_item: true,
        selected_items_ids: [10, 11],
      },
      expect.objectContaining({ onSuccess: onMoved }),
    );

    const options = vi.mocked(router.post).mock.calls[0][2];
    if (!hasOnSuccess(options)) {
      throw new Error("Expected move success callback");
    }
    options.onSuccess?.();
    expect(onMoved).toHaveBeenCalled();
  });

  it("does not submit when no destination is selected", async () => {
    const user = userEvent.setup();

    render(
      <MoveToWarehouseForm
        movePath="/purchase_items/move"
        selectedIds={[10]}
        warehouses={makeWarehouses()}
      />,
    );

    await user.click(screen.getByRole("button", { name: /Move/ }));

    expect(router.post).not.toHaveBeenCalled();
  });
});

function makeWarehouses(): WarehouseOption[] {
  return [
    { id: 1, name: "Berlin Hub" },
    { id: 2, name: "Munich Hub" },
  ];
}

function hasOnSuccess(value: unknown): value is { onSuccess?: () => void } {
  return typeof value === "object" && value !== null;
}
