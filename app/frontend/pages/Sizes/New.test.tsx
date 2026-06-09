import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import New from "./New";

let pageErrors: Record<string, string> = {};

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
  Form: ({
    children,
    action,
    method,
  }: {
    children: ReactNode | ((props: { errors: Record<string, string> }) => ReactNode);
    action: string;
    method: string;
  }) => (
    <form action={action} method={method}>
      {typeof children === "function" ? children({ errors: pageErrors }) : children}
    </form>
  ),
  usePage: () => ({ props: { errors: pageErrors } }),
}));

const size = { id: null, value: "", created_at: null, updated_at: null };

describe("Sizes/New", () => {
  beforeEach(() => {
    pageErrors = {};
  });

  it("renders the form", () => {
    render(<New size={size} />);

    expect(screen.getByRole("heading", { name: "New Size" })).toBeInTheDocument();
    expect(screen.getByLabelText("Value")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Size" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    pageErrors = { value: "can't be blank" };

    render(<New size={size} />);

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});
