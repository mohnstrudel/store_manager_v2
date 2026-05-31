import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Form from "./Form";
import type { SaleFormOptions, SaleFormRecord } from "../types";

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
  }: {
    action: string;
    cancelHref: string;
    children: ReactNode | ((props: { errors: Record<string, string> }) => ReactNode);
    method: string;
    submitLabel: string;
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

vi.mock("./AddressFields", () => ({
  default: ({ title }: { title: string }) => <div data-testid={`address-fields-${title}`} />,
}));

vi.mock("./SaleItemFields", () => ({
  default: () => <div data-testid="sale-item-fields" />,
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

  it("shows customer validation errors on the select field", () => {
    pageErrors = { customer: "Customer must exist" };

    render(<Form isNew options={options} sale={makeSale()} submitLabel="Create Sale" />);

    const customerField = screen.getByLabelText("Customer");

    expect(customerField.parentElement).toHaveClass("field_with_errors");
    expect(screen.getByText("Customer must exist")).toBeInTheDocument();
  });
});
