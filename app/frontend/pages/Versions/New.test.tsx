import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";

import New from "./New";
import { makeVersion } from "./test/factories";

describe("Versions/New", () => {
  it("renders the form", () => {
    render(
      <New
        version={makeVersion({
          id: null,
          value: "",
          created_at: null,
          updated_at: null,
        })}
      />,
    );

    expect(screen.getByRole("heading", { name: "New Version" })).toBeInTheDocument();
    expect(screen.getByLabelText("Value")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Version" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { value: "can't be blank" } });

    render(
      <New
        version={makeVersion({
          id: null,
          value: "",
          created_at: null,
          updated_at: null,
        })}
      />,
    );

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});
