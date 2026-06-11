import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import Form from "./Form";
import type { SaleFormOptions, SaleFormRecord, SaleItemFormRecord } from "../types";
// oxlint-disable-next-line import/no-unassigned-import
import "@/components/SmartSelect";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));
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

const options: SaleFormOptions = {
  customers: [{ value: 1, label: "Ada Lovelace" }],
  products: [{ value: 2, label: "Moon Statue" }],
  status_names: ["processing"],
};

function makeSale(overrides: Partial<SaleFormRecord> = {}): SaleFormRecord {
  return {
    id: null,
    path: "",
    status: "processing",
    customer_id: null,
    note: "",
    total: "",
    discount_total: "",
    shipping_total: "",
    shipping_address: {
      first_name: "",
      last_name: "",
      email: "",
      phone: "",
      company: "",
      address_1: "",
      address_2: "",
      city: "",
      state: "",
      postcode: "",
      country: "",
    },
    billing_address: {
      first_name: "",
      last_name: "",
      email: "",
      phone: "",
      company: "",
      address_1: "",
      address_2: "",
      city: "",
      state: "",
      postcode: "",
      country: "",
    },
    sale_items: [],
    ...overrides,
  };
}

describe("Sales/Components/Form", () => {
  beforeEach(() => {
    mockPageProps({});
  });

  it("renders the sale form sections with the correct shell configuration", async () => {
    let container!: HTMLElement;

    await act(async () => {
      ({ container } = render(
        <Form
          isNew={false}
          options={{ ...options, status_names: ["processing", "completed"] }}
          sale={makeSale({
            customer_id: 1,
            discount_total: "5",
            note: "Gift wrap",
            path: "/sales/12",
            sale_items: [{ id: 9, product_id: 2, qty: "1", price: "20", _destroy: false }],
            shipping_total: "3",
            total: "28",
          })}
          submitLabel="Update Sale"
        />,
      ));
    });
    const form = container.querySelector("form");

    expect(form).toHaveAttribute("action", "/sales/12");
    expect(form).toHaveAttribute("data-method", "patch");
    expect(screen.getByRole("radio", { name: "Processing" })).toBeChecked();
    expect(screen.getByRole("radio", { name: "Completed" })).not.toBeChecked();
    expect(screen.getByTestId("sale_customer_id")).toHaveValue("1");
    expect(screen.getByDisplayValue("Gift wrap")).toHaveAttribute("name", "sale[note]");
    expect(screen.getByDisplayValue("28")).toHaveAttribute("name", "sale[total]");
    expect(screen.getByTestId("address-fields-Shipping Address")).toBeInTheDocument();
    expect(screen.getByTestId("address-fields-Billing Address")).toBeInTheDocument();
    expect(screen.getByTestId("sale-item-fields")).toHaveTextContent("2");
  });

  it("shows customer validation errors on the select field", () => {
    mockPageProps({ errors: { customer: "Customer must exist" } });

    render(<Form isNew options={options} sale={makeSale()} submitLabel="Create Sale" />);

    const customerField = screen.getByLabelText("Customer");

    expect(customerField.parentElement).toHaveClass("field_with_errors");
    expect(screen.getByText("Customer must exist")).toBeInTheDocument();
  });

  it("adds a sale item row when Add Product is clicked", async () => {
    const user = userEvent.setup();

    render(<Form isNew options={options} sale={makeSale()} submitLabel="Create Sale" />);

    expect(screen.queryByTestId("sale-item-fields")).not.toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "Add Product" }));

    expect(screen.getByTestId("sale-item-fields")).toHaveTextContent("New product");
  });
});
