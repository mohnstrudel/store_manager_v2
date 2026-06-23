import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";
// oxlint-disable-next-line import/no-unassigned-import
import "@/components/SmartSelect";
import Form from "./Form";
import { makeSaleForm, makeSaleFormOptions, makeSaleItemForm } from "../test/factories";
import type { SaleItemFormRecord } from "../types";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));
vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

vi.mock("./Form/AddressFields", () => ({
  default: ({ title }: { title: string }) => <div data-testid={`address-fields-${title}`} />,
}));

vi.mock("./Form/SaleItemFields", () => ({
  default: ({ saleItem }: { saleItem: SaleItemFormRecord & { clientKey: string } }) => (
    <div data-testid="sale-item-fields">{saleItem.product_id ?? "New product"}</div>
  ),
}));

describe("Sales/components/Form", () => {
  beforeEach(() => {
    mockPageProps({});
  });

  describe("form shell", () => {
    it("configures action, method, and labels for a new sale", async () => {
      await renderForm({ isNew: true, submitLabel: "Create Sale" });

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/sales",
          cancelHref: "/sales",
          method: "post",
          submitLabel: "Create Sale",
        }),
      );
    });

    it("configures action, method, and labels for an existing sale", async () => {
      await renderForm({
        isNew: false,
        sale: makeSaleForm({ path: "/sales/12" }),
        submitLabel: "Update Sale",
      });

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/sales/12",
          cancelHref: "/sales",
          method: "patch",
          submitLabel: "Update Sale",
        }),
      );
    });
  });

  describe("field sections", () => {
    it("renders sale status, totals, address sections, and existing sale items", async () => {
      await renderForm({
        isNew: false,
        options: makeSaleFormOptions({ status_names: ["processing", "completed"] }),
        sale: makeSaleForm({
          customer_id: 1,
          discount_total: "5",
          note: "Gift wrap",
          path: "/sales/12",
          sale_items: [makeSaleItemForm({ id: 9, product_id: 2, qty: "1", price: "20" })],
          shipping_total: "3",
          total: "28",
        }),
        submitLabel: "Update Sale",
      });

      expect(screen.getByRole("radio", { name: "Processing" })).toBeChecked();
      expect(screen.getByRole("radio", { name: "Completed" })).not.toBeChecked();
      expect(screen.getByTestId("sale_customer_id")).toHaveValue("1");
      expect(screen.getByDisplayValue("Gift wrap")).toHaveAttribute("name", "sale[note]");
      expect(screen.getByDisplayValue("28")).toHaveAttribute("name", "sale[total]");
      expect(screen.getByTestId("address-fields-Shipping Address")).toBeInTheDocument();
      expect(screen.getByTestId("address-fields-Billing Address")).toBeInTheDocument();
      expect(screen.getByTestId("sale-item-fields")).toHaveTextContent("2");
    });

    it("adds a sale item row when Add Product is clicked", async () => {
      const user = userEvent.setup();
      await renderForm();

      expect(screen.queryByTestId("sale-item-fields")).not.toBeInTheDocument();

      await user.click(screen.getByRole("button", { name: "Add Product" }));

      expect(screen.getByTestId("sale-item-fields")).toHaveTextContent("New product");
    });
  });

  describe("error routing", () => {
    it("shows customer validation errors on the select field", async () => {
      mockPageProps({ errors: { customer: "Customer must exist" } });

      await renderForm();

      const customerField = screen.getByLabelText("Customer");

      expect(customerField.parentElement).toHaveClass("field_with_errors");
      expect(screen.getByText("Customer must exist")).toBeInTheDocument();
    });
  });
});

async function renderForm({
  isNew = true,
  options = makeSaleFormOptions(),
  sale = makeSaleForm(),
  submitLabel = "Create Sale",
}: {
  isNew?: boolean;
  options?: ReturnType<typeof makeSaleFormOptions>;
  sale?: ReturnType<typeof makeSaleForm>;
  submitLabel?: string;
} = {}) {
  const result = render(
    <Form isNew={isNew} options={options} sale={sale} submitLabel={submitLabel} />,
  );
  await act(async () => {});
  return result;
}
