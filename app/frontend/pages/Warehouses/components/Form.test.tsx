import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Form from "./Form";
import type { WarehouseFormOptions, WarehouseFormRecord } from "../types";

let pageErrors: Record<string, string> = {};

vi.mock("@inertiajs/react", () => ({
  usePage: () => ({ props: { errors: pageErrors } }),
}));

vi.mock("@/components/ResourceForm", () => ({
  default: ({
    action,
    cancelHref,
    children,
    method,
    submitLabel,
  }: {
    action: string;
    cancelHref: string;
    children: ReactNode;
    method: string;
    submitLabel: string;
  }) => (
    <form action={action} data-cancel-href={cancelHref} data-method={method}>
      {children}
      <button type="submit">{submitLabel}</button>
    </form>
  ),
}));

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

const options: WarehouseFormOptions = {
  positions: [1, 2, 3],
  transition_destinations: [
    { id: 10, name: "Berlin Warehouse" },
    { id: 20, name: "Tokyo Warehouse" },
  ],
};

function makeWarehouse(overrides: Partial<WarehouseFormRecord> = {}): WarehouseFormRecord {
  return {
    cbm: "12.5",
    container_tracking_number: "CONT-1",
    courier_tracking_url: "https://tracking.example/package",
    desc_de: "Deutsche Beschreibung",
    desc_en: "English description",
    external_name_de: "Lager",
    external_name_en: "Warehouse",
    id: 1,
    is_default: false,
    media: [
      {
        alt: "Warehouse front",
        id: 1,
        position: 0,
        preview_url: "/warehouse.png",
        thumb_url: "/warehouse-thumb.png",
        _destroy: false,
      },
    ],
    name: "Main Warehouse",
    path: "/warehouses/1",
    position: 2,
    transition_ids: [10],
    ...overrides,
  };
}

describe("Warehouses/Components/Form", () => {
  beforeEach(() => {
    pageErrors = {};
  });

  it("renders the warehouse form sections with the correct shell configuration", () => {
    const { container } = render(
      <Form
        isNew={false}
        options={options}
        submitLabel="Update Warehouse"
        warehouse={makeWarehouse()}
      />,
    );
    const form = container.querySelector("form");

    expect(form).toHaveAttribute("action", "/warehouses/1");
    expect(form).toHaveAttribute("data-cancel-href", "/warehouses/1");
    expect(form).toHaveAttribute("data-method", "patch");
    expect(screen.getByLabelText("Name")).toHaveValue("Main Warehouse");
    expect(screen.getByLabelText("CBM")).toHaveValue("12.5");
    expect(screen.getByLabelText("Position")).toHaveValue("2");
    expect(screen.getByLabelText("Default Warehouse")).toHaveValue("0");
    expect(screen.getByLabelText("External Name in English")).toHaveValue("Warehouse");
    expect(screen.getByLabelText("English Description")).toHaveValue("English description");
    expect(screen.getByLabelText("Container Tracking Number")).toHaveValue("CONT-1");
    expect(screen.getByTestId("image-uploader")).toHaveAttribute(
      "data-field-name-prefix",
      "warehouse[media]",
    );
    expect(screen.getByTestId("image-uploader")).toHaveAttribute("data-image-field-name", "image");
    expect(screen.getByTestId("image-uploader")).toHaveAttribute("data-media-count", "1");
    expect(screen.getByLabelText("Destination Warehouse 1")).toHaveValue("10");
  });

  it("shows validation errors on matching fields", () => {
    pageErrors = { name: "can't be blank", position: "is invalid" };

    render(
      <Form
        isNew
        options={options}
        submitLabel="Create Warehouse"
        warehouse={makeWarehouse({ path: "" })}
      />,
    );

    expect(screen.getByText("can't be blank")).toBeInTheDocument();
    expect(screen.getByText("is invalid")).toBeInTheDocument();
    expect(screen.getByLabelText("Name").parentElement).toHaveClass("field_with_errors");
    expect(screen.getByLabelText("Position").parentElement).toHaveClass("field_with_errors");
  });

  it("preserves transition rows and shows errors when re-rendered after a failed submit", async () => {
    const user = userEvent.setup();

    const { rerender } = render(
      <Form
        isNew
        options={options}
        submitLabel="Create Warehouse"
        warehouse={makeWarehouse({ transition_ids: [] })}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Add Transition" }));
    await user.selectOptions(screen.getByLabelText("Destination Warehouse 1"), "20");

    pageErrors = { name: "can't be blank" };
    rerender(
      <Form
        isNew
        options={options}
        submitLabel="Create Warehouse"
        warehouse={makeWarehouse({ transition_ids: [] })}
      />,
    );

    expect(screen.getByText("can't be blank")).toBeInTheDocument();
    expect(screen.getByLabelText("Destination Warehouse 1")).toHaveValue("20");
  });

  it("adds, changes, and removes transition notification rows", async () => {
    const user = userEvent.setup();

    render(
      <Form
        isNew
        options={options}
        submitLabel="Create Warehouse"
        warehouse={makeWarehouse({ transition_ids: [] })}
      />,
    );

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
