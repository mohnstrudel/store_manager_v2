import { act, fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { SaleItemFormRecord } from "../types";
import SaleItemFields from "./Form/SaleItemFields";
// oxlint-disable-next-line import/no-unassigned-import
import "@/components/SmartSelect";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));
vi.mock("@/components/VariantAssignmentSelect", () => ({
  default: ({
    error,
    name,
    onChange,
    productId,
    value,
  }: {
    error?: string;
    name: string;
    onChange: (value: number | null) => void;
    productId: number | null;
    value: number | null;
  }) => (
    <div>
      <input
        data-product-id={productId ?? ""}
        data-testid="variant-assignment-select"
        name={name}
        readOnly
        value={value ?? ""}
      />
      {error && <p>{error}</p>}
      <button onClick={() => onChange(22)} type="button">
        Choose Variant
      </button>
    </div>
  ),
}));

const productOptions = [
  { value: 1, label: "Moon Statue" },
  { value: 2, label: "Sun Lamp" },
];

function makeSaleItem(
  overrides: Partial<SaleItemFormRecord & { clientKey: string }> = {},
): SaleItemFormRecord & { clientKey: string } {
  return {
    _destroy: false,
    clientKey: "sale-item-1",
    id: null,
    price: "",
    product_id: null,
    qty: "",
    variant_availability: null,
    variant_id: null,
    ...overrides,
  };
}

async function renderSaleItem(
  saleItem: SaleItemFormRecord & { clientKey: string },
  errors: Record<string, string> = {},
) {
  const onRemove = vi.fn<(clientKey: string) => void>();
  const result = render(
    <SaleItemFields
      errors={errors}
      index={0}
      onRemove={onRemove}
      productOptions={productOptions}
      saleItem={saleItem}
    />,
  );
  await act(async () => {});
  return { ...result, onRemove };
}

describe("SaleItemFields", () => {
  it("renders a new sale item with cancel controls and Rails destroy bridge", async () => {
    const { onRemove } = await renderSaleItem(makeSaleItem());

    expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("New product");
    expect(document.querySelector('input[name="sale_items[0][_destroy]"]')).toHaveValue("0");

    fireEvent.click(screen.getByRole("button", { name: "Cancel" }));

    expect(onRemove).toHaveBeenCalledWith("sale-item-1");
  });

  it("renders an existing sale item with id and destroy checkbox", async () => {
    await renderSaleItem(
      makeSaleItem({ id: 10, product_id: 1, variant_id: 11, qty: "2", price: "19.99" }),
    );

    expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("Moon Statue");
    expect(document.querySelector('input[name="sale_items[0][id]"]')).toHaveValue("10");
    expect(screen.getByLabelText("Mark for deletion")).toBeInTheDocument();
    expect(document.querySelector('input[name="sale_items[0][qty]"]')).toHaveValue(2);
    expect(document.querySelector('input[name="sale_items[0][price]"]')).toHaveValue(19.99);
    expect(document.querySelector('input[name="sale_items[0][variant_id]"]')).toHaveValue("11");
  });

  it("updates the displayed title when a product is selected", async () => {
    await renderSaleItem(makeSaleItem());

    fireEvent.change(screen.getByRole("combobox"), { target: { value: "2" } });

    expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("Sun Lamp");
    expect(screen.getByTestId("variant-assignment-select")).toHaveValue("");
    expect(screen.getByTestId("variant-assignment-select")).toHaveAttribute("data-product-id", "2");
  });

  it("shows the backend Variant error on its Sale item row", async () => {
    await renderSaleItem(makeSaleItem({ product_id: 1 }), {
      "sale_items.0.variant": "must be selected",
    });

    expect(screen.getByText("must be selected")).toBeInTheDocument();
  });
});
