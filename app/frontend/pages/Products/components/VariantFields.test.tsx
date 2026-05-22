import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import VariantFields from "./VariantFields";
import { type VariantFormData } from "../types";

type MockOption = {
  value: number;
  label: string;
};

type SmartSelectMockProps = {
  defaultValue: MockOption | null;
  isClearable?: boolean;
  name: string;
  options: MockOption[];
};

vi.mock("@/components/SmartSelect", () => ({
  default: ({ defaultValue, name, options, isClearable = false }: SmartSelectMockProps) => (
    <>
      <input name={name} type="hidden" value={defaultValue?.value ?? ""} />
      <select defaultValue={defaultValue != null ? String(defaultValue.value) : ""}>
        {isClearable && <option value="">—</option>}
        {options.map((o) => (
          <option key={o.value} value={String(o.value)}>
            {o.label}
          </option>
        ))}
      </select>
    </>
  ),
}));

const sizes = [{ value: 1, label: "Large" }];
const versions = [{ value: 10, label: "Deluxe" }];
const colors = [{ value: 100, label: "Red" }];

function makeVariant(overrides: Partial<VariantFormData> = {}): VariantFormData {
  return {
    id: null,
    sku: "",
    size_id: null,
    version_id: null,
    color_id: null,
    purchase_cost: "0",
    selling_price: "0",
    weight: "0",
    deactivated: false,
    has_sales_or_purchases: false,
    _destroy: false,
    ...overrides,
  };
}

function renderVariant(variant: VariantFormData, props: Record<string, unknown> = {}) {
  const onRemove = vi.fn();
  const result = render(
    <VariantFields
      colors={colors}
      index={0}
      onRemove={onRemove}
      sizes={sizes}
      variant={variant}
      versions={versions}
      {...props}
    />,
  );
  return { ...result, onRemove };
}

describe("VariantFields", () => {
  describe("title", () => {
    it("shows 'Base Model' when no options are selected", () => {
      renderVariant(makeVariant());
      expect(screen.getByRole("heading", { level: 6 })).toHaveTextContent("Base Model");
    });

    it("shows combined title from selected options", () => {
      renderVariant(makeVariant({ size_id: 1, version_id: 10, color_id: 100 }));
      expect(screen.getByRole("heading", { level: 6 })).toHaveTextContent("Large | Deluxe | Red");
    });

    it("shows only size when other options are not selected", () => {
      renderVariant(makeVariant({ size_id: 1 }));
      expect(screen.getByRole("heading", { level: 6 })).toHaveTextContent("Large");
    });

    it("shows size and color when version is not selected", () => {
      renderVariant(makeVariant({ size_id: 1, color_id: 100 }));
      expect(screen.getByRole("heading", { level: 6 })).toHaveTextContent("Large | Red");
    });
  });

  describe("controls", () => {
    it("shows Remove button for new variants and calls onRemove on click", () => {
      const { onRemove } = renderVariant(makeVariant());
      fireEvent.click(screen.getByRole("button", { name: "Remove" }));
      expect(onRemove).toHaveBeenCalledWith(0);
    });

    it("shows Destroy? checkbox for existing variant without sales or purchases", () => {
      renderVariant(makeVariant({ id: 1 }));
      expect(screen.getByLabelText("Destroy?")).toBeInTheDocument();
      expect(screen.queryByLabelText("Deactivate?")).not.toBeInTheDocument();
    });

    it("renders Rails-style destroy inputs for existing variants", () => {
      renderVariant(makeVariant({ id: 1 }));
      const checkbox = screen.getByLabelText("Destroy?");

      expect(
        document.querySelector('input[name="variants[0][_destroy]"][type="hidden"]'),
      ).toHaveValue("0");
      expect(checkbox).toHaveAttribute("name", "variants[0][_destroy]");
      expect(checkbox).toHaveAttribute("value", "1");
    });

    it("shows Deactivate? for existing variant with sales or purchases", () => {
      renderVariant(makeVariant({ id: 1, has_sales_or_purchases: true }));
      expect(screen.getByLabelText("Deactivate?")).toBeInTheDocument();
      expect(screen.queryByLabelText("Destroy?")).not.toBeInTheDocument();
    });

    it("shows (Deactivated) and no action controls when deactivated", () => {
      renderVariant(makeVariant({ id: 1, deactivated: true }));
      expect(screen.getByText("(Deactivated)")).toBeInTheDocument();
      expect(screen.queryByRole("button", { name: "Remove" })).not.toBeInTheDocument();
      expect(screen.queryByLabelText("Destroy?")).not.toBeInTheDocument();
      expect(screen.queryByLabelText("Deactivate?")).not.toBeInTheDocument();
    });

    it("applies opacity-50 class when deactivated", () => {
      const { container } = renderVariant(makeVariant({ id: 1, deactivated: true }));
      expect(container.firstChild).toHaveClass("opacity-50");
    });
  });

  describe("errors", () => {
    it("shows SKU error when errors include 'sku'", () => {
      renderVariant(makeVariant(), { errors: { "variants.0.sku": "has already been taken" } });
      expect(screen.getByText("has already been taken")).toBeInTheDocument();
    });

    it("shows combination error under the Size field", () => {
      renderVariant(makeVariant(), { errors: { "variants.0.base": "Combination already exists" } });
      expect(screen.getByText("Combination already exists")).toBeInTheDocument();
    });
  });

  describe("native fields", () => {
    it("renders uncontrolled inputs and react-select hidden fields with names", () => {
      renderVariant(makeVariant({ sku: "SKU-1", size_id: 1, version_id: 10, color_id: 100 }));

      expect(document.querySelector('input[name="variants[0][sku]"]')).toHaveValue("SKU-1");
      expect(document.querySelector('input[name="variants[0][size_id]"]')).toHaveValue("1");
      expect(document.querySelector('input[name="variants[0][version_id]"]')).toHaveValue("10");
      expect(document.querySelector('input[name="variants[0][color_id]"]')).toHaveValue("100");
    });
  });
});
