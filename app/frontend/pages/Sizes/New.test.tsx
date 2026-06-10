import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import New from "./New";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

const size = { id: null, value: "", created_at: null, updated_at: null };

describe("Sizes/New", () => {
  it("renders the form", () => {
    render(<New size={size} />);

    expect(screen.getByRole("heading", { name: "New Size" })).toBeInTheDocument();
    expect(screen.getByLabelText("Value")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Size" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { value: "can't be blank" } });

    render(<New size={size} />);

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});
