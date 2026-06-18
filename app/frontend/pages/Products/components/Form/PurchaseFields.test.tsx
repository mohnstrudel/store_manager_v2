import { act, render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import PurchaseFields from "./PurchaseFields";
import { makePurchaseForm } from "../../test/factories";
// oxlint-disable-next-line import/no-unassigned-import
import "@/components/SmartSelect";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

const suppliers = [{ value: 1, label: "Moon Supply" }];
const warehouses = [{ value: 10, label: "Main Warehouse" }];

describe("Products/components/Form/PurchaseFields", () => {
  it("renders named hidden inputs for supplier_id and warehouse_id selects", async () => {
    await act(async () => {
            render(<PurchaseFields purchase={makePurchaseForm({ supplier_id: 1, warehouse_id: 10 })} suppliers={suppliers} warehouses={warehouses} {...{}}/>);
    });

    expect(screen.getAllByRole("combobox")).toHaveLength(2);
    expect(document.querySelector('input[name="purchase[supplier_id]"]')).toHaveValue("1");
    expect(document.querySelector('input[name="purchase[warehouse_id]"]')).toHaveValue("10");
  });

  it("renders ordinary purchase fields as uncontrolled named inputs", () => {
        render(<PurchaseFields purchase={makePurchaseForm({
        order_reference: "PO-1",
        item_price: "12.50",
        amount: "2",
        payment_value: "25",
    })} suppliers={suppliers} warehouses={warehouses} {...{}}/>);

    expect(document.querySelector('input[name="purchase[order_reference]"]')).toHaveValue("PO-1");
    expect(document.querySelector('input[name="purchase[item_price]"]')).toHaveValue("12.50");
    expect(document.querySelector('input[name="purchase[amount]"]')).toHaveValue("2");
    expect(document.querySelector('input[name="purchase[payment_value]"]')).toHaveValue(25);
  });

  it("does not render the warehouse select when there are no warehouses", () => {
    render(<PurchaseFields purchase={makePurchaseForm()} suppliers={suppliers} warehouses={[]} />);

    expect(screen.getAllByRole("combobox")).toHaveLength(1);
  });
});


