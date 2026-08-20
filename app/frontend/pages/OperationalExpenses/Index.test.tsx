import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Index from "./Index";

describe("OperationalExpenses/Index", () => {
  it("uses the canonical OpEx terminology", () => {
    render(<Index operationalExpenses={[]} />);

    expect(screen.getByRole("heading", { name: "OpEx" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Actual OpEx" })).toBeInTheDocument();
  });
});
