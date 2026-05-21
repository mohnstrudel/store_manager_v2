import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import New from "./New";

vi.mock("@/components/Link", () => ({
  default: ({ children, href }: { children: ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

let pageErrors: Record<string, string> = {};

vi.mock("@inertiajs/react", () => ({
  Form: ({ children, action, method }: { children: ReactNode; action: string; method: string }) => (
    <form action={action} method={method}>{children}</form>
  ),
  usePage: () => ({ props: { errors: pageErrors } }),
}));

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
  beforeEach(() => {
    pageErrors = {};
  });

  it("renders the form", () => {
    render(<New customer={emptyCustomer} />);

    expect(screen.getByRole("heading", { name: "New Customer" })).toBeInTheDocument();
    expect(screen.getByLabelText("First name")).toBeInTheDocument();
    expect(screen.getByLabelText("Email")).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    pageErrors = { first_name: "can't be blank" };

    render(<New customer={emptyCustomer} />);

    expect(screen.getByText("can't be blank")).toBeInTheDocument();
  });
});
