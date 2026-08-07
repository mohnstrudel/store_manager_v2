import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Field, { isBlank } from "./Field";

describe("Field", () => {
  it.each([
    ["null", null],
    ["undefined", undefined],
    ["an empty string", ""],
  ])("hides the row when the value is %s", (_description, value) => {
    render(
      <dl>
        <Field label="Shipping" value={value} />
      </dl>,
    );

    expect(screen.queryByText("Shipping")).not.toBeInTheDocument();
  });

  it("renders the row when the value is 0", () => {
    render(
      <dl>
        <Field label="Qty" value={0} />
      </dl>,
    );

    expect(screen.getByText("Qty")).toBeInTheDocument();
    expect(screen.getByText("0")).toBeInTheDocument();
  });

  it("renders the label and value when present", () => {
    render(
      <dl>
        <Field label="Order reference" value="177809" />
      </dl>,
    );

    expect(screen.getByText("Order reference")).toBeInTheDocument();
    expect(screen.getByText("177809")).toBeInTheDocument();
  });

  it("applies the className to the value", () => {
    render(
      <dl>
        <Field className="font-mono" label="Total price" value="556" />
      </dl>,
    );

    expect(screen.getByText("556")).toHaveClass("font-mono");
  });

  it("renders children instead of the raw value when supplied", () => {
    render(
      <dl>
        <Field label="Debt" value="323">
          -{"323"}
        </Field>
      </dl>,
    );

    expect(screen.getByText("Debt")).toBeInTheDocument();
    expect(screen.getByText("-323")).toBeInTheDocument();
  });

  it("hides the row when the value is blank even if children are supplied", () => {
    render(
      <dl>
        <Field label="Debt" value={null}>
          -{null}
        </Field>
      </dl>,
    );

    expect(screen.queryByText("Debt")).not.toBeInTheDocument();
  });
});

describe("isBlank", () => {
  it.each([
    [null, true],
    [undefined, true],
    ["", true],
    [0, false],
    ["0", false],
    ["value", false],
  ])("returns %s for isBlank(%o)", (value, expected) => {
    expect(isBlank(value)).toBe(expected);
  });
});
