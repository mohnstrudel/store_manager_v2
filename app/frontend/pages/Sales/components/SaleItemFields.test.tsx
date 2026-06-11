import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import SaleItemFields from "./Form/SaleItemFields";
import type { SaleItemFormRecord } from "../types";
// oxlint-disable-next-line import/no-unassigned-import
import "@/components/SmartSelect";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

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
    ...overrides,
  };
}

function renderSaleItem(saleItem: SaleItemFormRecord & { clientKey: string }) {
  const onRemove = vi.fn<(clientKey: string) => void>();
  const result = render(
    <SaleItemFields
      index={0}
      onRemove={onRemove}
      productOptions={productOptions}
      saleItem={saleItem}
    />,
  );

  return { ...result, onRemove };
}

describe("SaleItemFields", () => {
  it("renders a new sale item with cancel controls and Rails destroy bridge", () => {
    const { onRemove } = renderSaleItem(makeSaleItem());

    expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("New product");
    expect(document.querySelector('input[name="sale_items[0][_destroy]"]')).toHaveValue("0");

    fireEvent.click(screen.getByRole("button", { name: "Cancel" }));

    expect(onRemove).toHaveBeenCalledWith("sale-item-1");
  });

  it("renders an existing sale item with id and destroy checkbox", () => {
    renderSaleItem(makeSaleItem({ id: 10, product_id: 1, qty: "2", price: "19.99" }));

    expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("Moon Statue");
    expect(document.querySelector('input[name="sale_items[0][id]"]')).toHaveValue("10");
    expect(screen.getByLabelText("Mark for deletion")).toBeInTheDocument();
    expect(document.querySelector('input[name="sale_items[0][qty]"]')).toHaveValue(2);
    expect(document.querySelector('input[name="sale_items[0][price]"]')).toHaveValue(19.99);
  });

  it("updates the displayed title when a product is selected", () => {
    renderSaleItem(makeSaleItem());

    fireEvent.change(screen.getByRole("combobox"), { target: { value: "2" } });

    expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("Sun Lamp");
  });
});
