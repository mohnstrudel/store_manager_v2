import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { usePage } from "@inertiajs/react";
import { mockPageProps } from "@/test/mocks/inertia";
import Form from "./Form";
import {
  makeProductForm,
  makePurchaseForm,
  makeStoreInfoForm,
  makeVariantForm,
} from "../test/factories";
import type { PurchaseFormData, SelectOption, StoreInfoFormData, VariantFormData } from "../types";

type SmartSelectMockProps = {
  defaultValue?: SelectOption | SelectOption[] | null;
  inputId?: string;
  isMulti?: boolean;
  name?: string;
  options?: SelectOption[];
};

let resourceFormProps: {
  action: string;
  cancelHref: string;
  method: string;
  submitLabel: string;
} | null = null;

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

vi.mock("@/components/ResourceForm", () => ({
  default: function ResourceFormStub({
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
  }) {
    const errors = (usePage().props.errors ?? {}) as Record<string, string>;
    resourceFormProps = { action, cancelHref, method, submitLabel };

    return (
      <form data-testid="resource-form">
        {typeof children === "function" ? children({ errors }) : children}
        <button type="submit">{submitLabel}</button>
      </form>
    );
  },
}));

vi.mock("@/components/SmartSelect", () => ({
  default: ({
    defaultValue = null,
    inputId,
    isMulti = false,
    name,
    options = [],
  }: SmartSelectMockProps) => {
    const selectedValues = Array.isArray(defaultValue)
      ? defaultValue.map((option) => String(option.value))
      : defaultValue
        ? [String(defaultValue.value)]
        : [];
    const hiddenInputs = !name ? null : isMulti ? (
      selectedValues.length > 0 ? (
        selectedValues.map((selectedValue) => (
          <input key={selectedValue} name={name} type="hidden" value={selectedValue} />
        ))
      ) : (
        <input name={name} type="hidden" value="" />
      )
    ) : (
      <input name={name} type="hidden" value={selectedValues[0] ?? ""} />
    );

    return (
      <>
        {hiddenInputs}
        <select
          data-testid={inputId ?? name}
          defaultValue={isMulti ? selectedValues : (selectedValues[0] ?? "")}
          multiple={isMulti}
        >
          {!isMulti && <option value="">—</option>}
          {options.map((option) => (
            <option key={String(option.value)} value={String(option.value)}>
              {option.label}
            </option>
          ))}
        </select>
      </>
    );
  },
}));

vi.mock("./Form/TiptapEditor", () => ({
  default: ({ defaultValue, name }: { defaultValue: string; name: string }) => (
    <>
      <input data-testid="description-input" name={name} type="hidden" value={defaultValue} />
      <textarea data-testid="description-editor" defaultValue={defaultValue} />
    </>
  ),
}));

vi.mock("./Form/VariantFields", () => ({
  default: ({
    errors = {},
    index,
    onRemove,
    variant,
  }: {
    errors?: Record<string, string>;
    index: number;
    onRemove: (index: number) => void;
    variant: VariantFormData;
  }) => (
    <div data-testid="variant-row">
      <p>{variant.sku || `Variant ${index + 1}`}</p>
      <input name={`variants[${index}][sku]`} defaultValue={variant.sku} />
      {errors[`variants.${index}.sku`] && <p>{errors[`variants.${index}.sku`]}</p>}
      {errors[`variants.${index}.base`] && <p>{errors[`variants.${index}.base`]}</p>}
      {!variant.id && (
        <button type="button" onClick={() => onRemove(index)}>
          Remove
        </button>
      )}
    </div>
  ),
}));

vi.mock("./Form/StoreInfoFields", () => ({
  default: ({
    errors = {},
    index,
    onRemove,
    storeInfo,
  }: {
    errors?: Record<string, string>;
    index: number;
    onRemove: (index: number) => void;
    storeInfo: StoreInfoFormData;
  }) => (
    <div data-testid="store-info-row">
      <p>{storeInfo.store_name || `Store info ${index + 1}`}</p>
      <input name={`store_infos[${index}][store_name]`} defaultValue={storeInfo.store_name} />
      {errors[`store_infos.${index}.store_name`] && (
        <p>{errors[`store_infos.${index}.store_name`]}</p>
      )}
      {!storeInfo.id && (
        <button type="button" onClick={() => onRemove(index)}>
          Remove
        </button>
      )}
    </div>
  ),
}));

vi.mock("./Form/PurchaseFields", () => ({
  default: ({
    errors = {},
    purchase,
  }: {
    errors?: Record<string, string>;
    purchase: PurchaseFormData;
  }) => (
    <div data-testid="purchase-fields">
      <input name="purchase[item_price]" defaultValue={purchase.item_price} />
      {errors["purchase.0.item_price"] && <p>{errors["purchase.0.item_price"]}</p>}
      {errors["purchase.0.base"] && <p>{errors["purchase.0.base"]}</p>}
    </div>
  ),
}));

vi.mock("@/components/ImageUploader", () => ({
  default: () => <div data-testid="image-uploader" />,
}));

const options = {
  franchises: [{ value: 1, label: "Franchise" }],
  brands: [{ value: 2, label: "Featured Brand" }],
  shapes: ["Bust"],
  sizes: [{ value: 10, label: "Large" }],
  versions: [{ value: 20, label: "Deluxe" }],
  colors: [{ value: 30, label: "Red" }],
  suppliers: [{ value: 40, label: "Moon Supply" }],
  warehouses: [{ value: 50, label: "Main Warehouse" }],
  store_names: ["shopify", "woo"],
};

describe("Products/components/Form", () => {
  beforeEach(() => {
    resourceFormProps = null;
  });

  describe("form shell", () => {
    it("configures action, method, and labels for a new product", () => {
      renderForm({ isNew: true, submitLabel: "Create Product" });

      expect(resourceFormProps).toEqual({
        action: "/products",
        cancelHref: "/products",
        method: "post",
        submitLabel: "Create Product",
      });
    });

    it("configures action, method, and labels for an existing product", () => {
      renderForm({
        isNew: false,
        product: makeProductForm({ id: 1, path: "/products/1" }),
        submitLabel: "Update Product",
      });

      expect(resourceFormProps).toEqual({
        action: "/products/1",
        cancelHref: "/products/1",
        method: "patch",
        submitLabel: "Update Product",
      });
    });
  });

  describe("field sections", () => {
    it("renders the description editor, shape select, and image uploader", async () => {
      await act(async () => {
        renderForm();
      });

      expect(screen.getByTestId("description-editor")).toBeInTheDocument();
      expect(screen.getByDisplayValue("Bust")).toHaveAttribute("name", "product[shape]");
      expect(screen.getByTestId("image-uploader")).toBeInTheDocument();
    });

    it("renders existing variant and store info rows", () => {
      renderForm({
        product: makeProductForm({
          variants: [makeVariantForm()],
          store_infos: [makeStoreInfoForm({ id: 1, store_name: "shopify", tag_list: "featured" })],
        }),
      });

      expect(screen.getAllByTestId("variant-row")).toHaveLength(1);
      expect(screen.getAllByTestId("store-info-row")).toHaveLength(1);
    });

    it("adds a variant row when Add Variant is clicked", async () => {
      const user = userEvent.setup();
      renderForm();

      await user.click(screen.getByRole("button", { name: "Add Variant" }));

      expect(screen.getAllByTestId("variant-row")).toHaveLength(2);
    });
  });

  describe("error routing", () => {
    it("routes franchise, variant, and purchase errors to their fields", () => {
      mockPageProps({
        errors: {
          franchise: "Franchise must exist",
          "variants.0.sku": "has already been taken",
          "purchase.0.item_price": "can't be blank",
        },
      });

      renderForm({
        product: makeProductForm({
          store_infos: [makeStoreInfoForm({ id: 1, store_name: "shopify", tag_list: "featured" })],
        }),
      });

      expect(screen.getByTestId("product_franchise_id").parentElement).toHaveClass(
        "field_with_errors",
      );
      expect(screen.getByText("Franchise must exist")).toBeInTheDocument();
      expect(screen.getByText("has already been taken")).toBeInTheDocument();
      expect(screen.getByText("can't be blank")).toBeInTheDocument();
    });
  });

  describe("initial purchase section", () => {
    it("hides purchase fields and shows Add Purchase button initially", () => {
      renderForm({ isNew: true });

      expect(screen.queryByTestId("purchase-fields")).not.toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Add Purchase" })).toBeInTheDocument();
    });

    it("reveals purchase fields when Add Purchase is clicked", async () => {
      const user = userEvent.setup();
      renderForm({ isNew: true });

      await user.click(screen.getByRole("button", { name: "Add Purchase" }));

      expect(screen.getByTestId("purchase-fields")).toBeInTheDocument();
    });
  });
});

function renderForm({
  isNew = true,
  product = makeProductForm(),
  purchase = makePurchaseForm(),
  submitLabel = "Create Product",
}: {
  isNew?: boolean;
  product?: ReturnType<typeof makeProductForm>;
  purchase?: ReturnType<typeof makePurchaseForm>;
  submitLabel?: string;
} = {}) {
  return render(
    <Form
      isNew={isNew}
      options={options}
      product={product}
      purchase={purchase}
      submitLabel={submitLabel}
    />,
  );
}
