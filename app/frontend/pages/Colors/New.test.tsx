import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";

import New from "./New";
import { makeColorForm } from "./test/factories";

describe("Colors/New", () => {
  it("renders the form", () => {
    render(<New color={makeColorForm({ value: "" })} />);

    expect(screen.getByRole("heading", { name: "New Color" })).toBeInTheDocument();
    expect(screen.getByLabelText("Value")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Color" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { value: "can't be blank" } });

    render(<New color={makeColorForm({ value: "" })} />);

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});
