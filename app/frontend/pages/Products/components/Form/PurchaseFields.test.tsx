import { act, render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { makePurchaseForm } from "../../test/factories";
import PurchaseFields from "./PurchaseFields";
// oxlint-disable-next-line import/no-unassigned-import
import "@/components/SmartSelect";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

const suppliers = [{ value: 1, label: "Moon Supply" }];
const warehouses = [{ value: 10, label: "Main Warehouse" }];
const baseDraftAvailability = {
  mode: "base" as const,
  variants: [{ value: "draft-base", label: "Base Model", base_model: true }],
};

describe("Products/components/Form/PurchaseFields", () => {
  it("renders named hidden inputs for supplier_id and warehouse_id selects", async () => {
    await act(async () => {
      render(
        <PurchaseFields
          draftAvailability={baseDraftAvailability}
          onVariantChange={vi.fn<(clientKey: string | null) => void>()}
          purchase={makePurchaseForm({ supplier_id: 1, warehouse_id: 10 })}
          suppliers={suppliers}
          variantClientKey="draft-base"
          warehouses={warehouses}
        />,
      );
    });

    expect(screen.getAllByRole("combobox")).toHaveLength(2);
    expect(document.querySelector('input[name="purchase[supplier_id]"]')).toHaveValue("1");
    expect(document.querySelector('input[name="purchase[warehouse_id]"]')).toHaveValue("10");
  });

  it("renders ordinary purchase fields as uncontrolled named inputs", () => {
    render(
      <PurchaseFields
        draftAvailability={baseDraftAvailability}
        onVariantChange={vi.fn<(clientKey: string | null) => void>()}
        purchase={makePurchaseForm({
          order_reference: "PO-1",
          item_price: "12.50",
          amount: "2",
          payment_value: "25",
        })}
        suppliers={suppliers}
        variantClientKey="draft-base"
        warehouses={warehouses}
      />,
    );

    expect(document.querySelector('input[name="purchase[order_reference]"]')).toHaveValue("PO-1");
    expect(document.querySelector('input[name="purchase[item_price]"]')).toHaveValue("12.50");
    expect(document.querySelector('input[name="purchase[amount]"]')).toHaveValue("2");
    expect(document.querySelector('input[name="purchase[payment_value]"]')).toHaveValue(25);
  });

  it("does not render the warehouse select when there are no warehouses", () => {
    render(
      <PurchaseFields
        draftAvailability={baseDraftAvailability}
        onVariantChange={vi.fn<(clientKey: string | null) => void>()}
        purchase={makePurchaseForm()}
        suppliers={suppliers}
        variantClientKey="draft-base"
        warehouses={[]}
      />,
    );

    expect(screen.getAllByRole("combobox")).toHaveLength(1);
  });

  it("submits the fixed draft Base client key", () => {
    render(
      <PurchaseFields
        draftAvailability={{
          mode: "base",
          variants: [{ value: "draft-base", label: "Base Model", base_model: true }],
        }}
        onVariantChange={vi.fn<(clientKey: string | null) => void>()}
        purchase={makePurchaseForm({ variant_client_key: "draft-base" })}
        suppliers={suppliers}
        variantClientKey="draft-base"
        warehouses={warehouses}
      />,
    );

    expect(screen.getByText("Base Model")).toBeInTheDocument();
    expect(document.querySelector('input[name="purchase[variant_client_key]"]')).toHaveValue(
      "draft-base",
    );
  });

  it("does not select the first draft real Variant", () => {
    render(
      <PurchaseFields
        draftAvailability={{
          mode: "select",
          variants: [
            { value: "draft-large", label: "Large", base_model: false },
            { value: "draft-small", label: "Small", base_model: false },
          ],
        }}
        onVariantChange={vi.fn<(clientKey: string | null) => void>()}
        purchase={makePurchaseForm()}
        suppliers={suppliers}
        variantClientKey={null}
        warehouses={warehouses}
      />,
    );

    expect(screen.getByRole("combobox", { name: "Variant" })).toHaveValue("");
    expect(document.querySelector('input[name="purchase[variant_client_key]"]')).toHaveValue("");
  });
});
