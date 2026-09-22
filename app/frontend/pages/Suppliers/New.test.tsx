import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";

import New from "./New";
import { makeSupplier } from "./test/factories";

describe("Suppliers/New", () => {
  it("renders the form", () => {
    render(
      <New
        supplier={makeSupplier({
          id: null,
          title: "",
          created_at: null,
          updated_at: null,
        })}
      />,
    );

    expect(screen.getByRole("heading", { name: "New Supplier" })).toBeInTheDocument();
    expect(screen.getByLabelText("Title")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Supplier" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { title: "can't be blank" } });

    render(
      <New
        supplier={makeSupplier({
          id: null,
          title: "",
          created_at: null,
          updated_at: null,
        })}
      />,
    );

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});
