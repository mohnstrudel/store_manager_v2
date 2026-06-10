import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import New from "./New";
import type { SaleAddressFormRecord, SaleFormOptions, SaleFormRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

vi.mock("./components/Form", () => ({
  default: () => <div data-testid="sale-form" />,
}));

const blankAddress: SaleAddressFormRecord = {
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
};

const options: SaleFormOptions = {
  customers: [],
  products: [],
  status_names: ["processing"],
};

const sale: SaleFormRecord = {
  id: null,
  path: "",
  status: "",
  customer_id: null,
  note: "",
  total: "",
  discount_total: "",
  shipping_total: "",
  shipping_address: blankAddress,
  billing_address: blankAddress,
  sale_items: [],
};

describe("Sales/New", () => {
  it("renders the form without an error notice when there are no errors", () => {
    render(<New options={options} sale={sale} />);

    expect(screen.queryByText("Fix errors and try again")).not.toBeInTheDocument();
    expect(screen.getByTestId("sale-form")).toBeInTheDocument();
  });

  it("shows the error notice with field errors when validation fails", () => {
    mockPageProps({ errors: { customer: "can't be blank", status: "is invalid" } });

    render(<New options={options} sale={sale} />);

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getByText("can't be blank")).toBeInTheDocument();
    expect(screen.getByText("is invalid")).toBeInTheDocument();
  });
});
