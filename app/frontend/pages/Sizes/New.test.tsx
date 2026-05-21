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

    expect(screen.getByText("can't be blank")).toBeInTheDocument();
  });
});
