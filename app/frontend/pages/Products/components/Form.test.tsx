import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Form from "./Form";
import {
  type FormOptions,
  type ProductFormRecord,
  type PurchaseFormData,
  type SelectOption,
  type StoreInfoFormData,
  type VariantFormData,
} from "../types";

type SmartSelectMockProps = {
  defaultValue?: SelectOption | SelectOption[] | null;
  inputId?: string;
  isMulti?: boolean;
  name?: string;
  options?: SelectOption[];
};

let pageErrors: Record<string, string> = {};
let resourceFormProps: {
  action: string;
  cancelHref: string;
  method: string;
  submitLabel: string;
} | null = null;

vi.mock("@inertiajs/react", () => ({
  Form: ({
    action,
    children,
    method,
  }: {
    action: string;
    children: ReactNode | ((props: { errors: Record<string, string> }) => ReactNode);
    method: string;
  }) => (
    <form action={action} data-method={method}>
      {typeof children === "function" ? children({ errors: pageErrors }) : children}
    </form>
  ),
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
    children: ReactNode | ((props: { errors: Record<string, string> }) => ReactNode);
    method: string;
    submitLabel: string;
  }) => {
    resourceFormProps = { action, cancelHref, method, submitLabel };

    return (
      <form data-testid="resource-form">
        {typeof children === "function" ? children({ errors: pageErrors }) : children}
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

vi.mock("./TiptapEditor", () => ({
  default: ({ defaultValue, name }: { defaultValue: string; name: string }) => (
    <>
      <input data-testid="description-input" name={name} type="hidden" value={defaultValue} />
      <textarea data-testid="description-editor" defaultValue={defaultValue} />
    </>
  ),
}));

vi.mock("./VariantFields", () => ({
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

vi.mock("./StoreInfoFields", () => ({
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

vi.mock("./PurchaseFields", () => ({
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

vi.mock("./ImageUploader", () => ({
  default: () => <div data-testid="image-uploader" />,
}));

const options: FormOptions = {
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

function makeStoreInfo(overrides: Partial<StoreInfoFormData> = {}): StoreInfoFormData {
  return {
    id: null,
    store_name: "",
    tag_list: "",
    _destroy: false,
    ...overrides,
  };
}

function makeProduct(overrides: Partial<ProductFormRecord> = {}): ProductFormRecord {
  return {
    id: null,
    title: "Test Product",
    description_html: "<p>Product description</p>",
    franchise_id: null,
    shape: "Bust",
    brand_ids: [],
    path: "/products",
    variants: [makeVariant()],
    store_infos: [],
    media: [],
    ...overrides,
  };
}

function makePurchase(overrides: Partial<PurchaseFormData> = {}): PurchaseFormData {
  return {
    supplier_id: null,
    order_reference: "",
    item_price: "",
    amount: "",
    warehouse_id: null,
    payment_value: "",
    ...overrides,
  };
}

describe("Products/Components/Form", () => {
  beforeEach(() => {
    pageErrors = {};
    resourceFormProps = null;
  });

  it("renders the shell with nested errors and hidden form fields", () => {
    pageErrors = {
      franchise: "Franchise must exist",
      "variants.0.sku": "has already been taken",
      "purchase.0.item_price": "can't be blank",
    };

    render(
      <Form
        isNew
        options={options}
        product={makeProduct({
          store_infos: [makeStoreInfo({ id: 1, store_name: "shopify", tag_list: "featured" })],
        })}
        purchase={makePurchase()}
        submitLabel="Create Product"
      />,
    );

    expect(resourceFormProps).toEqual({
      action: "/products",
      cancelHref: "/products",
      method: "post",
      submitLabel: "Create Product",
    });
    expect(screen.getByTestId("resource-form")).toBeInTheDocument();
    expect(screen.getByTestId("description-editor")).toBeInTheDocument();
    expect(screen.getByDisplayValue("Bust")).toHaveAttribute("name", "product[shape]");
    expect(screen.getByTestId("description-input")).toHaveAttribute("name", "product[description]");
    expect(document.querySelector('input[name="product[brand_ids][]"]')).toHaveValue("");
    expect(screen.getByTestId("product_franchise_id").parentElement).toHaveClass(
      "field_with_errors",
    );
    expect(screen.getByText("Franchise must exist")).toBeInTheDocument();
    expect(screen.getByText("has already been taken")).toBeInTheDocument();
    expect(screen.getByText("can't be blank")).toBeInTheDocument();
    expect(screen.getByTestId("purchase-fields")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Add Purchase" })).not.toBeInTheDocument();
    expect(screen.getAllByTestId("variant-row")).toHaveLength(1);
    expect(screen.getAllByTestId("store-info-row")).toHaveLength(1);
    expect(screen.getByTestId("image-uploader")).toBeInTheDocument();
  });

  it("adds a variant row when Add Variant is clicked", async () => {
    const user = userEvent.setup();

    render(
      <Form
        isNew
        options={options}
        product={makeProduct()}
        purchase={makePurchase()}
        submitLabel="Create Product"
      />,
    );

    expect(screen.getAllByTestId("variant-row")).toHaveLength(1);

    await user.click(screen.getByRole("button", { name: "Add Variant" }));

    expect(screen.getAllByTestId("variant-row")).toHaveLength(2);
  });

  it("reveals the purchase section when Add Purchase is clicked", async () => {
    const user = userEvent.setup();

    render(
      <Form
        isNew
        options={options}
        product={makeProduct()}
        purchase={makePurchase()}
        submitLabel="Create Product"
      />,
    );

    expect(screen.getByRole("button", { name: "Add Purchase" })).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "Add Purchase" }));

    expect(screen.getByTestId("purchase-fields")).toBeInTheDocument();
  });
});
