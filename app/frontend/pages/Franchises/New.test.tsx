import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";

import New from "./New";
import { makeFranchiseForm } from "./test/factories";

describe("Franchises/New", () => {
  it("renders the form", () => {
    render(<New franchise={makeFranchiseForm({ title: "" })} />);

    expect(screen.getByRole("heading", { name: "New Franchise" })).toBeInTheDocument();
    expect(screen.getByLabelText("Title")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Franchise" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { title: "can't be blank" } });

    render(<New franchise={makeFranchiseForm({ title: "" })} />);

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});
