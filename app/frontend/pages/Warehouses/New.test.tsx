import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import New from "./New";
import { makeWarehouseFormOptions, makeWarehouseFormRecord } from "./test/factories";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

vi.mock("@/components/ImageUploader", () => ({
  default: () => <div data-testid="image-uploader" />,
}));

describe("Warehouses/New", () => {
  it("renders the heading and form", () => {
    renderNew();

    expect(screen.getByRole("heading", { name: "New Warehouse" })).toBeInTheDocument();
    expect(screen.getByLabelText("Name")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Warehouse" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { name: "can't be blank" } });

    renderNew();

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});

function renderNew() {
  return render(
    <New
      options={makeWarehouseFormOptions()}
      warehouse={makeWarehouseFormRecord({ id: null, path: "" })}
    />,
  );
}
