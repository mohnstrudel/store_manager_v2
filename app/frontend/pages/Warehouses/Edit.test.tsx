import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Edit from "./Edit";
import { makeWarehouseFormOptions, makeWarehouseFormRecord } from "./test/factories";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

vi.mock("@/components/ImageUploader", () => ({
  default: () => <div data-testid="image-uploader" />,
}));

describe("Warehouses/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
        render(<Edit options={makeWarehouseFormOptions()} warehouse={makeWarehouseFormRecord()}/>);

    expect(screen.getByRole("heading", { name: "Edit Warehouse" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Warehouse Page/ })).toHaveAttribute(
      "href",
      "/warehouses/1",
    );
    expect(screen.getByLabelText("Name")).toHaveValue("Main Warehouse");
    expect(screen.getByRole("button", { name: "Update Warehouse" })).toBeInTheDocument();
  });
});


