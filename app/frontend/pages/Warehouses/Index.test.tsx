import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import { router } from "@inertiajs/react";
import Index from "./Index";
import { makeWarehouseRecord } from "./test/factories";
import type { WarehouseRecord } from "./Index/Table";

describe("Warehouses/Index", () => {
  it("renders the heading, column headers, and warehouse rows", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Warehouses" })).toBeInTheDocument();
    expect(screen.getByRole("columnheader", { name: "Products" })).toBeInTheDocument();
    expect(screen.getByText("Main Warehouse")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/warehouses/1/edit",
    );
  });

  it("merges name and external name into a single column header", () => {
    renderIndex();

    expect(
      screen.getByRole("columnheader", { name: "Name + External Name for Clients" }),
    ).toBeInTheDocument();
    expect(screen.queryByRole("columnheader", { name: "External Name" })).not.toBeInTheDocument();
  });

  it("marks the default warehouse with a tip indicator", () => {
    renderIndex({ warehouses: [makeWarehouseRecord({ is_default: true })] });

    const star = screen.getByLabelText("More information");
    expect(star).toHaveClass("tip_mark__trigger");
  });

  it("does not show a default tip for non-default warehouses", () => {
    renderIndex({ warehouses: [makeWarehouseRecord({ is_default: false })] });

    expect(screen.queryByLabelText("More information")).not.toBeInTheDocument();
  });

  describe("position select", () => {
    it("patches the position path when a new position is selected", async () => {
      const user = userEvent.setup();
      renderIndex({
        warehouses: [makeWarehouseRecord({ position: 1, positions: [1, 2] })],
      });

      await user.selectOptions(
        screen.getByRole("combobox", { name: "Position for Main Warehouse" }),
        "2",
      );

      expect(router.patch).toHaveBeenCalledWith("/warehouses/1/position", { position: "2" });
    });

    it("does nothing when position_path is empty", async () => {
      const user = userEvent.setup();
      renderIndex({
        warehouses: [makeWarehouseRecord({ position: 1, positions: [1, 2], position_path: "" })],
      });

      await user.selectOptions(
        screen.getByRole("combobox", { name: "Position for Main Warehouse" }),
        "2",
      );

      expect(router.patch).not.toHaveBeenCalled();
    });
  });
});

function renderIndex({
  warehouses = [makeWarehouseRecord()],
}: { warehouses?: WarehouseRecord[] } = {}) {
  return render(<Index warehouses={warehouses} />);
}
