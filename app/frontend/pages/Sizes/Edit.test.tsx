import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Edit from "./Edit";
import { makeSize } from "./test/factories";

describe("Sizes/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    render(<Edit size={makeSize()} />);

    expect(screen.getByRole("heading", { name: "Edit Size" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Size Page/ })).toHaveAttribute(
      "href",
      "/sizes/1",
    );
    expect(screen.getByLabelText("Value")).toHaveValue("1:6");
    expect(screen.getByRole("button", { name: "Update Size" })).toBeInTheDocument();
  });
});
