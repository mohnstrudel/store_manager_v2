import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import New from "./New";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

const emptyCustomer = {
  id: null,
  woo_store_id: "",
  full_name: "",
  first_name: "",
  last_name: "",
  email: "",
  phone: "",
  created_at: null,
  updated_at: null,
  path: "/customers/new",
};

describe("Customers/New", () => {
  it("renders the form", () => {
    render(<New customer={emptyCustomer} />);

    expect(screen.getByRole("heading", { name: "New Customer" })).toBeInTheDocument();
    expect(screen.getByLabelText("First name")).toBeInTheDocument();
    expect(screen.getByLabelText("Email")).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { first_name: "can't be blank" } });

    render(<New customer={emptyCustomer} />);

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});
