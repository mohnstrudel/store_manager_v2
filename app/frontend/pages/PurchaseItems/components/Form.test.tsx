import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Form from "./Form";
import type { PurchaseItemFormOptions, PurchaseItemFormRecord } from "../types";

let pageErrors: Record<string, string> = {};

vi.mock("@/components/ResourceForm", () => ({
  default: ({
    action,
    cancelHref,
    children,
    method,
    submitLabel,
    validate: _validate,
  }: {
    action: string;
    cancelHref: string;
    children: ReactNode | ((props: { errors: Record<string, string> }) => ReactNode);
    method: string;
    submitLabel: string;
    validate?: unknown;
  }) => (
    <form action={action} data-cancel-href={cancelHref} data-method={method}>
      {typeof children === "function" ? children({ errors: pageErrors }) : children}
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

vi.mock("@/components/FormSmartSelect", () => ({
  default: ({
    inputId,
    label,
    name,
    defaultValue,
    error,
  }: {
    inputId: string;
    label: string;
    name: string;
    defaultValue: { value: number; label: string } | null;
    error?: string;
  }) => (
    <div data-error={error}>
      <label htmlFor={inputId}>{label}</label>
      <select id={inputId} name={name} defaultValue={defaultValue?.value ?? ""}>
        {defaultValue && <option value={defaultValue.value}>{defaultValue.label}</option>}
      </select>
      {error && <span>{error}</span>}
    </div>
  ),
}));

const options: PurchaseItemFormOptions = {
  warehouses: [
    { value: 1, label: "Main Warehouse" },
    { value: 2, label: "Secondary Warehouse" },
  ],
  purchases: [
    { value: 10, label: "Supplier A | Product X | 2024-01-01" },
    { value: 11, label: "Supplier B | Product Y | 2024-02-01" },
  ],
  sale_items: [
    {
      value: 100,
      label: "1 | Active | Product X | buyer@example.com | Sale ID: 5",
    },
  ],
  shipping_companies: [
    { value: 20, label: "DHL" },
    { value: 21, label: "FedEx" },
  ],
};

function makePurchaseItem(overrides: Partial<PurchaseItemFormRecord> = {}): PurchaseItemFormRecord {
  return {
    id: 42,
    path: "/purchase_items/42",
    purchase_id: 10,
    sale_item_id: null,
    warehouse_id: 1,
    shipping_company_id: 20,
    length: "30",
    width: "20",
    height: "15",
    weight: "2.5",
    expenses: "100.00",
    shipping_cost: "25.00",
    tracking_number: "TRK-001",
    media: [
      {
        id: 1,
        alt: "Item photo",
        position: 0,
        preview_url: "/item.png",
        thumb_url: "/item-thumb.png",
        _destroy: false,
      },
    ],
    redirect_to_sale_item: false,
    ...overrides,
  };
}

describe("PurchaseItems/Components/Form", () => {
  beforeEach(() => {
    pageErrors = {};
  });

  it("renders the form with correct shell configuration and field values", () => {
    const { container } = render(
      <Form
        action="/purchase_items/42"
        cancelHref="/purchase_items/42"
        method="patch"
        options={options}
        purchase_item={makePurchaseItem()}
        submitLabel="Update Purchase Item"
      />,
    );
    const form = container.querySelector("form");

    expect(form).toHaveAttribute("action", "/purchase_items/42");
    expect(form).toHaveAttribute("data-cancel-href", "/purchase_items/42");
    expect(form).toHaveAttribute("data-method", "patch");
    expect(screen.getByLabelText("Warehouse")).toHaveValue("1");
    expect(screen.getByLabelText("Purchase")).toHaveValue("10");
    expect(screen.getByLabelText("Length, cm")).toHaveValue("30");
    expect(screen.getByLabelText("Width, cm")).toHaveValue("20");
    expect(screen.getByLabelText("Height, cm")).toHaveValue("15");
    expect(screen.getByLabelText("Weight, kg")).toHaveValue("2.5");
    expect(screen.getByLabelText("Expenses")).toHaveValue("100.00");
    expect(screen.getByLabelText("Shipping")).toHaveValue("25.00");
    expect(screen.getByLabelText("Tracking Number")).toHaveValue("TRK-001");
    expect(screen.getByLabelText("Shipping Company")).toHaveValue("20");
    expect(screen.getByTestId("image-uploader")).toHaveAttribute(
      "data-field-name-prefix",
      "purchase_item[media]",
    );
    expect(screen.getByTestId("image-uploader")).toHaveAttribute("data-image-field-name", "image");
    expect(screen.getByTestId("image-uploader")).toHaveAttribute("data-media-count", "1");
  });

  it("does not include redirect_to_sale_item hidden field when flag is false", () => {
    const { container } = render(
      <Form
        action="/purchase_items/42"
        cancelHref="/purchase_items/42"
        method="patch"
        options={options}
        purchase_item={makePurchaseItem({ redirect_to_sale_item: false })}
        submitLabel="Update Purchase Item"
      />,
    );

    expect(
      container.querySelector('input[name="purchase_item[redirect_to_sale_item]"]'),
    ).toBeNull();
  });

  it("includes redirect_to_sale_item hidden field when flag is true", () => {
    const { container } = render(
      <Form
        action="/purchase_items/42"
        cancelHref="/purchase_items/42"
        method="patch"
        options={options}
        purchase_item={makePurchaseItem({ redirect_to_sale_item: true })}
        submitLabel="Update Purchase Item"
      />,
    );

    const hiddenInput = container.querySelector(
      'input[name="purchase_item[redirect_to_sale_item]"]',
    );
    expect(hiddenInput).not.toBeNull();
    expect(hiddenInput).toHaveAttribute("value", "1");
  });

  it("shows validation errors on matching fields", () => {
    pageErrors = { length: "is not a number", warehouse_id: "must exist" };

    render(
      <Form
        action="/purchase_items/42"
        cancelHref="/purchase_items/42"
        method="patch"
        options={options}
        purchase_item={makePurchaseItem()}
        submitLabel="Update Purchase Item"
      />,
    );

    expect(screen.getByText("is not a number")).toBeInTheDocument();
    expect(screen.getByText("must exist")).toBeInTheDocument();
  });
});
