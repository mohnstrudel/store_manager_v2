import { render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";

import { makePurchaseItemFormOptions, makePurchaseItemFormRecord } from "../test/factories";
import Form from "./Form";

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
      <select defaultValue={defaultValue?.value ?? ""} id={inputId} name={name}>
        {defaultValue && <option value={defaultValue.value}>{defaultValue.label}</option>}
      </select>
      {error && <span>{error}</span>}
    </div>
  ),
}));

describe("PurchaseItems/components/Form", () => {
  beforeEach(() => {
    mockPageProps({});
  });

  describe("form shell", () => {
    it("configures action, method, and labels for an existing purchase item", () => {
      renderForm({
        action: "/purchase_items/42",
        cancelHref: "/purchase_items/42",
        method: "patch",
        submitLabel: "Update Purchase Item",
      });

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/purchase_items/42",
          cancelHref: "/purchase_items/42",
          method: "patch",
          submitLabel: "Update Purchase Item",
        }),
      );
    });
  });

  describe("field sections", () => {
    it("renders linking, dimensions, shipping fields, and media uploader", () => {
      renderForm();

      const imageUploader = screen.getByTestId("image-uploader");
      expect({
        warehouse: formFieldValue("Warehouse"),
        purchase: formFieldValue("Purchase"),
        length: formFieldValue("Length, cm"),
        width: formFieldValue("Width, cm"),
        height: formFieldValue("Height, cm"),
        weight: formFieldValue("Weight, kg"),
        expensesLabel: screen.queryByLabelText("Expenses"),
        expenseField: document.querySelector('[name="purchase_item[expenses]"]'),
        shipping: formFieldValue("Shipping"),
        trackingNumber: formFieldValue("Tracking Number"),
        shipped: formFieldValue("Shipped"),
        shippingCompany: formFieldValue("Shipping Company"),
        mediaFieldNamePrefix: imageUploader.getAttribute("data-field-name-prefix"),
        imageFieldName: imageUploader.getAttribute("data-image-field-name"),
        mediaCount: imageUploader.getAttribute("data-media-count"),
      }).toEqual({
        warehouse: "1",
        purchase: "10",
        length: "30",
        width: "20",
        height: "15",
        weight: "2.5",
        expensesLabel: null,
        expenseField: null,
        shipping: "25.00",
        trackingNumber: "TRK-001",
        shipped: "2026-05-21",
        shippingCompany: "20",
        mediaFieldNamePrefix: "purchase_item[media]",
        imageFieldName: "image",
        mediaCount: "1",
      });
    });

    it("omits the redirect_to_sale_item hidden field when the flag is false", () => {
      const { container } = renderForm({
        purchase_item: makePurchaseItemFormRecord({ redirect_to_sale_item: false }),
      });

      expect(
        container.querySelector('input[name="purchase_item[redirect_to_sale_item]"]'),
      ).toBeNull();
    });

    it("includes the redirect_to_sale_item hidden field when the flag is true", () => {
      const { container } = renderForm({
        purchase_item: makePurchaseItemFormRecord({ redirect_to_sale_item: true }),
      });

      const hiddenInput = container.querySelector(
        'input[name="purchase_item[redirect_to_sale_item]"]',
      );
      expect(hiddenInput).not.toBeNull();
      expect(hiddenInput).toHaveAttribute("value", "1");
    });
  });

  describe("error routing", () => {
    it("shows validation errors on matching fields", () => {
      mockPageProps({ errors: { length: "is not a number", warehouse_id: "must exist" } });

      renderForm();

      expect(screen.getByText("is not a number")).toBeInTheDocument();
      expect(screen.getByText("must exist")).toBeInTheDocument();
    });
  });

  describe("validate", () => {
    it("returns null when tracking number is empty", () => {
      renderForm();
      const { validate } = lastCapturedProps()!;

      const formData = new FormData();
      formData.set("purchase_item[tracking_number]", "");
      formData.set("purchase_item[shipping_company_id]", "");

      expect(validate!(formData)).toBeNull();
    });

    it("returns null when tracking number and shipping company are both present", () => {
      renderForm();
      const { validate } = lastCapturedProps()!;

      const formData = new FormData();
      formData.set("purchase_item[tracking_number]", "TRK-123");
      formData.set("purchase_item[shipping_company_id]", "5");

      expect(validate!(formData)).toBeNull();
    });

    it("returns a shipping_company_id error when tracking number is set but company is missing", () => {
      renderForm();
      const { validate } = lastCapturedProps()!;

      const formData = new FormData();
      formData.set("purchase_item[tracking_number]", "TRK-123");
      formData.set("purchase_item[shipping_company_id]", "");

      expect(validate!(formData)).toEqual({ shipping_company_id: expect.any(String) });
    });
  });
});

function renderForm({
  action = "/purchase_items/42",
  cancelHref = "/purchase_items/42",
  method = "patch",
  options = makePurchaseItemFormOptions(),
  purchase_item = makePurchaseItemFormRecord(),
  submitLabel = "Update Purchase Item",
}: {
  action?: string;
  cancelHref?: string;
  method?: "post" | "patch";
  options?: ReturnType<typeof makePurchaseItemFormOptions>;
  purchase_item?: ReturnType<typeof makePurchaseItemFormRecord>;
  submitLabel?: string;
} = {}) {
  return render(
    <Form
      action={action}
      cancelHref={cancelHref}
      method={method}
      options={options}
      purchase_item={purchase_item}
      submitLabel={submitLabel}
    />,
  );
}

function formFieldValue(label: string) {
  const field = screen.getByLabelText(label);
  if (
    field instanceof HTMLInputElement ||
    field instanceof HTMLSelectElement ||
    field instanceof HTMLTextAreaElement
  ) {
    return field.value;
  }

  throw new Error(`Expected ${label} to be a form field`);
}
