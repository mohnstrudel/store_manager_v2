import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import New from "./New";

vi.mock("@/components/Link", () => ({
  default: ({ children, href }: { children: ReactNode; href: string }) => <a href={href}>{children}</a>,
}));

vi.mock("@inertiajs/react", () => ({
  useForm: (initialData: { size: { value: string } }) => ({
    data: initialData,
    post: vi.fn(),
    processing: false,
    setData: vi.fn(),
  }),
}));

describe("Sizes/New", () => {
  it("renders the form", () => {
    render(<New errors={{}} size={{ id: null, value: "", created_at: null, updated_at: null }} />);

    expect(screen.getByRole("heading", { name: "New Size" })).toBeInTheDocument();
    expect(screen.getByLabelText("Value")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Size" })).toBeInTheDocument();
  });

  it("renders validation errors", () => {
    render(
      <New
        errors={{ value: ["Value can't be blank"] }}
        size={{ id: null, value: "", created_at: null, updated_at: null }}
      />,
    );

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getByText("can't be blank")).toBeInTheDocument();
  });
});
