import { render, screen, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Index from "./Index";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

const warehouses = [
  {
    id: 1,
    path: "/warehouses/1",
    edit_path: "/warehouses/1/edit",
    position_path: "/warehouses/1/position",
    position: 1,
    positions: [1, 2],
    name: "In Production",
    is_default: true,
    external_name_en: "In Production",
    cbm: "",
    purchase_items_count: 305,
    has_purchase_items: true,
    payment_progress: { progress: 43, paid: "", price: "", debt: "222 526" },
  },
  {
    id: 2,
    path: "/warehouses/2",
    edit_path: "/warehouses/2/edit",
    position_path: "/warehouses/2/position",
    position: 2,
    positions: [1, 2],
    name: "China: Other Warehouse / Manufacturer",
    is_default: false,
    external_name_en: "Warehouse China",
    cbm: "",
    purchase_items_count: 3,
    has_purchase_items: true,
    payment_progress: { progress: 52, paid: "", price: "", debt: "2 734" },
  },
];

describe("Warehouses/Index", () => {
  it("renders the warehouse table using the pre-React listing layout", () => {
    render(<Index warehouses={warehouses} />);

    expect(screen.getByRole("heading", { name: "Warehouses" })).toBeInTheDocument();
    expect(
      screen.getByRole("columnheader", {
        name: "Name + External Name for Clients",
      }),
    ).toBeInTheDocument();
    expect(screen.queryByRole("columnheader", { name: "External Name" })).not.toBeInTheDocument();
    expect(screen.getByRole("columnheader", { name: "Products" })).toBeInTheDocument();

    const defaultWarehouseRow = screen.getByRole("row", {
      name: /1 In Production.*305 43% \$222 526 debt/,
    });

    expect(within(defaultWarehouseRow).getByText("*")).toHaveClass("text-yellow-600");
    expect(
      within(defaultWarehouseRow).getByText(
        "New purchases go to this warehouse by default. Change it on the edit page.",
      ),
    ).toBeInTheDocument();
    expect(within(defaultWarehouseRow).queryByText("Default")).not.toBeInTheDocument();
  });
});
