import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Button from "./Button";

describe("Button", () => {
  it("renders children", () => {
    render(<Button>Save</Button>);

    expect(screen.getByRole("button", { name: "Save" })).toBeInTheDocument();
  });

  it("defaults to type='button'", () => {
    render(<Button>Save</Button>);

    expect(screen.getByRole("button")).toHaveAttribute("type", "button");
  });

  it("renders without data-variant for the default variant", () => {
    render(<Button>Save</Button>);

    expect(screen.getByRole("button")).not.toHaveAttribute("data-variant");
  });

  it("sets data-variant='primary' for the primary variant", () => {
    render(<Button variant="primary">Save</Button>);

    expect(screen.getByRole("button")).toHaveAttribute("data-variant", "primary");
  });

  it("sets data-variant='danger' for the danger variant", () => {
    render(<Button variant="danger">Delete</Button>);

    expect(screen.getByRole("button")).toHaveAttribute("data-variant", "danger");
  });

  it("forwards extra HTML button attributes", () => {
    render(<Button aria-label="Submit form">Go</Button>);

    expect(screen.getByRole("button", { name: "Submit form" })).toBeInTheDocument();
  });
});
