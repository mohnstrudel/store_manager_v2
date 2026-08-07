import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import VariantFields from "./VariantFields";
import { makeVariantForm } from "../../test/factories";
import type { VariantFormData } from "../../types";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

const sizes = [{ value: 1, label: "Large" }];
const versions = [{ value: 10, label: "Deluxe" }];
const colors = [{ value: 100, label: "Red" }];

describe("Products/components/Form/VariantFields", () => {
  describe("title", () => {
    it("shows 'Base Model' when no options are selected", () => {
      renderVariant(makeVariantForm({ size_id: null, version_id: null, color_id: null }));

      expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("Base Model");
    });

    it("shows combined title from selected options", () => {
      renderVariant(makeVariantForm({ size_id: 1, version_id: 10, color_id: 100 }));

      expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("Large | Deluxe | Red");
    });

    it("shows only size when other options are not selected", () => {
      renderVariant(makeVariantForm({ size_id: 1, version_id: null, color_id: null }));

      expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("Large");
    });

    it("shows size and color when version is not selected", () => {
      renderVariant(makeVariantForm({ size_id: 1, version_id: null, color_id: 100 }));

      expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("Large | Red");
    });
  });

  describe("controls", () => {
    it("shows Cancel button for new variants and calls onRemove on click", async () => {
      const user = userEvent.setup();
      const { onRemove } = renderVariant(makeVariantForm({ id: null }));

      await user.click(screen.getByRole("button", { name: "Cancel" }));

      expect(onRemove).toHaveBeenCalled();
    });

    it("shows Mark for deletion checkbox for existing variant without sales or purchases", () => {
      renderVariant(makeVariantForm({ id: 1 }));

      expect(screen.getByLabelText("Mark for deletion")).toBeInTheDocument();
    });

    it("renders Rails-style destroy inputs with the red checkbox styling", () => {
      renderVariant(makeVariantForm({ id: 1 }));

      const checkbox = screen.getByLabelText("Mark for deletion");

      expect(
        document.querySelector('input[name="variants[0][_destroy]"][type="hidden"]'),
      ).toHaveValue("0");
      expect(checkbox).toHaveAttribute("name", "variants[0][_destroy]");
      expect(checkbox).toHaveAttribute("value", "1");
      expect(checkbox).toHaveClass("red");
      expect(checkbox).not.toHaveClass("w-4");
      expect(checkbox).not.toHaveClass("h-4");
    });

    it("keeps the same delete checkbox for existing variants with sales or purchases", () => {
      renderVariant(makeVariantForm({ id: 1, has_sales_or_purchases: true }));

      expect(screen.getByLabelText("Mark for deletion")).toBeInTheDocument();
    });

    it("shows (Deactivated) and no action controls when deactivated", () => {
      renderVariant(makeVariantForm({ id: 1, deactivated: true }));

      expect(screen.getByText("(Deactivated)")).toBeInTheDocument();
      expect(screen.queryByRole("button", { name: "Cancel" })).not.toBeInTheDocument();
      expect(screen.queryByLabelText("Mark for deletion")).not.toBeInTheDocument();
    });

    it("applies opacity-50 class when deactivated", () => {
      const { container } = renderVariant(makeVariantForm({ id: 1, deactivated: true }));

      expect(container.firstChild).toHaveClass("opacity-50");
    });

    it("applies opacity-50 class when marked for deletion", async () => {
      const user = userEvent.setup();
      const { container } = renderVariant(makeVariantForm({ id: 1 }));

      await user.click(screen.getByLabelText("Mark for deletion"));

      expect(container.firstChild).toHaveClass("opacity-50");
    });
  });

  describe("errors", () => {
    it("shows SKU error when errors include 'sku'", () => {
      renderVariant(makeVariantForm(), {
        errors: { "variants.0.sku": "has already been taken" },
      });

      expect(screen.getByText("has already been taken")).toBeInTheDocument();
    });

    it("shows combination error under the Size field", () => {
      renderVariant(makeVariantForm(), {
        errors: { "variants.0.base": "Combination already exists" },
      });

      expect(screen.getByText("Combination already exists")).toBeInTheDocument();
    });
  });

  describe("native fields", () => {
    it("renders uncontrolled inputs and react-select hidden fields with names", () => {
      renderVariant(
        makeVariantForm({
          sku: "SKU-1",
          size_id: 1,
          version_id: 10,
          color_id: 100,
        }),
      );

      expect(document.querySelector('input[name="variants[0][sku]"]')).toHaveValue("SKU-1");
      expect(document.querySelector('input[name="variants[0][size_id]"]')).toHaveValue("1");
      expect(document.querySelector('input[name="variants[0][version_id]"]')).toHaveValue("10");
      expect(document.querySelector('input[name="variants[0][color_id]"]')).toHaveValue("100");
    });

    it("submits its stable draft client key", () => {
      renderVariant(makeVariantForm());

      expect(document.querySelector('input[name="variants[0][client_key]"]')).toHaveValue(
        "draft-variant-1",
      );
    });

    it("reports option changes against the same draft client key", async () => {
      const { onChange } = renderVariant(makeVariantForm());

      fireEvent.change(screen.getByLabelText("Size"), { target: { value: "1" } });

      expect(onChange).toHaveBeenCalledWith("draft-variant-1", { size_id: 1 });
    });
  });
});

function renderVariant(
  variant: ReturnType<typeof makeVariantForm>,
  props: Record<string, unknown> = {},
) {
  const onRemove = vi.fn<(clientKey: string) => void>();
  const onChange = vi.fn<(clientKey: string, changes: Partial<VariantFormData>) => void>();
  const result = render(
    <VariantFields
      colors={colors}
      index={0}
      onChange={onChange}
      onRemove={onRemove}
      sizes={sizes}
      variant={{ ...variant, clientKey: "draft-variant-1" }}
      versions={versions}
      {...props}
    />,
  );
  return { ...result, onChange, onRemove };
}
