import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Edit from "./Edit";
import { makeColor } from "./test/factories";

describe("Colors/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    render(<Edit color={makeColor()} />);

    expect(screen.getByRole("heading", { name: "Edit Color" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Color Page/ })).toHaveAttribute(
      "href",
      "/colors/1",
    );
    expect(screen.getByLabelText("Value")).toHaveValue("Azure");
    expect(screen.getByRole("button", { name: "Update Color" })).toBeInTheDocument();
  });
});
