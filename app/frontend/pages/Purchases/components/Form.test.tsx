import { act, fireEvent, render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";

import { makePurchaseForm, makePurchaseFormOptions } from "../test/factories";
import Form from "./Form";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

vi.mock("@/components/FormSmartSelect", () => ({
  default: ({
    error,
    inputId,
    label,
    onChange,
    options = [],
    value,
  }: {
    error?: string;
    inputId: string;
    label: string;
    onChange?: (option: { value: number; label: string } | null) => void;
    options?: Array<{ value: number; label: string }>;
    value?: { value: number; label: string } | null;
  }) => (
    <div className={error ? "field_with_errors" : ""}>
      <label htmlFor={inputId}>{label}</label>
      <select
        id={inputId}
        onChange={(event) => {
          const option =
            options.find((candidate) => String(candidate.value) === event.target.value) ?? null;
          onChange?.(option);
        }}
        value={value?.value ?? ""}
      >
        <option value="">—</option>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {error && <p>{error}</p>}
    </div>
  ),
}));

vi.mock("@/components/VariantAssignmentSelect", () => ({
  default: ({ productId, value }: { productId: number | null; value: number | null }) => (
    <div data-product-id={productId ?? ""} data-testid="variant-assignment-select">
      {value ?? ""}
    </div>
  ),
}));

describe("Purchases/components/Form", () => {
  beforeEach(() => {
    mockPageProps({});
  });

  describe("form shell", () => {
    it("configures action, method, and labels for a new purchase", () => {
      renderForm({ isNew: true, submitLabel: "Create Purchase" });

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/purchases",
          cancelHref: "/purchases",
          method: "post",
          submitLabel: "Create Purchase",
        }),
      );
      expect(screen.getByRole("button", { name: "Create Purchase" })).toBeInTheDocument();
    });

    it("configures action, method, and labels for an existing purchase", () => {
      renderForm({
        isNew: false,
        purchase: makePurchaseForm({ id: 5, path: "/purchases/5" }),
        submitLabel: "Update Purchase",
      });

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/purchases/5",
          cancelHref: "/purchases",
          method: "patch",
          submitLabel: "Update Purchase",
        }),
      );
    });
  });

  describe("error routing", () => {
    it("shows server-side supplier error", () => {
      mockPageProps({ errors: { supplier_id: "Supplier must exist" } });

      renderForm();

      expect(screen.getByText("Supplier must exist")).toBeInTheDocument();
    });

    it("shows server-side product error", () => {
      mockPageProps({ errors: { product_id: "Product must exist" } });

      renderForm();

      expect(screen.getByText("Product must exist")).toBeInTheDocument();
    });
  });

  describe("field sections", () => {
    it("hides the payment field on edit", () => {
      renderForm({
        isNew: false,
        purchase: makePurchaseForm({ path: "/purchases/5" }),
        submitLabel: "Update Purchase",
      });

      expect(screen.queryByLabelText("What did you pay in total?")).not.toBeInTheDocument();
    });

    it("clears the old Variant when the Product changes", async () => {
      await act(async () => {
        renderForm({
          options: makePurchaseFormOptions({
            products: [
              { value: 1, label: "Moon Statue" },
              { value: 2, label: "Sun Lamp" },
            ],
          }),
          purchase: makePurchaseForm({
            product_id: 1,
            variant_id: 11,
          }),
        });
      });

      expect(screen.getByTestId("variant-assignment-select")).toHaveTextContent("11");

      fireEvent.change(screen.getByRole("combobox", { name: "Product" }), {
        target: { value: "2" },
      });

      expect(screen.getByTestId("variant-assignment-select")).toHaveTextContent("");
      expect(screen.getByTestId("variant-assignment-select")).toHaveAttribute(
        "data-product-id",
        "2",
      );
    });
  });
});

function renderForm({
  isNew = true,
  options = makePurchaseFormOptions(),
  purchase = makePurchaseForm(),
  submitLabel = "Create Purchase",
}: {
  isNew?: boolean;
  options?: ReturnType<typeof makePurchaseFormOptions>;
  purchase?: ReturnType<typeof makePurchaseForm>;
  submitLabel?: string;
} = {}) {
  return render(
    <Form isNew={isNew} options={options} purchase={purchase} submitLabel={submitLabel} />,
  );
}
