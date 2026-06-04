import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Form from "./Form";
import type { SaleFormOptions, SaleFormRecord, SaleItemFormRecord } from "../types";

type SmartSelectMockProps = {
  defaultValue?:
    | { label: string; value: number | string }
    | { label: string; value: number | string }[]
    | null;
  inputId?: string;
  name?: string;
  options?: Array<{ label: string; value: number | string }>;
};

let pageErrors: Record<string, string> = {};

vi.mock("@/components/ResourceForm", () => ({
  default: ({
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
  }) => (
    <form action={action} data-cancel-href={cancelHref} data-method={method}>
      {typeof children === "function" ? children({ errors: pageErrors }) : children}
      <button type="submit">{submitLabel}</button>
    </form>
  ),
}));

vi.mock("@/components/SmartSelect", () => ({
  default: ({ defaultValue = null, inputId, name, options = [] }: SmartSelectMockProps) => {
    const selectedValue = Array.isArray(defaultValue)
      ? String(defaultValue[0]?.value ?? "")
      : String(defaultValue?.value ?? "");

    return (
      <select data-testid={inputId ?? name} defaultValue={selectedValue} id={inputId} name={name}>
        <option value="">Select...</option>
        {options.map((option) => (
          <option key={String(option.value)} value={String(option.value)}>
            {option.label}
          </option>
        ))}
      </select>
    );
  },
}));

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
    pageErrors = {};
  });

  it("renders the sale form sections with the correct shell configuration", () => {
    const { container } = render(
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
    );
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
    pageErrors = { customer: "Customer must exist" };

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
