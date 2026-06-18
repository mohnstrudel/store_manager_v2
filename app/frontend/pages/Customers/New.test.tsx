import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import New from "./New";
import { makeCustomer } from "./test/factories";
import type { CustomerRecord } from "./types";

describe("Customers/New", () => {
  it("renders the form", () => {
    renderNew();

    expect(screen.getByRole("heading", { name: "New Customer" })).toBeInTheDocument();
    expect(screen.getByLabelText("First name")).toBeInTheDocument();
    expect(screen.getByLabelText("Email")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Customer" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { first_name: "can't be blank" } });

    renderNew();

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});

function renderNew({
  customer = makeCustomer({
    id: null,
    first_name: "",
    last_name: "",
    full_name: "",
    email: "",
    phone: "",
    woo_store_id: "",
    created_at: null,
    updated_at: null,
    path: "/customers/new",
  }),
}: {
  customer?: CustomerRecord;
} = {}) {
  return render(<New customer={customer} />);
}
