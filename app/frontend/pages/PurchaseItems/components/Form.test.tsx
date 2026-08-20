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

      expect(screen.getByLabelText("Warehouse")).toHaveValue("1");
      expect(screen.getByLabelText("Purchase")).toHaveValue("10");
      expect(screen.getByLabelText("Length, cm")).toHaveValue("30");
      expect(screen.getByLabelText("Width, cm")).toHaveValue("20");
      expect(screen.getByLabelText("Height, cm")).toHaveValue("15");
      expect(screen.getByLabelText("Weight, kg")).toHaveValue("2.5");
      expect(screen.queryByLabelText("Expenses")).not.toBeInTheDocument();
      expect(document.querySelector('[name="purchase_item[expenses]"]')).toBeNull();
      expect(screen.getByLabelText("Shipping")).toHaveValue("25.00");
      expect(screen.getByLabelText("Tracking Number")).toHaveValue("TRK-001");
      expect(screen.getByLabelText("Shipping Company")).toHaveValue("20");
      expect(screen.getByTestId("image-uploader")).toHaveAttribute(
        "data-field-name-prefix",
        "purchase_item[media]",
      );
      expect(screen.getByTestId("image-uploader")).toHaveAttribute(
        "data-image-field-name",
        "image",
      );
      expect(screen.getByTestId("image-uploader")).toHaveAttribute("data-media-count", "1");
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
