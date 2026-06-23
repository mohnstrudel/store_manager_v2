import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";
import Form from "./Form";
import { makeWarehouseFormOptions, makeWarehouseFormRecord } from "../test/factories";
import type { WarehouseFormOptions, WarehouseFormRecord } from "../types";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

vi.mock("@/components/ImageUploader", () => ({
  default: ({
    fieldNamePrefix,
    imageFieldName,
    media,
  }: {
    fieldNamePrefix?: string;
    imageFieldName?: string;
    media: unknown[];
  }) => (
    <div
      data-field-name-prefix={fieldNamePrefix}
      data-image-field-name={imageFieldName}
      data-media-count={media.length}
      data-testid="image-uploader"
    />
  ),
}));

describe("Warehouses/components/Form", () => {
  it("configures action, method, and labels for a new warehouse", () => {
    renderForm({ isNew: true, warehouse: makeWarehouseFormRecord({ id: null, path: "" }) });

    expect(lastCapturedProps()).toEqual(
      expect.objectContaining({
        action: "/warehouses",
        cancelHref: "/warehouses",
        method: "post",
        submitLabel: "Create Warehouse",
      }),
    );
  });

  it("configures action, method, and labels for an existing warehouse", () => {
    renderForm({ isNew: false });

    expect(lastCapturedProps()).toEqual(
      expect.objectContaining({
        action: "/warehouses/1",
        cancelHref: "/warehouses/1",
        method: "patch",
        submitLabel: "Update Warehouse",
      }),
    );
  });

  it("renders the warehouse form sections with current field values", () => {
    renderForm({ isNew: false });

    expect(screen.getByLabelText("Name")).toHaveValue("Main Warehouse");
    expect(screen.getByLabelText("CBM")).toHaveValue("12.5");
    expect(screen.getByLabelText("Position")).toHaveValue("2");
    expect(screen.getByLabelText("Default Warehouse")).toHaveValue("0");
    expect(screen.getByLabelText("External Name in English")).toHaveValue("Warehouse");
    expect(screen.getByLabelText("English Description")).toHaveValue("English description");
    expect(screen.getByLabelText("Container Tracking Number")).toHaveValue("CONT-1");
  });

  it("renders the image uploader with the correct field config", () => {
    renderForm({ isNew: false });

    expect(screen.getByTestId("image-uploader")).toHaveAttribute(
      "data-field-name-prefix",
      "warehouse[media]",
    );
    expect(screen.getByTestId("image-uploader")).toHaveAttribute("data-image-field-name", "image");
    expect(screen.getByTestId("image-uploader")).toHaveAttribute("data-media-count", "1");
  });

  it("renders existing transition rows", () => {
    renderForm({ isNew: false });

    expect(screen.getByLabelText("Destination Warehouse 1")).toHaveValue("10");
  });

  it("shows validation errors on matching fields", () => {
    mockPageProps({ errors: { name: "can't be blank", position: "is invalid" } });

    renderForm({ isNew: true, warehouse: makeWarehouseFormRecord({ path: "" }) });

    expect(screen.getByText("can't be blank")).toBeInTheDocument();
    expect(screen.getByText("is invalid")).toBeInTheDocument();
    expect(screen.getByLabelText("Name").parentElement).toHaveClass("field_with_errors");
    expect(screen.getByLabelText("Position").parentElement).toHaveClass("field_with_errors");
  });

  it("preserves transition rows and shows errors when re-rendered after a failed submit", async () => {
    const user = userEvent.setup();

    const { rerender } = renderForm({
      isNew: true,
      warehouse: makeWarehouseFormRecord({ transition_ids: [] }),
    });

    await user.click(screen.getByRole("button", { name: "Add Transition" }));
    await user.selectOptions(screen.getByLabelText("Destination Warehouse 1"), "20");

    mockPageProps({ errors: { name: "can't be blank" } });
    rerender(
      <Form
        isNew
        options={makeWarehouseFormOptions()}
        submitLabel="Create Warehouse"
        warehouse={makeWarehouseFormRecord({ transition_ids: [] })}
      />,
    );

    expect(screen.getByText("can't be blank")).toBeInTheDocument();
    expect(screen.getByLabelText("Destination Warehouse 1")).toHaveValue("20");
  });

  it("adds, changes, and removes transition notification rows", async () => {
    const user = userEvent.setup();

    renderForm({ isNew: true, warehouse: makeWarehouseFormRecord({ transition_ids: [] }) });

    expect(screen.queryByLabelText("Destination Warehouse 1")).not.toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "Add Transition" }));

    const destination = screen.getByLabelText("Destination Warehouse 1");
    expect(destination).toHaveValue("");

    await user.selectOptions(destination, "20");
    expect(destination).toHaveValue("20");

    await user.click(screen.getByRole("button", { name: "Remove" }));

    expect(screen.queryByLabelText("Destination Warehouse 1")).not.toBeInTheDocument();
  });
});

function renderForm({
  isNew = false,
  options = makeWarehouseFormOptions(),
  submitLabel = isNew ? "Create Warehouse" : "Update Warehouse",
  warehouse = makeWarehouseFormRecord(),
}: {
  isNew?: boolean;
  options?: WarehouseFormOptions;
  submitLabel?: string;
  warehouse?: WarehouseFormRecord;
} = {}) {
  return render(
    <Form isNew={isNew} options={options} submitLabel={submitLabel} warehouse={warehouse} />,
  );
}
