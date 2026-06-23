import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";
import Form from "./Form";
import {
  makeProductForm,
  makePurchaseForm,
  makeStoreInfoForm,
  makeVariantForm,
} from "../test/factories";
import type { PurchaseFormData, StoreInfoFormData, VariantFormData } from "../types";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

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
  describe("form shell", () => {
    it("configures action, method, and labels for a new product", async () => {
      await renderForm({ isNew: true, submitLabel: "Create Product" });

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/products",
          cancelHref: "/products",
          method: "post",
          submitLabel: "Create Product",
        }),
      );
    });

    it("configures action, method, and labels for an existing product", async () => {
      await renderForm({
        isNew: false,
        product: makeProductForm({ id: 1, path: "/products/1" }),
        submitLabel: "Update Product",
      });

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/products/1",
          cancelHref: "/products/1",
          method: "patch",
          submitLabel: "Update Product",
        }),
      );
    });
  });

  describe("field sections", () => {
    it("renders the description editor, shape select, and image uploader", async () => {
      await renderForm();

      expect(screen.getByTestId("description-editor")).toBeInTheDocument();
      expect(screen.getByDisplayValue("Bust")).toHaveAttribute("name", "product[shape]");
      expect(screen.getByTestId("image-uploader")).toBeInTheDocument();
    });

    it("renders existing variant and store info rows", async () => {
      await renderForm({
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
      await renderForm();

      await user.click(screen.getByRole("button", { name: "Add Variant" }));

      expect(screen.getAllByTestId("variant-row")).toHaveLength(2);
    });
  });

  describe("error routing", () => {
    it("routes franchise, variant, and purchase errors to their fields", async () => {
      mockPageProps({
        errors: {
          franchise: "Franchise must exist",
          "variants.0.sku": "has already been taken",
          "purchase.0.item_price": "can't be blank",
        },
      });

      await renderForm({
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
    it("hides purchase fields and shows Add Purchase button initially", async () => {
      await renderForm({ isNew: true });

      expect(screen.queryByTestId("purchase-fields")).not.toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Add Purchase" })).toBeInTheDocument();
    });

    it("reveals purchase fields when Add Purchase is clicked", async () => {
      const user = userEvent.setup();
      await renderForm({ isNew: true });

      await user.click(screen.getByRole("button", { name: "Add Purchase" }));

      expect(screen.getByTestId("purchase-fields")).toBeInTheDocument();
    });
  });
});

async function renderForm({
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
  const result = render(
    <Form
      isNew={isNew}
      options={options}
      product={product}
      purchase={purchase}
      submitLabel={submitLabel}
    />,
  );
  await act(async () => {});
  return result;
}
