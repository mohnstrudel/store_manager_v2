import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import New from "./New";

vi.mock("@/components/Link", () => ({
  default: ({ children, href }: { children: ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

vi.mock("@inertiajs/react", () => ({
  useForm: (initialData: object) => ({
    data: initialData,
    post: vi.fn(),
    processing: false,
    setData: vi.fn(),
  }),
}));

const emptyCustomer = {
  id: null,
  first_name: "",
  last_name: "",
  full_name: "",
  email: "",
  phone: "",
  woo_store_id: "",
  created_at: null,
  updated_at: null,
  path: "",
};

describe("Customers/New", () => {
  it("renders the form", () => {
    render(<New customer={emptyCustomer} />);

    expect(screen.getByRole("heading", { name: "New Customer" })).toBeInTheDocument();
    expect(screen.getByLabelText("First name")).toBeInTheDocument();
    expect(screen.getByLabelText("Last name")).toBeInTheDocument();
    expect(screen.getByLabelText("Email")).toBeInTheDocument();
    expect(screen.getByLabelText("Phone")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Customer" })).toBeInTheDocument();
  });

  it("renders validation errors", () => {
    render(
      <New
        customer={emptyCustomer}
        errors={{ base: ["Customer must have contact details or store information"] }}
      />,
    );

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
  });
});
